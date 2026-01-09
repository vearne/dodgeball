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
import 'input_controller.dart';
import 'keyboard_config.dart';
import 'mobile_controller.dart';
import 'mission_map.dart';
import 'obstacle_component.dart';
import 'player_component.dart';
import 'player_state.dart';
import 'team.dart';
import 'power_up_component.dart';

/// Mission模式游戏：消灭敌人
class MissionDodgeballGame extends FlameGame
    with
        HasCollisionDetection,
        TapCallbacks,
        DoubleTapCallbacks,
        KeyboardEvents,
        HasThrowRequest,
        HasPlayerThrowRequest {
  MissionDodgeballGame({
    required this.missionMap,
    this.aiIntelligenceLevel = 1.0,
    this.maxHealth = 3,
    this.playerState, // 玩家状态（用于关卡间传递）
    this.onMissionComplete,
    this.onMissionFailed, // 新增：任务失败回调
    this.playerCount = 1, // 玩家数量（1或2）
  });

  final MissionMap missionMap;
  final double aiIntelligenceLevel;
  final int maxHealth;
  final PlayerState? playerState; // 可选的初始玩家状态
  final VoidCallback? onMissionComplete;
  final VoidCallback? onMissionFailed; // 新增：任务失败回调
  final int playerCount; // 玩家数量
  final Random _random = Random();

  // 关卡时间跟踪
  double _elapsedTime = 0.0;

  // 道具效果计时器
  TimerComponent? _speedBoostTimer;
  TimerComponent? _attackSpeedBoostTimer;

  /// 应用速度提升道具（由PowerUpComponent调用）
  void applySpeedBoost(PlayerComponent player, {double duration = 10.0}) {
    const originalSpeed = 120.0; // 默认速度
    player.movementSpeed = originalSpeed * 1.2; // 改为20%增速

    // 取消之前的定时器
    _speedBoostTimer?.removeFromParent();

    // 创建新的定时器
    _speedBoostTimer = TimerComponent(
      period: duration,
      onTick: () {
        player.movementSpeed = originalSpeed;
        _speedBoostTimer = null;
      },
    );
    add(_speedBoostTimer!);
  }

  /// 应用攻速提升道具（由PowerUpComponent调用）
  void applyAttackSpeedBoost(PlayerComponent player, {double duration = 30.0}) {
    player.setAttackSpeedBoost(true);

    // 取消之前的定时器
    _attackSpeedBoostTimer?.removeFromParent();

    // 创建新的定时器
    _attackSpeedBoostTimer = TimerComponent(
      period: duration,
      onTick: () {
        player.setAttackSpeedBoost(false);
        _attackSpeedBoostTimer = null;
      },
    );
    add(_attackSpeedBoostTimer!);
  }

  // 玩家和敌人列表
  final List<PlayerComponent> playerTeam = []; // 玩家队伍（红队）
  final List<PlayerComponent> enemyTeam = []; // 敌人队伍（蓝队）

  // 游戏状态
  GameState gameState = GameState.playing;

  // 人类玩家冷却时间监听（秒）- 每个玩家独立
  final Map<int, ValueNotifier<double>> playerCooldownNotifiers = {};
  // 每个玩家的击杀数统计
  final Map<int, ValueNotifier<int>> playerKillNotifiers = {};
  // 玩家当前生命值
  final ValueNotifier<int> playerHealthNotifier = ValueNotifier<int>(0);

  // 音频管理器
  final AudioManager _audioManager = AudioManager.instance;

  // 移动设备控制器
  MobileController? _mobileController;

  // 道具掉落定时器
  TimerComponent? _powerUpDropTimer;

  // 当前存在的道具数量
  int _currentPowerUpCount = 0;

  // 键盘输入状态（每个玩家）
  final Map<int, Vector2> _keyboardMoveInputs = {};

  // 输入控制器（每个玩家）
  final Map<int, InputController> _inputControllers = {};

  // 键盘配置（每个玩家）
  final Map<int, KeyboardConfig> _keyboardConfigs = {};

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // 初始化关卡计时器
    _elapsedTime = 0.0;

    // 初始化音频管理器
    await _audioManager.initialize();

    // 添加场地背景
    add(FieldBackground(gameSize: size));

    // 添加外围边界墙壁
    _addBoundaryWalls();

    // 加载地图障碍物（等待加载完成）
    await _loadMapObstacles();

    // 加载键盘配置
    await _loadKeyboardConfigs();

    // 生成玩家和敌人
    await _spawnPlayerAndEnemies();

    // 延迟一小段时间后播放背景音乐，确保关卡完全加载
    Future.delayed(const Duration(milliseconds: 100), () {
      _audioManager.playBackgroundMusic();
    });

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
  Future<void> _loadMapObstacles() async {
    for (final obstacle in missionMap.obstacles) {
      final obstacleComponent = createObstacleFromData(obstacle);
      add(obstacleComponent);
      // 等待障碍物完全加载（确保 onLoad 完成，子组件创建完毕）
      await obstacleComponent.loaded;
    }
  }

  /// 加载键盘配置
  Future<void> _loadKeyboardConfigs() async {
    for (int i = 0; i < playerCount; i++) {
      _keyboardConfigs[i] = await KeyboardConfig.load(i);
      _keyboardMoveInputs[i] = Vector2.zero();
    }
  }

  /// 生成玩家和敌人
  Future<void> _spawnPlayerAndEnemies() async {
    // 玩家在左侧（红队区域）生成
    final playerArea = FieldConfig.getRedTeamArea(size);

    // 生成玩家1
    Vector2 player1Position;
    // 检查是否配置了玩家1的初始位置
    PlayerInitialPosition? player1InitialConfig;
    if (missionMap.playerInitialPositions != null) {
      try {
        player1InitialConfig = missionMap.playerInitialPositions!.firstWhere(
          (p) => p.playerId == 0,
        );
      } catch (e) {
        player1InitialConfig = null;
      }
    }
    if (player1InitialConfig != null) {
      // 使用配置的初始位置
      player1Position = _findValidSpawnPosition(
        playerArea,
        Vector2(player1InitialConfig.x, player1InitialConfig.y),
      );
    } else {
      // 使用默认位置
      player1Position = _findValidSpawnPosition(
        playerArea,
        Vector2(
          playerArea.left + playerArea.width / 3,
          playerArea.top + playerArea.height / 2,
        ),
      );
    }

    final player1 = PlayerComponent(
      team: Team.red,
      playerId: 0,
      position: player1Position,
      controllerType: PlayerControllerType.human,
      aiIntelligenceLevel: aiIntelligenceLevel,
      name: '玩家1',
      maxHealth: maxHealth,
    );

    playerTeam.add(player1);
    add(player1);

    // 等待玩家组件完全加载
    await player1.loaded;

    // 为玩家1创建输入控制器（替换默认的）
    final inputController1 = InputController(
      playerId: 0,
      keyboardConfig: _keyboardConfigs[0],
      onMove: (direction) {
        _keyboardMoveInputs[0] = direction;
      },
      onThrow: (direction) {
        if (player1.isEliminated || !player1.canThrow) return;
        final throwTarget = player1.position + direction * 100;
        _throwFromPlayer(player1, throwTarget);
      },
    );
    player1.inputController = inputController1;
    _inputControllers[0] = inputController1;

    // 为玩家1创建冷却时间通知器
    playerCooldownNotifiers[0] = ValueNotifier<double>(0);

    // 为玩家1创建击杀数通知器
    playerKillNotifiers[0] = ValueNotifier<int>(0);

    // 如果有保存的玩家状态，应用它（只应用到玩家1）
    if (playerState != null) {
      _applyPlayerState(player1, playerState!);
    }

    // 如果支持2人游戏，生成玩家2
    if (playerCount >= 2) {
      Vector2 player2Position;
      // 检查是否配置了玩家2的初始位置
      PlayerInitialPosition? player2InitialConfig;
      if (missionMap.playerInitialPositions != null) {
        try {
          player2InitialConfig = missionMap.playerInitialPositions!.firstWhere(
            (p) => p.playerId == 1,
          );
        } catch (e) {
          player2InitialConfig = null;
        }
      }
      if (player2InitialConfig != null) {
        // 使用配置的初始位置
        player2Position = _findValidSpawnPosition(
          playerArea,
          Vector2(player2InitialConfig.x, player2InitialConfig.y),
        );
      } else {
        // 使用默认位置
        player2Position = _findValidSpawnPosition(
          playerArea,
          Vector2(
            playerArea.left + playerArea.width * 2 / 3,
            playerArea.top + playerArea.height / 2,
          ),
        );
      }

      final player2 = PlayerComponent(
        team: Team.red,
        playerId: 1,
        position: player2Position,
        controllerType: PlayerControllerType.human,
        aiIntelligenceLevel: aiIntelligenceLevel,
        name: '玩家2',
        maxHealth: maxHealth,
      );

      playerTeam.add(player2);
      add(player2);

      // 等待玩家组件完全加载
      await player2.loaded;

      // 为玩家2创建输入控制器（替换默认的）
      final inputController2 = InputController(
        playerId: 1,
        keyboardConfig: _keyboardConfigs[1],
        onMove: (direction) {
          _keyboardMoveInputs[1] = direction;
        },
        onThrow: (direction) {
          if (player2.isEliminated || !player2.canThrow) return;
          final throwTarget = player2.position + direction * 100;
          _throwFromPlayer(player2, throwTarget);
        },
      );
      // 替换默认的输入控制器
      player2.inputController = inputController2;
      _inputControllers[1] = inputController2;

      // 为玩家2创建冷却时间通知器
      playerCooldownNotifiers[1] = ValueNotifier<double>(0);

      // 为玩家2创建击杀数通知器
      playerKillNotifiers[1] = ValueNotifier<int>(0);
    }

    // 敌人在右侧（蓝队区域）随机生成
    final enemyArea = FieldConfig.getBluTeamArea(size);
    final enemyPositions = _generateEnemyPositions(
      enemyArea,
      missionMap.enemyCount,
    );

    for (int i = 0; i < missionMap.enemyCount; i++) {
      final enemy = PlayerComponent(
        team: Team.blue,
        playerId: 100 + i,
        position: enemyPositions[i],
        controllerType: PlayerControllerType.ai,
        aiIntelligenceLevel: aiIntelligenceLevel,
        name: '敌人 ${i + 1}',
        maxHealth: 1, // AI敌人固定为1条命
      );

      enemyTeam.add(enemy);
      add(enemy);
    }
  }

  /// 查找有效的生成位置（不与障碍物和其他玩家重叠）
  Vector2 _findValidSpawnPosition(Rect area, Vector2 preferredPosition) {
    const playerRadius = 16.0;
    const maxAttempts = 50;
    const minDistanceBetweenPlayers = playerRadius * 2 + 4.0; // 玩家之间的最小距离
    final playerSize = Vector2.all(playerRadius * 2); // 玩家矩形碰撞区域大小

    // 首先尝试首选位置
    final obstacleCheck = _isPositionOnObstacle(preferredPosition, playerSize);
    final playerCheck = _isPositionTooCloseToPlayers(
      preferredPosition,
      minDistanceBetweenPlayers,
    );

    if (!obstacleCheck && !playerCheck) {
      return preferredPosition;
    }

    // 如果首选位置被占用，随机尝试其他位置
    for (int attempt = 0; attempt < maxAttempts; attempt++) {
      final randomX = area.left + _random.nextDouble() * area.width;
      final randomY = area.top + _random.nextDouble() * area.height;
      final testPosition = Vector2(randomX, randomY);

      if (!_isPositionOnObstacle(testPosition, playerSize) &&
          !_isPositionTooCloseToPlayers(
            testPosition,
            minDistanceBetweenPlayers,
          )) {
        return testPosition;
      }
    }

    // 如果实在找不到，返回首选位置（容错）
    return preferredPosition;
  }

  /// 检查位置是否离其他已生成的玩家太近
  bool _isPositionTooCloseToPlayers(Vector2 position, double minDistance) {
    // 检查与已添加到游戏中的所有玩家的距离
    for (final player in children.whereType<PlayerComponent>()) {
      final distance = position.distanceTo(player.center);
      if (distance < minDistance) {
        return true; // 太近了
      }
    }
    return false; // 距离足够远
  }

  /// 检查位置是否在障碍物上（使用圆形碰撞检测）
  bool _isPositionOnObstacle(Vector2 position, Vector2 playerSize) {
    // playerSize 转换为半径（取较小的一边）
    final radius = playerSize.x / 2;
    // 递归检查所有障碍物组件（包括嵌套在 BrickWallComponent 中的原子砖块）
    return _checkObstacleCollisionRecursive(this, position, radius);
  }

  /// 递归检查组件树中的障碍物碰撞（圆形与矩形碰撞检测）
  bool _checkObstacleCollisionRecursive(
    Component parent,
    Vector2 circleCenter,
    double circleRadius,
  ) {
    for (final child in parent.children) {
      // 如果是 ObstacleComponent（AtomicBrickComponent 或 RockComponent），检查碰撞
      if (child is ObstacleComponent) {
        // 使用 absolutePosition 获取障碍物在世界坐标系中的位置
        // ObstacleComponent 的 anchor 是 Anchor.topLeft
        // 所以 absolutePosition 就是左上角坐标
        final obstacleAbsPos = child.absolutePosition;
        final obstacleRect = Rect.fromLTWH(
          obstacleAbsPos.x,
          obstacleAbsPos.y,
          child.size.x,
          child.size.y,
        );
        if (_circleRectCollision(circleCenter, circleRadius, obstacleRect)) {
          return true;
        }
      }

      // 递归检查子组件（例如 BrickWallComponent 的子组件）
      if (_checkObstacleCollisionRecursive(child, circleCenter, circleRadius)) {
        return true;
      }
    }
    return false;
  }

  /// 圆形与矩形碰撞检测
  bool _circleRectCollision(
    Vector2 circleCenter,
    double circleRadius,
    Rect rect,
  ) {
    // 找到矩形上离圆心最近的点
    final closestX = circleCenter.x.clamp(rect.left, rect.right);
    final closestY = circleCenter.y.clamp(rect.top, rect.bottom);

    // 计算圆心到最近点的距离
    final distanceX = circleCenter.x - closestX;
    final distanceY = circleCenter.y - closestY;
    final distanceSquared = distanceX * distanceX + distanceY * distanceY;

    // 如果距离小于半径，则发生碰撞
    return distanceSquared < circleRadius * circleRadius;
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

        final preferredPosition = Vector2(baseX + offsetX, baseY + offsetY);

        // 使用 _findValidSpawnPosition 确保位置不与障碍物碰撞
        final validPosition = _findValidSpawnPosition(area, preferredPosition);
        positions.add(validPosition);
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
          final distance = player.center.distanceTo(enemy.center);
          if (distance < minDistance) {
            minDistance = distance;
            target = enemy.center;
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
    final moveVector = direction.normalized() * speed * 0.016; // 使用固定时间步长
    final newPosition = player.center + moveVector;

    // 检查新位置是否在对应的队伍区域内（考虑玩家半径）
    final isRedTeam = player.team == Team.red;
    final isInArea = isRedTeam
        ? FieldConfig.isInRedTeamArea(
            newPosition,
            size,
            playerRadius: player.radius,
          )
        : FieldConfig.isInBlueTeamArea(
            newPosition,
            size,
            playerRadius: player.radius,
          );

    // 只有在区域内且不与障碍物碰撞时才移动
    if (isInArea && !_isPositionOnObstacle(newPosition, player.size)) {
      player.center = newPosition;
    } else {
      // 如果不在区域内，尝试限制到边界内（考虑玩家半径）
      final clampedPosition = FieldConfig.clampToTeamArea(
        newPosition,
        isRedTeam,
        size,
        playerRadius: player.radius,
      );
      // 只有当限制后的位置仍在区域内时才更新
      final clampedInArea = isRedTeam
          ? FieldConfig.isInRedTeamArea(
              clampedPosition,
              size,
              playerRadius: player.radius,
            )
          : FieldConfig.isInBlueTeamArea(
              clampedPosition,
              size,
              playerRadius: player.radius,
            );
      if (clampedInArea &&
          !_isPositionOnObstacle(clampedPosition, player.size)) {
        player.center = clampedPosition;
      }
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (gameState != GameState.playing) return;

    // 跟踪游戏进行时间
    _elapsedTime += dt;

    // 应用键盘输入移动玩家
    _applyKeyboardMovement(dt);

    // 更新人类玩家冷却时间显示
    _updateHumanCooldownNotifier();

    // 更新玩家生命值显示
    _updatePlayerHealthNotifier();

    // 处理边界反弹
    _handleWallBounces();

    // 检查游戏结束条件
    _checkGameOver();
  }

  /// 应用键盘输入移动玩家
  void _applyKeyboardMovement(double dt) {
    // 为每个玩家应用输入
    for (final player in playerTeam) {
      if (player.isEliminated ||
          player.controllerType != PlayerControllerType.human) {
        continue;
      }

      final input = _keyboardMoveInputs[player.playerId];
      if (input == null || input.length < 0.01) continue;

      final speed = player.movementSpeed;
      final moveVector = input.normalized() * speed * dt;
      final newPosition = player.center + moveVector;

      // 检查新位置是否在对应的队伍区域内（考虑玩家半径）
      final isRedTeam = player.team == Team.red;
      final isInArea = isRedTeam
          ? FieldConfig.isInRedTeamArea(
              newPosition,
              size,
              playerRadius: player.radius,
            )
          : FieldConfig.isInBlueTeamArea(
              newPosition,
              size,
              playerRadius: player.radius,
            );

      // 只有在区域内且不与障碍物碰撞时才移动
      final obstacleCollision = _isPositionOnObstacle(newPosition, player.size);

      if (isInArea && !obstacleCollision) {
        player.center = newPosition;
        // 更新玩家朝向
        player.setDirection(input.normalized());
      } else {
        // 如果不在区域内或与障碍物碰撞，尝试分轴移动（沿墙滑动）
        bool moved = false;

        // 先尝试只在 X 轴移动
        final newPosX = Vector2(newPosition.x, player.center.y);
        final isInAreaX = isRedTeam
            ? FieldConfig.isInRedTeamArea(
                newPosX,
                size,
                playerRadius: player.radius,
              )
            : FieldConfig.isInBlueTeamArea(
                newPosX,
                size,
                playerRadius: player.radius,
              );

        if (isInAreaX && !_isPositionOnObstacle(newPosX, player.size)) {
          player.center = newPosX;
          player.setDirection(input.normalized());
          moved = true;
        }

        // 如果 X 轴没移动，再尝试只在 Y 轴移动
        if (!moved) {
          final newPosY = Vector2(player.center.x, newPosition.y);
          final isInAreaY = isRedTeam
              ? FieldConfig.isInRedTeamArea(
                  newPosY,
                  size,
                  playerRadius: player.radius,
                )
              : FieldConfig.isInBlueTeamArea(
                  newPosY,
                  size,
                  playerRadius: player.radius,
                );

          if (isInAreaY && !_isPositionOnObstacle(newPosY, player.size)) {
            player.center = newPosY;
            player.setDirection(input.normalized());
          }
        }
        // 如果都不行，玩家保持原位
      }
    }
  }

  void _updateHumanCooldownNotifier() {
    // 更新所有人类玩家的冷却时间
    for (final player in playerTeam) {
      if (player.controllerType != PlayerControllerType.human ||
          player.isEliminated) {
        continue;
      }

      final playerId = player.playerId;
      final notifier = playerCooldownNotifiers[playerId];

      if (notifier != null) {
        final remaining = player.throwCooldownRemaining;
        if (notifier.value != remaining) {
          notifier.value = remaining;
        }
      } else {
        // 如果通知器不存在，创建一个
        playerCooldownNotifiers[playerId] = ValueNotifier<double>(
          player.throwCooldownRemaining,
        );
      }
    }

    // 清理已淘汰玩家的通知器
    final activePlayerIds = playerTeam
        .where(
          (p) =>
              p.controllerType == PlayerControllerType.human && !p.isEliminated,
        )
        .map((p) => p.playerId)
        .toSet();

    playerCooldownNotifiers.removeWhere(
      (playerId, _) => !activePlayerIds.contains(playerId),
    );
  }

  /// 获取玩家的冷却时间通知器（用于向后兼容）
  ValueNotifier<double> get humanCooldownRemainingNotifier {
    // 返回第一个玩家的冷却时间通知器，如果没有则创建一个默认的
    if (playerCooldownNotifiers.isEmpty) {
      return ValueNotifier<double>(0);
    }
    return playerCooldownNotifiers.values.first;
  }

  /// 获取总击杀数（用于向后兼容）
  ValueNotifier<int> get killCountNotifier {
    int total = 0;
    for (final notifier in playerKillNotifiers.values) {
      total += notifier.value;
    }
    return ValueNotifier<int>(total);
  }

  /// 获取每个玩家的击杀数（用于关卡完成统计）
  Map<int, int> get playerKillCounts {
    final Map<int, int> counts = {};
    for (final entry in playerKillNotifiers.entries) {
      counts[entry.key] = entry.value.value;
    }
    return counts;
  }

  void _updatePlayerHealthNotifier() {
    // 计算所有人类玩家的总生命值
    int totalHealth = 0;
    for (final player in playerTeam) {
      if (player.controllerType == PlayerControllerType.human &&
          !player.isEliminated) {
        totalHealth += player.currentHealth;
      }
    }

    if (playerHealthNotifier.value != totalHealth) {
      playerHealthNotifier.value = totalHealth;
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

    if (playerWins) {
      // 如果玩家胜利，调用关卡完成回调
      if (onMissionComplete != null) {
        // 停止背景音乐并播放胜利音效
        _audioManager.stopBackgroundMusic();
        _audioManager.playVictorySound();

        // 延迟2.5秒后调用，让玩家看到胜利文字和听到胜利音效
        Future.delayed(const Duration(milliseconds: 2500), () {
          onMissionComplete!();
        });
      }
    } else {
      // 如果玩家失败，调用任务失败回调
      if (onMissionFailed != null) {
        // 停止背景音乐并播放击中音效
        _audioManager.stopBackgroundMusic();
        _audioManager.playHitSound();

        // 延迟3秒后自动返回首页
        Future.delayed(const Duration(seconds: 3), () {
          onMissionFailed!();
        });
      }
    }
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

    // 将按键事件传递给所有输入控制器
    for (final controller in _inputControllers.values) {
      controller.handleKeyEvent(keysPressed);
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
        : (target - player.center).normalized(); // 回退：如果没有方向，使用目标方向

    final speed = 300.0; // 投掷速度
    final velocity = direction * speed;

    final ball = BallComponent(
      team: player.team,
      ownerPlayerId: player.playerId,
      position: player.center + direction * (player.radius + 10),
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
      // 增加击杀者的击杀数
      final killerId = ball.ownerPlayerId;
      if (playerKillNotifiers.containsKey(killerId)) {
        playerKillNotifiers[killerId]!.value++;
      }

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
    // 如果地图没有配置道具，不掉落
    if (missionMap.allowedPowerUps.isEmpty) {
      return;
    }

    // 检查是否达到最大数量限制
    if (missionMap.maxPowerUps != null &&
        _currentPowerUpCount >= missionMap.maxPowerUps!) {
      return;
    }

    // 从地图允许的道具中随机选择
    final powerUpType = missionMap
        .allowedPowerUps[_random.nextInt(missionMap.allowedPowerUps.length)];

    final powerUp = PowerUpComponent(
      type: powerUpType,
      position: position,
      onCollected: () {
        // 道具被拾取时减少计数器
        _currentPowerUpCount--;
      },
    );

    add(powerUp);
    _currentPowerUpCount++;
  }

  /// 启动道具掉落定时器
  void _startPowerUpDropTimer() {
    // 如果地图没有配置道具，不启动定时器
    if (missionMap.allowedPowerUps.isEmpty) {
      return;
    }

    // 使用地图配置的生成间隔
    final dropInterval = missionMap.powerUpSpawnInterval;

    _powerUpDropTimer = TimerComponent(
      period: dropInterval,
      repeat: true,
      onTick: () {
        // 在地图随机空白位置掉落道具
        final position = _findValidPowerUpPosition();
        if (position != null) {
          _dropPowerUp(position);
        }
      },
    );

    add(_powerUpDropTimer!);
  }

  /// 查找有效的道具生成位置（不在障碍物和玩家位置）
  Vector2? _findValidPowerUpPosition() {
    const powerUpSize = 32.0; // 道具大小
    const maxAttempts = 50;
    final playableArea = FieldConfig.getPlayableArea(size);
    final powerUpSizeVec = Vector2.all(powerUpSize);

    for (int attempt = 0; attempt < maxAttempts; attempt++) {
      // 在可玩区域内随机生成位置
      final randomX =
          playableArea.left + _random.nextDouble() * playableArea.width;
      final randomY =
          playableArea.top + _random.nextDouble() * playableArea.height;
      final testPosition = Vector2(randomX, randomY);

      // 检查是否在障碍物上（使用矩形碰撞检测）
      if (_isPositionOnObstacle(testPosition, powerUpSizeVec)) {
        continue;
      }

      // 检查是否与玩家重叠
      bool tooCloseToPlayer = false;
      for (final player in children.whereType<PlayerComponent>()) {
        if (player.isEliminated) continue;
        final distance = testPosition.distanceTo(player.center);
        if (distance < powerUpSize / 2 + player.radius + 10.0) {
          tooCloseToPlayer = true;
          break;
        }
      }

      if (tooCloseToPlayer) {
        continue;
      }

      // 找到有效位置
      return testPosition;
    }

    // 如果实在找不到，返回null
    return null;
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

  /// 应用玩家状态（用于关卡间传递）
  void _applyPlayerState(PlayerComponent player, PlayerState state) {
    // 设置生命值（保留上一关的生命值，包括超过默认最大值的情况）
    // 使用一个合理的最大值上限（999），避免 Infinity 转换错误
    final healthToSet = state.currentHealth.clamp(1, 999);
    player.setCurrentHealth(healthToSet);

    // 应用速度提升效果（使用剩余时间）
    if (state.hasSpeedBoost && state.speedBoostRemainingTime > 0) {
      applySpeedBoost(player, duration: state.speedBoostRemainingTime);
    }

    // 应用攻速提升效果（使用剩余时间）
    if (state.hasAttackSpeedBoost && state.attackSpeedBoostRemainingTime > 0) {
      applyAttackSpeedBoost(
        player,
        duration: state.attackSpeedBoostRemainingTime,
      );
    }
  }

  /// 获取当前玩家状态（用于关卡间传递）
  /// 注意：只返回第一个玩家的状态
  PlayerState? getCurrentPlayerState() {
    if (playerTeam.isEmpty) return null;

    // 找到第一个人类玩家
    PlayerComponent? player;
    for (final p in playerTeam) {
      if (p.controllerType == PlayerControllerType.human && !p.isEliminated) {
        player = p;
        break;
      }
    }
    if (player == null) return null;

    // 计算道具剩余时间
    final speedBoostRemaining =
        _speedBoostTimer != null && _speedBoostTimer!.isMounted
        ? _speedBoostTimer!.timer.limit - _speedBoostTimer!.timer.current
        : 0.0;

    final attackSpeedBoostRemaining =
        _attackSpeedBoostTimer != null && _attackSpeedBoostTimer!.isMounted
        ? _attackSpeedBoostTimer!.timer.limit -
              _attackSpeedBoostTimer!.timer.current
        : 0.0;

    return PlayerState(
      currentHealth: player.currentHealth,
      hasSpeedBoost: player.movementSpeed > 120.0,
      hasAttackSpeedBoost: player.hasAttackSpeedBoost,
      speedBoostRemainingTime: speedBoostRemaining,
      attackSpeedBoostRemainingTime: attackSpeedBoostRemaining,
    );
  }

  /// 获取关卡经过时间（秒）
  double get elapsedTimeInSeconds => _elapsedTime;

  @override
  void onRemove() {
    // 不在这里停止背景音乐，因为在关卡切换时会导致音乐中断
    // 背景音乐会在真正退出游戏或新关卡开始时自动处理
    super.onRemove();
  }
}
