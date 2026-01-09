import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import 'ai_controller.dart';
import 'arrow_component.dart';
import 'game_mode.dart';
import 'input_controller.dart';
import 'team.dart';

class PlayerComponent extends PositionComponent
    with CollisionCallbacks, HasGameReference {
  PlayerComponent({
    required this.team,
    required this.playerId,
    required Vector2 position, // 注意：这里的position参数表示玩家的中心位置
    this.controllerType = PlayerControllerType.human,
    this.radius = 16,
    this.aiIntelligenceLevel = 1.0,
    this.name, // 新增：玩家名称
    int maxHealth = 3, // 新增：最大生命值参数
    ui.Color? color,
  }) : _color = color ?? _teamColor(team),
       _maxHealth = maxHealth,
       _currentHealth = maxHealth,
       super(
         // 将中心位置转换为topLeft位置（左上角 = 中心 - 半径）
         position: position - Vector2.all(radius),
         size: Vector2.all(radius * 2),
         anchor: Anchor.topLeft, // 统一使用topLeft，与障碍物保持一致
       ) {
    // 设置随机初始冷却时间（1-10秒）
    final random = math.Random();
    _lastThrowTime = (1.0 + random.nextDouble() * 9.0); // 负值表示还在初始冷却中
  }

  final Team team;
  final int playerId;
  final PlayerControllerType controllerType;
  final double radius;
  final double aiIntelligenceLevel;
  final String? name; // 新增：玩家名称
  final ui.Color _color;
  bool isEliminated = false;
  bool _pendingRemoval = false; // 新增：标记是否待移除

  /// 获取玩家中心位置（因为anchor是topLeft，中心在position + radius）
  /// 用于逻辑计算（距离、方向等），与absoluteCenter等效
  Vector2 get center => position + Vector2.all(radius);

  /// 设置玩家中心位置
  set center(Vector2 centerPos) {
    position = centerPos - Vector2.all(radius);
  }

  // 新增：生命值系统
  int _maxHealth; // 最大生命值
  int _currentHealth; // 当前生命值
  int _score = 0; // 得分（限时赛用）

  // 生命值访问器
  int get maxHealth => _maxHealth;
  int get currentHealth => _currentHealth;
  int get score => _score;
  bool get isAlive => _currentHealth > 0;

  // 设置最大生命值
  void setMaxHealth(int health) {
    _maxHealth = health;
    _currentHealth = health;
    // 更新生命值显示
    _healthText?.text = '$_currentHealth/$_maxHealth';
  }

  // 设置当前生命值（用于关卡间传递）
  void setCurrentHealth(int health) {
    // 允许生命值超过初始最大值（吃血瓶可以加血超过3），但不能低于0
    // 绝对最大值限制为5
    _currentHealth = (health < 0 ? 0 : health).clamp(0, 5);
    // 更新生命值显示（显示当前值/初始最大值）
    _healthText?.text = '$_currentHealth/$_maxHealth';

    // 如果生命值为0，标记为淘汰
    if (_currentHealth <= 0 && !isEliminated) {
      isEliminated = true;
      eliminate();
    }
  }

  // 受到伤害
  void takeDamage() {
    // 正常处理伤害
    if (_currentHealth > 0 && !isEliminated) {
      _currentHealth--;
      // 更新生命值显示
      _healthText?.text = '$_currentHealth/$_maxHealth';
      if (_currentHealth <= 0) {
        isEliminated = true;
        // 当生命值耗尽时，从游戏中移除玩家
        eliminate();
      }
    }
  }

  // 增加得分（限时赛用）
  void addScore(int points) {
    _score += points;
  }

  // 重置生命值和得分
  void reset() {
    _currentHealth = _maxHealth;
    _score = 0;
    isEliminated = false;
    _pendingRemoval = false; // 重置移除标志
    // 更新生命值显示
    _healthText?.text = '$_currentHealth/$_maxHealth';
  }

  AIController? _aiController;
  InputController? _inputController;

  // 提供访问器以便游戏主类可以访问输入控制器
  InputController? get inputController => _inputController;

  // 设置输入控制器
  set inputController(InputController? controller) {
    // 移除旧的控制器
    _inputController?.removeFromParent();
    _inputController = controller;
    // 如果新控制器不为空且已加载，添加到组件树
    if (_inputController != null && isMounted) {
      add(_inputController!);
    }
  }

  // 移动相关
  double movementSpeed = 120.0;
  Vector2 _targetDirection = Vector2.zero();
  Vector2 _currentDirection = Vector2(1, 0); // 当前朝向方向，默认为向右

  // 投球冷却
  double _lastThrowTime = 0.0;
  static const double throwCooldown = 10.0; // 10秒基础冷却时间
  bool _attackSpeedBoost = false; // 攻速提升标记
  double _gameTimeInSeconds = 0.0; // 当前游戏时间（秒）

  // 更新游戏时间
  void updateGameTime(double gameTime) {
    _gameTimeInSeconds = gameTime;
  }

  // 冷却时间访问器
  double get effectiveThrowCooldown {
    // 根据游戏时间动态调整冷却时间
    double baseCooldown = throwCooldown;

    // 根据时间档位调整冷却时间
    if (_gameTimeInSeconds > 360) {
      // 超过6分钟：3秒（减少70%）
      baseCooldown = 3.0;
    } else if (_gameTimeInSeconds > 240) {
      // 超过4分钟：5秒（减少50%）
      baseCooldown = 5.0;
    } else if (_gameTimeInSeconds > 120) {
      // 超过2分钟：7秒（减少30%）
      baseCooldown = 7.0;
    }

    // 攻速提升时冷却时间减半
    return _attackSpeedBoost ? baseCooldown * 0.5 : baseCooldown;
  }

  bool get canThrow => _lastThrowTime >= effectiveThrowCooldown;
  double get throwCooldownRemaining => (effectiveThrowCooldown - _lastThrowTime)
      .clamp(0.0, effectiveThrowCooldown);

  // 重置投球冷却
  void resetThrowCooldown() {
    _lastThrowTime = 0.0;
  }

  // 设置攻速提升
  void setAttackSpeedBoost(bool boost) {
    _attackSpeedBoost = boost;
  }

  // 获取攻速提升状态
  bool get hasAttackSpeedBoost => _attackSpeedBoost;

  // 投掷后调用（用于更新冷却时间）
  void onThrow() {
    resetThrowCooldown();
  }

  // 设置朝向方向（供AI控制器使用）
  void setDirection(Vector2 direction) {
    if (direction.length > 0.1) {
      _currentDirection = direction.normalized();
      // 更新箭头方向，确保碰撞检测与视觉一致
      _arrowIcon?.updateDirection(_currentDirection);
    }
  }

  // 获取当前朝向方向
  Vector2 get currentDirection => _currentDirection;

  // 视觉组件
  ArrowComponent? _arrowIcon;
  TextComponent? _playerLabel;
  TimerComponent? _breathingTimer;
  TextComponent? _healthText; // 生命值显示

  static ui.Color _teamColor(Team team) {
    switch (team) {
      case Team.red:
        return const ui.Color(0xFFE53935);
      case Team.blue:
        return const ui.Color(0xFF1E88E5);
    }
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // 添加圆形碰撞体作为主要碰撞检测
    // 父组件anchor是topLeft，所以碰撞体中心应该在(radius, radius)位置
    add(
      CircleHitbox(
        radius: radius,
        position: Vector2.all(radius), // 碰撞体中心在(radius, radius)，即正方形的中心
        anchor: Anchor.center,
      ),
    );

    // 设置玩家视觉效果
    _setupPlayerVisuals();

    // 根据控制器类型设置控制器
    if (controllerType == PlayerControllerType.ai) {
      _setupAIController();
    } else {
      _setupInputController();
    }

    // 添加生命值显示
    _setupHealthDisplay();

    // 如果有待添加的输入控制器，现在添加它
    if (_inputController != null && !_inputController!.isMounted) {
      add(_inputController!);
    }
  }

  @override
  void onMount() {
    super.onMount();

    // 如果有待添加的输入控制器，现在添加它
    if (_inputController != null && !_inputController!.isMounted) {
      add(_inputController!);
    }
  }

  void _setupAIController() {
    final game = findGame();
    if (game != null) {
      _aiController = AIController(
        player: this,
        gameSize: game.size,
        difficultyLevel: aiIntelligenceLevel, // 使用传入的AI智能水平
      );
      add(_aiController!);
    }
  }

  void _setupInputController() {
    _inputController = InputController(
      playerId: playerId,
      onMove: _handleMovementInput,
      onThrow: _handleThrowInput,
    );
    add(_inputController!);
  }

  void _setupPlayerVisuals() {
    // 添加箭头图标
    _arrowIcon = ArrowComponent(sideLength: radius * 2, color: _color);
    add(_arrowIcon!);

    if (controllerType == PlayerControllerType.human) {
      // 人类玩家：添加王冠图标和特殊边框
      _setupHumanPlayerVisuals();
    } else {
      // AI玩家：保持原始外观
      _setupAIPlayerVisuals();
    }
  }

  void _setupHumanPlayerVisuals() {
    // 为人类玩家添加特殊的视觉效果
    // 1. 添加玩家标识
    String displayText;
    if (name != null && name!.isNotEmpty) {
      displayText = name!;
    } else {
      displayText = 'YOU';
    }

    _playerLabel = TextComponent(
      text: displayText,
      textRenderer: TextPaint(
        style: const TextStyle(
          fontSize: 6,
          fontWeight: FontWeight.bold,
          color: ui.Color(0xFFFFFFFF),
        ),
      ),
      anchor: Anchor.center,
      // 放在箭头主体中部略偏右
      position: Vector2(radius * 1.0, radius * 1.0),
    );
    _arrowIcon?.add(_playerLabel!);

    // 2. 更新箭头颜色，让人类玩家更亮
    final brightColor = _getBrightTeamColor(team);
    _arrowIcon?.color = brightColor;
  }

  void _setupAIPlayerVisuals() {
    // AI玩家：在箭头内部添加标识
    _playerLabel = TextComponent(
      text: 'AI',
      textRenderer: TextPaint(
        style: const TextStyle(
          fontSize: 6,
          fontWeight: FontWeight.bold,
          color: ui.Color(0xFFFFFFFF),
        ),
      ),
      anchor: Anchor.center,
      // 放在箭头主体中部略偏右
      position: Vector2(radius * 1.0, radius * 1.0),
    );
    _arrowIcon?.add(_playerLabel!);
  }

  void _setupHealthDisplay() {
    // 生命值显示在玩家上方
    _healthText = TextComponent(
      text: '$_currentHealth/$_maxHealth',
      textRenderer: TextPaint(
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: ui.Color(0xFFFFFFFF),
        ),
      ),
      anchor: Anchor.center,
      position: Vector2(0, -radius - 15), // 在玩家上方显示
    );
    add(_healthText!);
  }

  ui.Color _getBrightTeamColor(Team team) {
    switch (team) {
      case Team.red:
        return const ui.Color(0xFFFF1744); // 更亮的红色
      case Team.blue:
        return const ui.Color(0xFF2196F3); // 更亮的蓝色
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    // 检查是否应该移除
    if (_pendingRemoval) {
      _pendingRemoval = false;
      removeFromParent();
      return;
    }

    if (isEliminated) return;

    // 更新投球冷却时间
    _lastThrowTime += dt;

    // 注意：人类玩家的移动由 MissionDodgeballGame._applyKeyboardMovement 处理
    // 这里不再调用 _updateMovement，避免两套移动系统冲突
    // AI 玩家的移动由 AIController 处理

    // 更新箭头方向 - 使用当前朝向方向
    if (_currentDirection.length > 0.1) {
      _arrowIcon?.updateDirection(_currentDirection);
    }
  }

  void _handleMovementInput(Vector2 direction) {
    if (!isEliminated) {
      _targetDirection = direction;
      // 如果有移动输入，立即更新朝向方向
      if (direction.length > 0.1) {
        _currentDirection = direction;
      }
    }
  }

  // 公共方法：外部直接设置移动方向
  void setMovementDirection(Vector2 direction) {
    _handleMovementInput(direction);
  }

  void _handleThrowInput(Vector2 direction) {
    if (isEliminated) return;

    // 检查冷却时间
    if (!canThrow) {
      return; // 还在冷却中，不能投球
    }

    final game = findGame();
    if (game != null && game is HasPlayerThrowRequest) {
      // 使用当前朝向方向作为投掷方向
      final throwDirection = _currentDirection;
      final throwDistance = 200.0;
      final targetPosition = absoluteCenter + throwDirection * throwDistance;

      (game as HasPlayerThrowRequest).requestThrowFromPlayer(
        this,
        targetPosition,
      );

      // 重置冷却时间
      resetThrowCooldown();
    }
  }

  void eliminate() {
    if (isEliminated && _pendingRemoval) return; // 如果已经标记为待移除，直接返回
    isEliminated = true;
    _pendingRemoval = true; // 标记待移除

    // 停止控制器
    _aiController?.removeFromParent();
    _inputController?.removeFromParent();
    // 清理视觉组件
    _arrowIcon?.removeFromParent();
    _playerLabel?.removeFromParent();
    _breathingTimer?.removeFromParent();
    _healthText?.removeFromParent();
  }

  // 简单投掷接口：朝向某个方向扔球
  Vector2 throwDirectionTowards(Vector2 target) {
    final dir = (target - absoluteCenter).normalized();
    if (dir.x.isNaN || dir.y.isNaN) {
      return Vector2(1, 0);
    }
    return dir;
  }
}
