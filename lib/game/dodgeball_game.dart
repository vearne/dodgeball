import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'ai_controller.dart';
import 'audio_manager.dart';
import 'ball_component.dart';
import 'field_background.dart';
import 'field_config.dart';
import 'game_mode.dart';
import 'mobile_controller.dart';
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
  DodgeballGame({
    this.randomSeed,
    this.gameMode = GameMode.singlePlayer,
    this.gameplayMode = GameplayMode.elimination,
    this.maxHealth,
    this.timeLimit,
  }) {
    if (randomSeed != null) {
      _random = Random(randomSeed);
    }
  }

  final int? randomSeed;
  final GameMode gameMode;
  final GameplayMode gameplayMode;
  final int? maxHealth;
  final TimeLimitOption? timeLimit;
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

  // 限时赛相关
  TimerComponent? _gameTimer;
  final ValueNotifier<int> _remainingTimeNotifier = ValueNotifier<int>(0);
  ValueNotifier<int> get remainingTimeNotifier => _remainingTimeNotifier;

  // 胜利显示组件
  TextComponent? victoryText;

  // 游戏统计
  TextComponent? redTeamCountText;
  TextComponent? blueTeamCountText;

  // 音频管理器
  final AudioManager _audioManager = AudioManager.instance;

  // 移动设备控制器
  MobileController? _mobileController;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // 初始化音频管理器
    await _audioManager.initialize();

    // 添加场地背景
    add(FieldBackground(gameSize: size));

    // 添加外围边界墙壁
    _addBoundaryWalls();

    // 生成队伍
    await _spawnTeams();

    // 添加队伍统计显示
    _setupTeamCountDisplay();

    // 播放背景音乐
    await _audioManager.playBackgroundMusic();

    // 如果是移动设备，添加移动控制器
    if (MobileController.isMobileDevice) {
      _addMobileController();
    }
  }

  /// 添加移动设备控制器
  void _addMobileController() {
    _mobileController = MobileController(
      gameSize: size,
      onMove: _handleMobileMove,
      onThrow: _handleMobileThrow,
    );
    add(_mobileController!);
  }

  /// 处理移动设备移动输入
  void _handleMobileMove(Vector2 direction) {
    // 找到人类玩家并发送移动指令
    for (final player in redPlayers) {
      if (player.controllerType == PlayerControllerType.human &&
          !player.isEliminated) {
        // 使用新的移动设备输入方法
        player.inputController?.handleMobileInput(direction);
        break;
      }
    }
  }

  /// 处理移动设备投掷输入
  void _handleMobileThrow() {
    // 找到人类玩家并发送投掷指令
    for (final player in redPlayers) {
      if (player.controllerType == PlayerControllerType.human &&
          !player.isEliminated) {
        if (player.canThrow) {
          // 使用新的移动设备投掷方法
          player.inputController?.handleMobileThrow();
        }
        break;
      }
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (gameState == GameState.playing) {
      _handleWallBounces();
      _checkVictoryConditions();
    }

    // 更新人类玩家冷却时间通知
    _updateHumanCooldownNotifier();

    // 更新移动设备控制器状态
    _updateMobileController();
  }

  /// 更新移动设备控制器状态
  void _updateMobileController() {
    if (_mobileController != null) {
      // 检查人类玩家是否可以投掷
      bool canThrow = false;
      for (final player in redPlayers) {
        if (player.controllerType == PlayerControllerType.human &&
            !player.isEliminated) {
          canThrow = player.canThrow;
          break;
        }
      }
      _mobileController!.setThrowButtonEnabled(canThrow);
    }
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
        // 修正球的位置，防止穿透
        ball.position.y = wallThickness + r;
        ball.reflectOnHorizontalWall();
      }

      // 底部边界
      if (py + r >= size.y - wallThickness && ball.velocity.y > 0) {
        ball.position.y = size.y - wallThickness - r;
        ball.reflectOnHorizontalWall();
      }

      // 左侧边界
      if (px - r <= wallThickness && ball.velocity.x < 0) {
        ball.position.x = wallThickness + r;
        ball.reflectOnVerticalWall();
      }

      // 右侧边界
      if (px + r >= size.x - wallThickness && ball.velocity.x > 0) {
        ball.position.x = size.x - wallThickness - r;
        ball.reflectOnVerticalWall();
      }
    }
  }

  // 基于碰撞系统，不再手动检测球-玩家距离

  void _awardScoreForHit(BallComponent ball, PlayerComponent hitPlayer) {
    // 找到投掷球的玩家
    final thrower = _findPlayerById(ball.ownerPlayerId);
    if (thrower == null) return;

    if (gameplayMode == GameplayMode.elimination) {
      // 淘汰赛：被击中的玩家已经在球组件中处理了伤害
      // 若发球者是人类玩家则加分（用于显示）
      if (thrower.controllerType == PlayerControllerType.human) {
        humanScoreNotifier.value = humanScoreNotifier.value + 1;
      }
    } else if (gameplayMode == GameplayMode.timeLimit) {
      // 限时赛：投掷球的玩家得分
      thrower.addScore(1);

      // 若发球者是人类玩家则更新显示
      if (thrower.controllerType == PlayerControllerType.human) {
        humanScoreNotifier.value = thrower.score;
      }
    }

    // 播放击中音效
    _audioManager.playHitSound();
  }

  /// 根据玩家ID找到玩家
  PlayerComponent? _findPlayerById(int playerId) {
    for (final player in [...redPlayers, ...bluePlayers]) {
      if (player.playerId == playerId) {
        return player;
      }
    }
    return null;
  }

  // 简化：点击屏幕由红队随机一人向点击点扔球，双击由蓝队投掷
  @override
  void onTapDown(TapDownEvent event) {
    if (gameState != GameState.playing || gameState == GameState.timeUp) {
      // 游戏结束时，点击重新开始
      restartGame();
      return;
    }
    _throwFromTeamTowards(Team.red, event.localPosition);
  }

  @override
  void onDoubleTapDown(DoubleTapDownEvent event) {
    if (gameState != GameState.playing || gameState == GameState.timeUp) {
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
      onHitPlayer: (b, hitPlayer) {
        _awardScoreForHit(b, hitPlayer);
      },
    );
    add(ball);

    // 播放投掷音效
    _audioManager.playThrowSound();

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
      onHitPlayer: (b, hitPlayer) {
        _awardScoreForHit(b, hitPlayer);
      },
    );
    add(ball);

    // 播放投掷音效
    _audioManager.playThrowSound();

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
      onHitPlayer: (b, hitPlayer) {
        _awardScoreForHit(b, hitPlayer);
      },
    );
    add(ball);

    // 播放投掷音效
    _audioManager.playThrowSound();

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

    // 限时赛模式下不检查淘汰胜利条件
    if (gameplayMode == GameplayMode.timeLimit) {
      return;
    }

    // 检查红队是否全部被淘汰
    // 由于被淘汰的玩家已经从列表中移除，直接检查列表长度
    final redAlive = redPlayers.length;
    final blueAlive = bluePlayers.length;

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

    // 播放胜利音效
    _audioManager.playVictorySound();

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

    // 重置限时赛状态
    _gameTimer?.removeFromParent();
    _gameTimer = null;
    _remainingTimeNotifier.value = 0;

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
    if (gameplayMode == GameplayMode.timeLimit) {
      // 限时赛模式：显示得分
      final redScore = redPlayers.fold<int>(
        0,
        (sum, player) => sum + player.score,
      );
      final blueScore = bluePlayers.fold<int>(
        0,
        (sum, player) => sum + player.score,
      );

      redTeamCountText?.text = '红队: $redScore分';
      blueTeamCountText?.text = '蓝队: $blueScore分';
    } else {
      // 淘汰赛模式：显示存活人数
      final redAlive = redPlayers.length;
      final blueAlive = bluePlayers.length;

      redTeamCountText?.text = '红队: $redAlive';
      blueTeamCountText?.text = '蓝队: $blueAlive';
    }
  }

  /// 当玩家被淘汰时调用
  void onPlayerEliminated(PlayerComponent player) {
    // 限时赛模式下不执行淘汰逻辑
    if (gameplayMode == GameplayMode.timeLimit) {
      return;
    }

    // 从玩家列表中移除被淘汰的玩家
    if (player.team == Team.red) {
      redPlayers.remove(player);
    } else {
      bluePlayers.remove(player);
    }

    // 从锁定列表中移除
    playersLocked.remove(player.playerId);

    // 更新统计显示
    _updateTeamCountDisplay();
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

  @override
  void onRemove() {
    // 停止背景音乐
    _audioManager.stopBackgroundMusic();
    super.onRemove();
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

      // 设置生命值（只在淘汰赛模式下）
      if (maxHealth != null && gameplayMode == GameplayMode.elimination) {
        red.setMaxHealth(maxHealth!);
      }

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

      // 设置生命值（只在淘汰赛模式下）
      if (maxHealth != null && gameplayMode == GameplayMode.elimination) {
        blue.setMaxHealth(maxHealth!);
      }

      bluePlayers.add(blue);
      add(blue);
    }

    // 如果是限时赛，启动计时器
    if (gameplayMode == GameplayMode.timeLimit && timeLimit != null) {
      _startTimeLimitGame();
    }
  }

  /// 启动限时赛
  void _startTimeLimitGame() {
    _remainingTimeNotifier.value = timeLimit!.seconds;

    _gameTimer = TimerComponent(
      period: 1.0,
      repeat: true,
      onTick: () {
        _remainingTimeNotifier.value--;

        if (_remainingTimeNotifier.value <= 0) {
          _handleTimeUp();
        }
      },
    );
    add(_gameTimer!);
  }

  /// 处理限时赛时间到
  void _handleTimeUp() {
    gameState = GameState.timeUp;

    // 停止计时器
    _gameTimer?.removeFromParent();
    _gameTimer = null;

    // 停止所有球的移动
    for (final ball in children.whereType<BallComponent>()) {
      ball.removeFromParent();
    }

    // 播放结束音效
    _audioManager.playVictorySound();

    // 显示得分统计
    _showScoreResults();
  }

  /// 显示得分统计
  void _showScoreResults() {
    // 计算各队得分
    final redTeamScore = redPlayers.fold<int>(
      0,
      (sum, player) => sum + player.score,
    );
    final blueTeamScore = bluePlayers.fold<int>(
      0,
      (sum, player) => sum + player.score,
    );

    // 背景遮罩
    final overlay = RectangleComponent(
      size: size,
      paint: Paint()..color = const Color(0x80000000), // 半透明黑色
    );
    add(overlay);

    // 标题
    final titleText = TextComponent(
      text: '游戏结束！',
      textRenderer: TextPaint(
        style: const TextStyle(
          fontSize: 36,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      anchor: Anchor.center,
      position: Vector2(size.x / 2, size.y / 2 - 80),
    );
    add(titleText);

    // 得分统计
    final scoreText = TextComponent(
      text: '红队得分: $redTeamScore\n蓝队得分: $blueTeamScore',
      textRenderer: TextPaint(
        style: const TextStyle(fontSize: 24, color: Colors.white, height: 1.5),
      ),
      anchor: Anchor.center,
      position: Vector2(size.x / 2, size.y / 2 - 20),
    );
    add(scoreText);

    // 获胜队伍
    final winnerText = TextComponent(
      text: redTeamScore > blueTeamScore
          ? '红队获胜！'
          : blueTeamScore > redTeamScore
          ? '蓝队获胜！'
          : '平局！',
      textRenderer: TextPaint(
        style: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: redTeamScore > blueTeamScore
              ? const Color(0xFFE53935)
              : blueTeamScore > redTeamScore
              ? const Color(0xFF1E88E5)
              : Colors.yellow,
        ),
      ),
      anchor: Anchor.center,
      position: Vector2(size.x / 2, size.y / 2 + 20),
    );
    add(winnerText);

    // 重新开始提示
    final restartText = TextComponent(
      text: '点击屏幕重新开始',
      textRenderer: TextPaint(
        style: const TextStyle(fontSize: 20, color: Color(0xFFFFFFFF)),
      ),
      anchor: Anchor.center,
      position: Vector2(size.x / 2, size.y / 2 + 80),
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
}
