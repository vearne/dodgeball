import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'ai_controller.dart';
import 'ball_component.dart';
import 'field_background.dart';
import 'field_config.dart';
import 'game_mode.dart';
import 'player_component.dart';
import 'team.dart';

class DodgeballGame extends FlameGame
    with
        HasCollisionDetection,
        TapCallbacks,
        DoubleTapCallbacks,
        HasKeyboardHandlerComponents,
        HasThrowRequest,
        HasPlayerThrowRequest {
  DodgeballGame({this.randomSeed, this.gameMode = GameMode.singlePlayer}) {
    if (randomSeed != null) {
      _random = Random(randomSeed);
    }
  }

  final int? randomSeed;
  final GameMode gameMode;
  late Random _random = Random();

  final List<PlayerComponent> redPlayers = [];
  final List<PlayerComponent> bluePlayers = [];

  // 管控每个玩家是否可以再次投掷（必须等到上一次球命中墙或玩家后）
  final Set<int> playersLocked = {};

  // 游戏状态
  GameState gameState = GameState.playing;

  // 人类玩家冷却时间监听（秒）
  final ValueNotifier<double> humanCooldownRemainingNotifier =
      ValueNotifier<double>(0);
  // 人类玩家得分
  final ValueNotifier<int> humanScoreNotifier = ValueNotifier<int>(0);

  // 胜利显示组件
  TextComponent? victoryText;

  // 游戏统计
  TextComponent? redTeamCountText;
  TextComponent? blueTeamCountText;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // 添加场地背景
    add(FieldBackground(gameSize: size));

    // 添加外围边界墙壁
    _addBoundaryWalls();

    // 生成队伍
    await _spawnTeams();

    // 添加队伍统计显示
    _setupTeamCountDisplay();
  }

  Future<void> _spawnTeams() async {
    // 两侧各 6 人
    const int teamSize = 6;

    final redArea = FieldConfig.getRedTeamArea(size);
    final blueArea = FieldConfig.getBluTeamArea(size);

    // 计算玩家在各自区域内的位置
    final redPositions = _generatePlayerPositions(redArea, teamSize);
    final bluePositions = _generatePlayerPositions(blueArea, teamSize);

    for (int i = 0; i < teamSize; i++) {
      final red = PlayerComponent(
        team: Team.red,
        playerId: i,
        position: redPositions[i],
        controllerType: (gameMode == GameMode.singlePlayer && i != 0)
            ? PlayerControllerType.ai
            : PlayerControllerType.human,
      );
      redPlayers.add(red);
      add(red);

      final blue = PlayerComponent(
        team: Team.blue,
        playerId: 100 + i,
        position: bluePositions[i],
        controllerType: gameMode == GameMode.singlePlayer
            ? PlayerControllerType.ai
            : PlayerControllerType.human,
      );
      bluePlayers.add(blue);
      add(blue);
    }
  }

  /// 在指定区域内生成玩家位置
  List<Vector2> _generatePlayerPositions(Rect area, int count) {
    final positions = <Vector2>[];
    final margin = 30.0; // 距离边界的边距

    // 简单的网格布局
    final cols = (count <= 4) ? 2 : 3;
    final rows = (count + cols - 1) ~/ cols;

    final cellWidth = (area.width - margin * 2) / cols;
    final cellHeight = (area.height - margin * 2) / rows;

    int playerIndex = 0;
    for (int row = 0; row < rows && playerIndex < count; row++) {
      for (int col = 0; col < cols && playerIndex < count; col++) {
        final x = area.left + margin + cellWidth * (col + 0.5);
        final y = area.top + margin + cellHeight * (row + 0.5);
        positions.add(Vector2(x, y));
        playerIndex++;
      }
    }

    return positions;
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (gameState == GameState.playing) {
      _handleWallBounces();
      _handleBallPlayerCollisions();
      _checkVictoryConditions();
    }

    // 更新人类玩家冷却时间通知
    _updateHumanCooldownNotifier();
  }

  void _updateHumanCooldownNotifier() {
    // 假设红队第一个玩家为人类（单人模式）；多人模式也可以扩展成跟踪所有人类玩家
    PlayerComponent? human;
    if (redPlayers.isNotEmpty) {
      human = redPlayers.firstWhere(
        (p) => p.controllerType == PlayerControllerType.human,
        orElse: () => redPlayers.first,
      );
    }
    if (human == null || human.isEliminated) {
      if (humanCooldownRemainingNotifier.value != 0) {
        humanCooldownRemainingNotifier.value = 0;
      }
      return;
    }
    final remaining = human.throwCooldownRemaining;
    if (humanCooldownRemainingNotifier.value != remaining) {
      humanCooldownRemainingNotifier.value = remaining;
    }
  }

  void _handleWallBounces() {
    for (final ball in children.whereType<BallComponent>()) {
      final r = ball.radius;
      final px = ball.position.x;
      final py = ball.position.y;
      final wallThickness = FieldConfig.wallThickness;

      // 顶部边界
      if (py - r <= wallThickness && ball.velocity.y < 0) {
        ball.reflectOnHorizontalWall();
      }

      // 底部边界
      if (py + r >= size.y - wallThickness && ball.velocity.y > 0) {
        ball.reflectOnHorizontalWall();
      }

      // 左侧边界
      if (px - r <= wallThickness && ball.velocity.x < 0) {
        ball.reflectOnVerticalWall();
      }

      // 右侧边界
      if (px + r >= size.x - wallThickness && ball.velocity.x > 0) {
        ball.reflectOnVerticalWall();
      }
    }
  }

  void _handleBallPlayerCollisions() {
    final balls = children.whereType<BallComponent>().toList();
    final players = children.whereType<PlayerComponent>().toList();

    for (final ball in balls) {
      for (final player in players) {
        if (player.team == ball.team) continue; // 不打同队
        if (player.isEliminated) continue;
        final distance = ball.absoluteCenter.distanceTo(player.absoluteCenter);
        if (distance <= ball.radius + player.radius) {
          player.eliminate();
          ball.hitPlayerAndContinue();
          _awardScoreForHit(ball);
          // 直接继续运行，球可能还有剩余反弹次数
        }
      }
    }
  }

  void _awardScoreForHit(BallComponent ball) {
    // 若发球者是人类玩家（默认红队第一个）则加分
    if (redPlayers.isNotEmpty) {
      final human = redPlayers.firstWhere(
        (p) => p.controllerType == PlayerControllerType.human,
        orElse: () => redPlayers.first,
      );
      if (human.playerId == ball.ownerPlayerId) {
        humanScoreNotifier.value = humanScoreNotifier.value + 1;
      }
    }
  }

  // 简化：点击屏幕由红队随机一人向点击点扔球，双击由蓝队投掷
  @override
  void onTapDown(TapDownEvent event) {
    if (gameState != GameState.playing) {
      // 游戏结束时，点击重新开始
      restartGame();
      return;
    }
    _throwFromTeamTowards(Team.red, event.localPosition);
  }

  @override
  void onDoubleTapDown(DoubleTapDownEvent event) {
    if (gameState != GameState.playing) {
      // 游戏结束时，双击也重新开始
      restartGame();
      return;
    }
    // 随机位置：对称中点附近
    final target = Vector2(size.x * 0.5, _random.nextDouble() * size.y);
    _throwFromTeamTowards(Team.blue, target);
  }

  void _throwFromTeamTowards(Team team, Vector2 target) {
    final candidates = (team == Team.red ? redPlayers : bluePlayers)
        .where((p) => !p.isEliminated && !playersLocked.contains(p.playerId))
        .toList();
    if (candidates.isEmpty) return;
    final thrower = candidates[_random.nextInt(candidates.length)];

    final dir = (target - thrower.absoluteCenter).normalized();
    final speed = 360.0; // 可调速度
    final velocity = dir * speed;

    final randomBounces = 1 + _random.nextInt(5); // 1..5
    final ball = BallComponent(
      team: team,
      ownerPlayerId: thrower.playerId,
      position: thrower.absoluteCenter.clone(),
      initialVelocity: velocity,
      bounceCount: randomBounces,
    );
    add(ball);

    // 上锁：直到该球与墙或玩家发生一次有效碰撞才解锁
    playersLocked.add(thrower.playerId);
    // 轮询：当球发生任意有效碰撞（ball.collidedOnce）时解锁
    late final TimerComponent timer;
    timer = TimerComponent(
      period: 0.05,
      repeat: true,
      onTick: () {
        if (!ball.isMounted || ball.collidedOnce) {
          playersLocked.remove(thrower.playerId);
          timer.removeFromParent();
        }
      },
    );
    add(timer);
  }

  @override
  void requestThrowFromAI(PlayerComponent thrower, Vector2 target) {
    // 检查游戏状态和AI玩家是否可以投球
    if (gameState != GameState.playing ||
        thrower.isEliminated ||
        playersLocked.contains(thrower.playerId)) {
      return;
    }

    final dir = (target - thrower.absoluteCenter).normalized();
    final speed = 300.0 + _random.nextDouble() * 120.0; // AI投球速度有随机性
    final velocity = dir * speed;

    final randomBounces = 1 + _random.nextInt(4); // 1..4 (略少于玩家)
    final ball = BallComponent(
      team: thrower.team,
      ownerPlayerId: thrower.playerId,
      position: thrower.absoluteCenter.clone(),
      initialVelocity: velocity,
      bounceCount: randomBounces,
    );
    add(ball);

    // 重置投球冷却时间
    thrower.resetThrowCooldown();

    // 上锁：直到该球与墙或玩家发生一次有效碰撞才解锁
    playersLocked.add(thrower.playerId);

    late final TimerComponent timer;
    timer = TimerComponent(
      period: 0.05,
      repeat: true,
      onTick: () {
        if (!ball.isMounted || ball.collidedOnce) {
          playersLocked.remove(thrower.playerId);
          timer.removeFromParent();
        }
      },
    );
    add(timer);
  }

  @override
  void requestThrowFromPlayer(PlayerComponent thrower, Vector2 target) {
    // 检查游戏状态和玩家是否可以投球
    if (gameState != GameState.playing ||
        thrower.isEliminated ||
        playersLocked.contains(thrower.playerId)) {
      return;
    }

    final dir = (target - thrower.absoluteCenter).normalized();
    final speed = 400.0; // 玩家投球速度
    final velocity = dir * speed;

    final randomBounces = 2 + _random.nextInt(4); // 2..5
    final ball = BallComponent(
      team: thrower.team,
      ownerPlayerId: thrower.playerId,
      position: thrower.absoluteCenter.clone(),
      initialVelocity: velocity,
      bounceCount: randomBounces,
    );
    add(ball);

    // 上锁：直到该球与墙或玩家发生一次有效碰撞才解锁
    playersLocked.add(thrower.playerId);

    late final TimerComponent timer;
    timer = TimerComponent(
      period: 0.05,
      repeat: true,
      onTick: () {
        if (!ball.isMounted || ball.collidedOnce) {
          playersLocked.remove(thrower.playerId);
          timer.removeFromParent();
        }
      },
    );
    add(timer);
  }

  /// 检查胜利条件
  void _checkVictoryConditions() {
    if (gameState != GameState.playing) return;

    // 更新统计显示
    _updateTeamCountDisplay();

    // 检查红队是否全部被淘汰
    final redAlive = redPlayers.where((p) => !p.isEliminated).length;
    final blueAlive = bluePlayers.where((p) => !p.isEliminated).length;

    if (redAlive == 0) {
      _handleVictory(GameState.blueWins);
    } else if (blueAlive == 0) {
      _handleVictory(GameState.redWins);
    }
  }

  /// 处理胜利
  void _handleVictory(GameState winner) {
    gameState = winner;

    // 停止所有球的移动
    for (final ball in children.whereType<BallComponent>()) {
      ball.removeFromParent();
    }

    // 显示胜利信息
    _showVictoryMessage(winner);
  }

  /// 显示胜利消息
  void _showVictoryMessage(GameState winner) {
    final winnerName = winner == GameState.redWins ? '红队' : '蓝队';
    final winnerColor = winner == GameState.redWins
        ? const Color(0xFFE53935)
        : const Color(0xFF1E88E5);

    // 背景遮罩
    final overlay = RectangleComponent(
      size: size,
      paint: Paint()..color = const Color(0x80000000), // 半透明黑色
    );
    add(overlay);

    // 胜利文字
    victoryText = TextComponent(
      text: '$winnerName 获胜！',
      textRenderer: TextPaint(
        style: TextStyle(
          fontSize: 48,
          fontWeight: FontWeight.bold,
          color: winnerColor,
        ),
      ),
      anchor: Anchor.center,
      position: Vector2(size.x / 2, size.y / 2 - 40),
    );
    add(victoryText!);

    // 重新开始提示
    final restartText = TextComponent(
      text: '点击屏幕重新开始',
      textRenderer: TextPaint(
        style: const TextStyle(fontSize: 24, color: Color(0xFFFFFFFF)),
      ),
      anchor: Anchor.center,
      position: Vector2(size.x / 2, size.y / 2 + 20),
    );
    add(restartText);

    // 添加闪烁效果
    final blinkTimer = TimerComponent(
      period: 0.5,
      repeat: true,
      onTick: () {
        restartText.scale = restartText.scale == Vector2.all(1.0)
            ? Vector2.all(1.2)
            : Vector2.all(1.0);
      },
    );
    add(blinkTimer);
  }

  /// 重新开始游戏
  void restartGame() {
    // 清除所有组件
    removeAll(children.toList());

    // 重置状态
    gameState = GameState.playing;
    redPlayers.clear();
    bluePlayers.clear();
    playersLocked.clear();
    victoryText = null;
    redTeamCountText = null;
    blueTeamCountText = null;
    humanScoreNotifier.value = 0;

    // 重新设置场地
    add(FieldBackground(gameSize: size));
    _addBoundaryWalls();

    // 重新生成队伍
    _spawnTeams();

    // 重新设置统计显示
    _setupTeamCountDisplay();
  }

  /// 设置队伍统计显示
  void _setupTeamCountDisplay() {
    // 红队统计
    redTeamCountText = TextComponent(
      text: '红队: 6',
      textRenderer: TextPaint(
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Color(0xFFE53935),
        ),
      ),
      position: Vector2(20, 20),
    );
    add(redTeamCountText!);

    // 蓝队统计
    blueTeamCountText = TextComponent(
      text: '蓝队: 6',
      textRenderer: TextPaint(
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Color(0xFF1E88E5),
        ),
      ),
      position: Vector2(size.x - 120, 20),
    );
    add(blueTeamCountText!);
  }

  /// 更新队伍统计显示
  void _updateTeamCountDisplay() {
    final redAlive = redPlayers.where((p) => !p.isEliminated).length;
    final blueAlive = bluePlayers.where((p) => !p.isEliminated).length;

    redTeamCountText?.text = '红队: $redAlive';
    blueTeamCountText?.text = '蓝队: $blueAlive';
  }

  /// 添加外围边界墙壁
  void _addBoundaryWalls() {
    final wallThickness = FieldConfig.wallThickness;

    // 顶部墙壁
    final topWall = RectangleComponent(
      position: Vector2(0, 0),
      size: Vector2(size.x, wallThickness),
      paint: Paint()..color = FieldConfig.wallColor,
    );
    add(topWall);

    // 底部墙壁
    final bottomWall = RectangleComponent(
      position: Vector2(0, size.y - wallThickness),
      size: Vector2(size.x, wallThickness),
      paint: Paint()..color = FieldConfig.wallColor,
    );
    add(bottomWall);

    // 左侧墙壁
    final leftWall = RectangleComponent(
      position: Vector2(0, 0),
      size: Vector2(wallThickness, size.y),
      paint: Paint()..color = FieldConfig.wallColor,
    );
    add(leftWall);

    // 右侧墙壁
    final rightWall = RectangleComponent(
      position: Vector2(size.x - wallThickness, 0),
      size: Vector2(wallThickness, size.y),
      paint: Paint()..color = FieldConfig.wallColor,
    );
    add(rightWall);
  }

  @override
  KeyEventResult onKeyEvent(
    KeyEvent event,
    Set<LogicalKeyboardKey> keysPressed,
  ) {
    // 先调用父类方法
    super.onKeyEvent(event, keysPressed);

    // 将键盘事件传递给所有人类玩家的输入控制器
    for (final player in [...redPlayers, ...bluePlayers]) {
      if (player.controllerType == PlayerControllerType.human &&
          player.inputController != null) {
        player.inputController!.handleKeyEvent(keysPressed);
      }
    }
    return KeyEventResult.handled;
  }
}
