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
import 'mission_map.dart';
import 'obstacle_component.dart';
import 'player_component.dart';
import 'team.dart';
import 'power_up_component.dart';

/// Mission模式游戏：消灭敌人
class MissionDodgeballGame extends FlameGame
    with
        HasCollisionDetection,
        TapCallbacks,
        DoubleTapCallbacks,
        HasKeyboardHandlerComponents,
        HasThrowRequest,
        HasPlayerThrowRequest {
  MissionDodgeballGame({
    required this.missionMap,
    this.aiIntelligenceLevel = 1.0,
  });

  final MissionMap missionMap;
  final double aiIntelligenceLevel;
  final Random _random = Random();

  // 玩家和敌人列表
  final List<PlayerComponent> playerTeam = []; // 玩家队伍（红队）
  final List<PlayerComponent> enemyTeam = []; // 敌人队伍（蓝队）

  // 游戏状态
  GameState gameState = GameState.playing;

  // 人类玩家冷却时间监听（秒）
  final ValueNotifier<double> humanCooldownRemainingNotifier =
      ValueNotifier<double>(0);
  // 击杀数
  final ValueNotifier<int> killCountNotifier = ValueNotifier<int>(0);

  // 音频管理器
  final AudioManager _audioManager = AudioManager.instance;

  // 移动设备控制器
  MobileController? _mobileController;

  // 道具掉落定时器
  TimerComponent? _powerUpDropTimer;

  // 键盘输入状态
  Vector2 _keyboardMoveInput = Vector2.zero();

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // 初始化音频管理器
    await _audioManager.initialize();

    // 添加场地背景
    add(FieldBackground(gameSize: size));

    // 添加外围边界墙壁
    _addBoundaryWalls();

    // 加载地图障碍物
    _loadMapObstacles();

    // 生成玩家和敌人
    await _spawnPlayerAndEnemies();

    // 播放背景音乐
    await _audioManager.playBackgroundMusic();

    // 设置调试模式
    BallComponent.showDebugCollision = false;

    // 如果是移动设备，添加移动控制器
    if (MobileController.isMobileDevice) {
      _addMobileController();
    }

    // 启动道具掉落定时器（3-5分钟随机）
    _startPowerUpDropTimer();
  }

  /// 添加外围边界墙壁
  void _addBoundaryWalls() {
    // 边界墙壁由FieldBackground处理，这里不需要额外添加
  }

  /// 加载地图障碍物
  void _loadMapObstacles() {
    for (final obstacle in missionMap.obstacles) {
      final obstacleComponent = createObstacleFromData(obstacle);
      add(obstacleComponent);
    }
  }

  /// 生成玩家和敌人
  Future<void> _spawnPlayerAndEnemies() async {
    // 玩家在左侧（红队区域）生成
    final playerArea = FieldConfig.getRedTeamArea(size);
    final playerPosition = _findValidSpawnPosition(
      playerArea,
      Vector2(
        playerArea.left + playerArea.width / 2,
        playerArea.top + playerArea.height / 2,
      ),
    );

    final player = PlayerComponent(
      team: Team.red,
      playerId: 0,
      position: playerPosition,
      controllerType: PlayerControllerType.human,
      aiIntelligenceLevel: aiIntelligenceLevel,
      name: '玩家',
    );

    playerTeam.add(player);
    add(player);

    // 敌人在右侧（蓝队区域）随机生成
    final enemyArea = FieldConfig.getBluTeamArea(size);
    final enemyPositions = _generateEnemyPositions(enemyArea, missionMap.enemyCount);

    for (int i = 0; i < missionMap.enemyCount; i++) {
      final enemy = PlayerComponent(
        team: Team.blue,
        playerId: 100 + i,
        position: enemyPositions[i],
        controllerType: PlayerControllerType.ai,
        aiIntelligenceLevel: aiIntelligenceLevel,
        name: '敌人 ${i + 1}',
      );

      enemyTeam.add(enemy);
      add(enemy);
    }
  }

  /// 查找有效的生成位置（不与障碍物重叠）
  Vector2 _findValidSpawnPosition(Rect area, Vector2 preferredPosition) {
    const playerRadius = 16.0;
    const maxAttempts = 50;

    // 首先尝试首选位置
    if (!_isPositionOnObstacle(preferredPosition, playerRadius)) {
      return preferredPosition;
    }

    // 如果首选位置被占用，随机尝试其他位置
    for (int attempt = 0; attempt < maxAttempts; attempt++) {
      final randomX = area.left + _random.nextDouble() * area.width;
      final randomY = area.top + _random.nextDouble() * area.height;
      final testPosition = Vector2(randomX, randomY);

      if (!_isPositionOnObstacle(testPosition, playerRadius)) {
        return testPosition;
      }
    }

    // 如果实在找不到，返回首选位置（容错）
    return preferredPosition;
  }

  /// 检查位置是否在障碍物上
  bool _isPositionOnObstacle(Vector2 position, double radius) {
    for (final obstacle in children.whereType<ObstacleComponent>()) {
      final obstacleRect = Rect.fromLTWH(
        obstacle.position.x,
        obstacle.position.y,
        obstacle.size.x,
        obstacle.size.y,
      );

      // 扩展障碍物矩形以包含玩家半径
      final expandedRect = obstacleRect.inflate(radius);

      if (expandedRect.contains(Offset(position.x, position.y))) {
        return true;
      }
    }
    return false;
  }

  /// 在指定区域内生成敌人位置
  List<Vector2> _generateEnemyPositions(Rect area, int count) {
    final positions = <Vector2>[];
    final margin = 30.0;

    // 使用网格布局，但添加随机偏移
    final cols = (count <= 4) ? 2 : 3;
    final rows = (count + cols - 1) ~/ cols;

    final cellWidth = (area.width - margin * 2) / cols;
    final cellHeight = (area.height - margin * 2) / rows;

    int enemyIndex = 0;
    for (int row = 0; row < rows && enemyIndex < count; row++) {
      for (int col = 0; col < cols && enemyIndex < count; col++) {
        final baseX = area.left + margin + cellWidth * (col + 0.5);
        final baseY = area.top + margin + cellHeight * (row + 0.5);

        // 添加随机偏移
        final offsetX = (_random.nextDouble() - 0.5) * cellWidth * 0.3;
        final offsetY = (_random.nextDouble() - 0.5) * cellHeight * 0.3;

        positions.add(Vector2(baseX + offsetX, baseY + offsetY));
        enemyIndex++;
      }
    }

    return positions;
  }

  /// 添加移动设备控制器
  void _addMobileController() {
    _mobileController = MobileController(
      gameSize: size,
      onMove: _handleMobileMove,
      onThrow: () {
        // 移动设备投掷：朝向敌人方向投掷
        if (playerTeam.isEmpty) return;
        final player = playerTeam.first;
        if (player.isEliminated) return;

        // 找到最近的敌人作为目标
        Vector2? target;
        double minDistance = double.infinity;
        for (final enemy in enemyTeam) {
          if (enemy.isEliminated) continue;
          final distance = player.position.distanceTo(enemy.position);
          if (distance < minDistance) {
            minDistance = distance;
            target = enemy.position;
          }
        }

        if (target != null) {
          _throwFromPlayer(player, target);
        }
      },
    );
    add(_mobileController!);
  }

  void _handleMobileMove(Vector2 direction) {
    if (playerTeam.isEmpty) return;
    final player = playerTeam.first;
    if (player.isEliminated) return;

    final speed = player.movementSpeed;
    final moveVector = direction * speed;
    final newPosition = player.position + moveVector;

    // 限制在可玩区域内
    final clampedPosition = FieldConfig.clampToPlayableArea(newPosition, size);
    player.position = clampedPosition;
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (gameState != GameState.playing) return;

    // 应用键盘输入移动玩家
    _applyKeyboardMovement(dt);

    // 更新人类玩家冷却时间显示
    _updateHumanCooldownNotifier();

    // 处理边界反弹
    _handleWallBounces();

    // 检查游戏结束条件
    _checkGameOver();
  }

  /// 应用键盘输入移动玩家
  void _applyKeyboardMovement(double dt) {
    if (playerTeam.isEmpty) return;
    final player = playerTeam.first;
    if (player.isEliminated) return;
    
    // 如果有键盘输入
    if (_keyboardMoveInput.length > 0.01) {
      final speed = player.movementSpeed;
      final moveVector = _keyboardMoveInput.normalized() * speed * dt;
      final newPosition = player.position + moveVector;

      // 限制在可玩区域内
      final clampedPosition = FieldConfig.clampToPlayableArea(newPosition, size);
      
      // 检查是否与障碍物碰撞
      if (!_isPositionOnObstacle(clampedPosition, player.radius)) {
        player.position = clampedPosition;
        // 更新玩家朝向
        player.setDirection(_keyboardMoveInput.normalized());
      }
    }
  }

  void _updateHumanCooldownNotifier() {
    if (playerTeam.isEmpty) {
      if (humanCooldownRemainingNotifier.value != 0) {
        humanCooldownRemainingNotifier.value = 0;
      }
      return;
    }

    final player = playerTeam.first;
    if (player.isEliminated) {
      if (humanCooldownRemainingNotifier.value != 0) {
        humanCooldownRemainingNotifier.value = 0;
      }
      return;
    }

    final remaining = player.throwCooldownRemaining;
    if (humanCooldownRemainingNotifier.value != remaining) {
      humanCooldownRemainingNotifier.value = remaining;
    }
  }

  void _handleWallBounces() {
    for (final ball in children.whereType<BallComponent>()) {
      final r = ball.ballRadius;
      final px = ball.position.x;
      final py = ball.position.y;
      final wallThickness = FieldConfig.wallThickness;

      // 顶部边界
      if (py - r <= wallThickness && ball.velocity.y < 0) {
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

  void _checkGameOver() {
    // 检查玩家是否被淘汰
    final playerAlive = playerTeam.any((p) => !p.isEliminated);
    if (!playerAlive) {
      gameState = GameState.blueWins;
      _showGameOver(false);
      return;
    }

    // 检查所有敌人是否被消灭
    final enemiesAlive = enemyTeam.any((e) => !e.isEliminated);
    if (!enemiesAlive) {
      gameState = GameState.redWins;
      _showGameOver(true);
      return;
    }
  }

  void _showGameOver(bool playerWins) {
    final text = playerWins ? '胜利！' : '失败！';
    final color = playerWins ? Colors.green : Colors.red;

    final victoryText = TextComponent(
      text: text,
      textRenderer: TextPaint(
        style: TextStyle(
          fontSize: 64,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
      position: Vector2(size.x / 2, size.y / 2),
      anchor: Anchor.center,
    );

    add(victoryText);
  }

  @override
  KeyEventResult onKeyEvent(
    KeyEvent event,
    Set<LogicalKeyboardKey> keysPressed,
  ) {
    // 调用父类方法
    super.onKeyEvent(event, keysPressed);
    
    if (gameState != GameState.playing) {
      return KeyEventResult.handled;
    }

    if (playerTeam.isEmpty) return KeyEventResult.handled;
    final player = playerTeam.first;
    if (player.isEliminated) return KeyEventResult.handled;

    // 计算移动方向
    _keyboardMoveInput = Vector2.zero();

    // WASD 或箭头键移动
    if (keysPressed.contains(LogicalKeyboardKey.keyW) ||
        keysPressed.contains(LogicalKeyboardKey.arrowUp)) {
      _keyboardMoveInput.y -= 1;
    }
    if (keysPressed.contains(LogicalKeyboardKey.keyS) ||
        keysPressed.contains(LogicalKeyboardKey.arrowDown)) {
      _keyboardMoveInput.y += 1;
    }
    if (keysPressed.contains(LogicalKeyboardKey.keyA) ||
        keysPressed.contains(LogicalKeyboardKey.arrowLeft)) {
      _keyboardMoveInput.x -= 1;
    }
    if (keysPressed.contains(LogicalKeyboardKey.keyD) ||
        keysPressed.contains(LogicalKeyboardKey.arrowRight)) {
      _keyboardMoveInput.x += 1;
    }

    // 空格键投掷（沿箭头方向）
    if (event is KeyDownEvent && 
        event.logicalKey == LogicalKeyboardKey.space) {
      // 直接沿着箭头方向投掷
      if (player.currentDirection.length > 0.1) {
        final throwTarget = player.position + player.currentDirection * 100;
        _throwFromPlayer(player, throwTarget);
      }
    }

    return KeyEventResult.handled;
  }

  @override
  void onTapDown(TapDownEvent event) {
    if (gameState != GameState.playing) {
      return;
    }

    if (playerTeam.isEmpty) return;
    final player = playerTeam.first;
    if (player.isEliminated) return;

    _throwFromPlayer(player, event.localPosition);
  }

  void _throwFromPlayer(PlayerComponent player, Vector2 target) {
    if (player.isEliminated) return;
    if (!player.canThrow) return;

    // 使用玩家当前箭头方向作为投掷方向
    final direction = player.currentDirection.length > 0.1
        ? player.currentDirection.normalized()
        : (target - player.position).normalized(); // 回退：如果没有方向，使用目标方向
    
    final speed = 300.0; // 投掷速度
    final velocity = direction * speed;

    final ball = BallComponent(
      team: player.team,
      ownerPlayerId: player.playerId,
      position: player.position + direction * (player.radius + 10),
      initialVelocity: velocity,
      bounceCount: 1 + _random.nextInt(5), // 1-5次弹跳
      onHitPlayer: _onEnemyHit,
    );

    add(ball);
    player.onThrow();
  }

  void _onEnemyHit(BallComponent ball, PlayerComponent hitPlayer) {
    // 只处理击中敌人的情况
    if (hitPlayer.team != Team.blue) return;

    // 敌人受到伤害
    hitPlayer.takeDamage();

    // 如果敌人被淘汰
    if (hitPlayer.isEliminated) {
      killCountNotifier.value = killCountNotifier.value + 1;

      // 播放击中音效
      _audioManager.playHitSound();

      // 有概率掉落道具
      if (_random.nextDouble() < 0.3) {
        // 30%概率掉落道具
        _dropPowerUp(hitPlayer.position);
      }
    }
  }

  /// 掉落道具
  void _dropPowerUp(Vector2 position) {
    // 随机选择道具类型
    final powerUpType = _random.nextBool()
        ? PowerUpType.speedBoost
        : PowerUpType.attackSpeed;

    final powerUp = PowerUpComponent(
      type: powerUpType,
      position: position,
    );

    add(powerUp);
  }

  /// 启动道具掉落定时器
  void _startPowerUpDropTimer() {
    // 3-5分钟随机
    final dropInterval = 180.0 + _random.nextInt(120).toDouble(); // 180-300秒

    _powerUpDropTimer = TimerComponent(
      period: dropInterval,
      repeat: true,
      onTick: () {
        // 在地图随机位置掉落道具
        final randomX = FieldConfig.wallThickness +
            _random.nextDouble() *
                (size.x - FieldConfig.wallThickness * 2);
        final randomY = FieldConfig.wallThickness +
            _random.nextDouble() *
                (size.y - FieldConfig.wallThickness * 2);

        _dropPowerUp(Vector2(randomX, randomY));
      },
    );

    add(_powerUpDropTimer!);
  }

  /// 实现 HasThrowRequest 的方法
  @override
  void requestThrowFromAI(PlayerComponent thrower, Vector2 target) {
    if (gameState != GameState.playing ||
        thrower.isEliminated ||
        !thrower.canThrow) {
      return;
    }

    _throwFromPlayer(thrower, target);
  }

  /// 实现 HasPlayerThrowRequest 的方法
  @override
  void requestThrowFromPlayer(PlayerComponent thrower, Vector2 target) {
    if (gameState != GameState.playing ||
        thrower.isEliminated ||
        !thrower.canThrow) {
      return;
    }

    _throwFromPlayer(thrower, target);
  }

  @override
  void onRemove() {
    _audioManager.stopBackgroundMusic();
    super.onRemove();
  }
}

