import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import 'ai_controller.dart';
import 'arrow_component.dart';
import 'crown_component.dart';
import 'field_config.dart';
import 'game_mode.dart';
import 'input_controller.dart';
import 'team.dart';

class PlayerComponent extends PositionComponent
    with CollisionCallbacks, HasGameReference {
  PlayerComponent({
    required this.team,
    required this.playerId,
    required Vector2 position,
    this.controllerType = PlayerControllerType.human,
    this.radius = 16,
    ui.Color? color,
  }) : _color = color ?? _teamColor(team),
       super(
         position: position,
         size: Vector2.all(radius * 2),
         anchor: Anchor.center,
       ) {
    // 设置随机初始冷却时间（1-10秒）
    final random = math.Random();
    _lastThrowTime = -(1.0 + random.nextDouble() * 9.0); // 负值表示还在初始冷却中
  }

  final Team team;
  final int playerId;
  final PlayerControllerType controllerType;
  final double radius;
  final ui.Color _color;
  bool isEliminated = false;

  AIController? _aiController;
  InputController? _inputController;

  // 提供访问器以便游戏主类可以访问输入控制器
  InputController? get inputController => _inputController;

  // 移动相关
  double movementSpeed = 120.0;
  Vector2 _velocity = Vector2.zero();
  Vector2 _targetDirection = Vector2.zero();

  // 投球冷却
  double _lastThrowTime = 0.0;
  static const double throwCooldown = 10.0; // 10秒冷却时间

  // 冷却时间访问器
  bool get canThrow => _lastThrowTime >= throwCooldown;
  double get throwCooldownRemaining =>
      (throwCooldown - _lastThrowTime).clamp(0.0, throwCooldown);

  // 重置投球冷却
  void resetThrowCooldown() {
    _lastThrowTime = 0.0;
  }

  // 视觉组件
  ArrowComponent? _arrowIcon;
  CrownComponent? _crownIcon;
  TextComponent? _playerLabel;
  TimerComponent? _breathingTimer;

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

    // 添加统一尺寸的“身体”圆形（视觉与碰撞一致）
    final body = CircleComponent(
      radius: radius,
      anchor: Anchor.center,
      paint: ui.Paint()
        ..color = _color
        ..style = ui.PaintingStyle.fill,
    );
    add(body);

    // 添加圆形碰撞检测（与视觉半径一致）
    add(CircleHitbox(radius: radius));

    // 设置玩家视觉效果
    _setupPlayerVisuals();

    // 根据控制器类型设置控制器
    if (controllerType == PlayerControllerType.ai) {
      _setupAIController();
    } else {
      _setupInputController();
    }
  }

  void _setupAIController() {
    final game = findGame();
    if (game != null) {
      _aiController = AIController(
        player: this,
        gameSize: game.size,
        difficultyLevel: 1.0, // 可以根据需要调整难度
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
    _arrowIcon = ArrowComponent(
      size: radius * 2,
      color: _color,
      angle: 0.0, // 初始方向向右
    );
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

    // 1. 添加王冠图标
    _crownIcon = CrownComponent(
      size: radius * 0.8,
      color: const ui.Color(0xFFFFD700), // 金色王冠
    );
    // 王冠继承自Component，需要用PositionComponent包装
    final crownWrapper = PositionComponent(
      position: Vector2(0, -radius * 0.3),
      children: [_crownIcon!],
    );
    add(crownWrapper);

    // 2. 添加"HUMAN"标识
    _playerLabel = TextComponent(
      text: 'YOU',
      textRenderer: TextPaint(
        style: const TextStyle(
          fontSize: 8,
          fontWeight: FontWeight.bold,
          color: ui.Color(0xFFFFFFFF), // 白色
        ),
      ),
      anchor: Anchor.center,
      position: Vector2(0, radius * 0.7), // 位于玩家下方
    );
    add(_playerLabel!);

    // 3. 更新箭头颜色，让人类玩家更亮
    final brightColor = _getBrightTeamColor(team);
    _arrowIcon?.color = brightColor;

    // 4. 添加发光边框效果
    final glowPaint = ui.Paint()
      ..color = const ui.Color(0x50FFFFFF)
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = 3.0;

    add(
      CircleComponent(
        radius: radius + 2,
        paint: glowPaint,
        anchor: Anchor.center,
      ),
    );

    // 5. 添加呼吸动画效果
    _breathingTimer = TimerComponent(
      period: 1.0,
      repeat: true,
      onTick: () {
        // 创建缩放动画效果
        final currentScale = scale.x;
        final targetScale = currentScale == 1.0 ? 1.1 : 1.0;
        scale = Vector2.all(targetScale);
      },
    );
    add(_breathingTimer!);
  }

  void _setupAIPlayerVisuals() {
    // AI玩家保持原始外观，但添加"AI"标识
    _playerLabel = TextComponent(
      text: 'AI',
      textRenderer: TextPaint(
        style: const TextStyle(
          fontSize: 8,
          fontWeight: FontWeight.bold,
          color: ui.Color(0xFFFFFFFF), // 白色
        ),
      ),
      anchor: Anchor.center,
      position: Vector2.zero(),
    );
    add(_playerLabel!);
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

    if (isEliminated) return;

    // 更新投球冷却时间
    _lastThrowTime += dt;

    // 更新玩家移动
    if (controllerType == PlayerControllerType.human) {
      _updateMovement(dt);
    }

    // 更新箭头方向
    if (_velocity.length > 1.0) {
      _arrowIcon?.updateDirection(_velocity.normalized());
    }
  }

  void _updateMovement(double dt) {
    // 平滑移动到目标方向
    _velocity = _velocity * 0.9 + _targetDirection * movementSpeed * 0.1;

    if (_velocity.length > 1.0) {
      final newPosition = position + _velocity * dt;

      // 边界检查和玩家重叠检查
      if (_isValidPlayerPosition(newPosition) &&
          !_wouldOverlapWithOtherPlayers(newPosition)) {
        position = newPosition;
      }
    }
  }

  bool _isValidPlayerPosition(Vector2 newPosition) {
    final game = findGame();
    if (game == null) return false;

    // 检查是否在对应的队伍区域内
    final isRedTeam = team == Team.red;

    if (isRedTeam) {
      return FieldConfig.isInRedTeamArea(newPosition, game.size);
    } else {
      return FieldConfig.isInBlueTeamArea(newPosition, game.size);
    }
  }

  bool _wouldOverlapWithOtherPlayers(Vector2 newPosition) {
    final game = findGame();
    if (game == null) return false;

    // 检查与其他玩家的距离
    for (final other in game.children.whereType<PlayerComponent>()) {
      if (other == this || other.isEliminated) continue;

      final distance = newPosition.distanceTo(other.position);
      final minDistance = radius + other.radius + 2.0; // 额外2像素间隔

      if (distance < minDistance) {
        return true; // 会重叠
      }
    }

    return false; // 不会重叠
  }

  void _handleMovementInput(Vector2 direction) {
    if (!isEliminated) {
      _targetDirection = direction;
    }
  }

  void _handleThrowInput(Vector2 direction) {
    if (isEliminated) return;

    // 检查冷却时间
    if (!canThrow) {
      return; // 还在冷却中，不能投球
    }

    final game = findGame();
    if (game != null && game is HasPlayerThrowRequest) {
      // 计算投掷目标位置
      final throwDistance = 200.0;
      final targetPosition = absoluteCenter + direction * throwDistance;

      (game as HasPlayerThrowRequest).requestThrowFromPlayer(
        this,
        targetPosition,
      );

      // 重置冷却时间
      resetThrowCooldown();
    }
  }

  void eliminate() {
    if (isEliminated) return;
    isEliminated = true;
    // 停止控制器
    _aiController?.removeFromParent();
    _inputController?.removeFromParent();
    // 清理视觉组件
    _arrowIcon?.removeFromParent();
    _crownIcon?.removeFromParent();
    _playerLabel?.removeFromParent();
    _breathingTimer?.removeFromParent();
    removeFromParent();
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
