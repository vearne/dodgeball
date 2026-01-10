import 'dart:ui' as ui;
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import 'arrow_component.dart';
import 'field_config.dart';
import 'obstacle_component.dart';
import 'player_component.dart';
import 'team.dart';

class BallComponent extends BodyComponent with ContactCallbacks {
  BallComponent({
    required this.team,
    required this.ownerPlayerId,
    required Vector2 position,
    required Vector2 initialVelocity,
    required this.bounceCount,
    double radius = 8,
    this.onHitPlayer,
  }) : ballRadius = radius,
       _initialVelocity = initialVelocity,
       super(
         fixtureDefs: [
           FixtureDef(
             CircleShape()..radius = radius, // 直接使用像素单位
             restitution: 0.8, // 弹性系数，与原有逻辑一致
             friction: 0.3,
             density: 1.0,
           ),
         ],
         bodyDef: BodyDef(
           position: position, // 直接使用像素坐标
           linearVelocity: initialVelocity, // 直接使用像素单位
           type: BodyType.dynamic,
           linearDamping: 0.0, // 无阻尼，保持恒定速度
           angularDamping: 0.0,
         ),
       ) {
    remainingLabel = TextComponent(
      text: '$bounceCount',
      anchor: Anchor.center,
      scale: Vector2.all(0.5), // 调小字体大小
      priority: 1,
    );
  }

  final Team team;
  final int ownerPlayerId; // 发球者ID，用于计分
  int bounceCount; // 初始为 1..5 的随机数
  late final TextComponent remainingLabel;
  bool collidedOnce = false; // 首次与墙/玩家发生碰撞后置为 true
  final void Function(BallComponent ball, PlayerComponent hitPlayer)?
  onHitPlayer;
  final double ballRadius; // 球的半径，用于碰撞检测
  bool _hasHitPlayer = false; // 防止重复扣血：记录是否已经击中玩家
  Vector2? _lastPosition; // 上一次的位置，用于检测墙壁碰撞
  bool _hasHitWallThisFrame = false; // 防止同一帧重复触发墙壁碰撞
  final Vector2 _initialVelocity; // 保存初始速度
  double _targetSpeed = 300.0; // 目标速度，从初始速度获取

  // 调试模式：显示碰撞检测范围
  static bool showDebugCollision = false;

  // 获取球的中心位置（像素坐标）
  Vector2 get center => body.position;

  // 兼容旧代码：获取速度（像素坐标）
  Vector2 get velocity => body.linearVelocity;

  // 兼容旧代码：获取位置（像素坐标）
  Vector2 get position => body.position;

  // 公共访问器：障碍物组件需要检查和设置此标记
  bool hasHitObstacle = false;

  late SpriteComponent _spriteComponent;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // 设置 body.userData 为 this，使 WorldContactListener 能够调用此组件的碰撞回调
    body.userData = this;

    // 设置碰撞回调
    _setupCollisionCallbacks();

    // 从初始速度获取目标速度
    _targetSpeed = _initialVelocity.length;
    if (_targetSpeed < 0.01) {
      _targetSpeed = 300.0; // 默认速度
    }

    // 调试信息：打印目标速度
    print(
      '球加载: 初始速度=${_initialVelocity.length}, 目标速度=$_targetSpeed, 初始速度向量=$_initialVelocity',
    );

    // 初始化位置跟踪
    _lastUpdatePosition = body.position.clone();

    // 根据队伍加载相应的球图片
    final spritePath = _getSpritePathForTeam(team);
    final sprite = await Sprite.load(spritePath);

    // 添加 sprite 组件用于渲染
    _spriteComponent = SpriteComponent(
      sprite: sprite,
      size: Vector2.all(ballRadius * 2),
      anchor: Anchor.center,
    );
    add(_spriteComponent);

    // 添加剩余弹跳次数标签
    add(remainingLabel);
  }

  /// 设置碰撞回调
  void _setupCollisionCallbacks() {
    onBeginContact = (other, contact) {
      // 处理与玩家的碰撞
      if (other is PlayerComponent) {
        handlePlayerCollision(other as PlayerComponent);
      }
      // 处理与障碍物的碰撞
      else if (other is ObstacleComponent) {
        other.handleBallCollision(this);
      }
    };

    onEndContact = (other, contact) {
      // 碰撞结束时的处理（如果需要）
    };
  }

  Vector2? _lastUpdatePosition; // 上一次update时的位置，用于计算移动距离
  int _updateCount = 0; // 更新计数

  @override
  void update(double dt) {
    // 先保存当前速度方向，因为 super.update 可能会被物理引擎限制速度
    final velocityBeforeUpdate = body.linearVelocity;
    final directionBeforeUpdate = velocityBeforeUpdate.length > 0.01
        ? velocityBeforeUpdate.normalized()
        : null;

    super.update(dt);

    // 重置墙壁碰撞标记
    _hasHitWallThisFrame = false;

    // 同步 sprite 位置和旋转到物理体
    _spriteComponent.position = Vector2.zero();
    _spriteComponent.angle = body.angle;

    // 保持恒定速度（忽略碰撞后的速度损失，只使用弹性系数）
    // 注意：Forge2D 在 super.update 中会限制速度和移动距离
    // 我们需要在物理更新后强制恢复目标速度，并手动调整位置以绕过移动距离限制
    final currentSpeed = body.linearVelocity.length;
    final currentPos = body.position;

    // 如果有目标速度，无条件强制设置（无论当前速度是多少）
    // 这是为了绕过 Forge2D 的速度限制
    if (_targetSpeed > 0.01) {
      Vector2 direction;
      if (directionBeforeUpdate != null) {
        // 优先使用之前保存的方向
        direction = directionBeforeUpdate;
      } else if (currentSpeed > 0.01) {
        // 如果没有保存的方向，使用当前方向
        direction = body.linearVelocity.normalized();
      } else {
        // 如果完全没有方向，跳过（球可能已经停止）
        return; // 提前返回，不设置速度
      }

      // 强制设置目标速度（绕过 Forge2D 的速度限制）
      body.linearVelocity = direction * _targetSpeed;

      // 计算预期移动距离
      final expectedMovement = direction * _targetSpeed * dt;
      final actualMovement = currentPos - (_lastUpdatePosition ?? currentPos);
      final movementDiff = expectedMovement.length - actualMovement.length;

      // 如果实际移动距离小于预期（被 Forge2D 限制了），手动调整位置
      if (movementDiff > 0.1 && _lastUpdatePosition != null) {
        // 手动移动球到预期位置，绕过 Forge2D 的移动距离限制
        final expectedPos = _lastUpdatePosition! + expectedMovement;
        body.setTransform(expectedPos, body.angle);
        print(
          '手动调整位置: 实际移动=${actualMovement.length.toStringAsFixed(2)}, 预期移动=${expectedMovement.length.toStringAsFixed(2)}, 调整=${movementDiff.toStringAsFixed(2)}',
        );
      }

      // 调试信息：如果速度被修改，打印
      if ((currentSpeed - _targetSpeed).abs() > 0.1) {
        print('球速度被修改: $currentSpeed -> $_targetSpeed (目标速度)');
      }
    } else if (currentSpeed > 0 && currentSpeed <= 0.01) {
      // 调试信息：速度过小被忽略
      print('球速度过小被忽略: $currentSpeed');
    }

    // 调试信息：每10帧打印一次移动信息
    _updateCount++;
    if (_lastUpdatePosition != null && _updateCount % 10 == 0) {
      final currentPos = body.position;
      final distance = (currentPos - _lastUpdatePosition!).length;
      final expectedDistance = currentSpeed * dt * 10; // 10帧的预期距离
      print(
        '球移动调试 (每10帧): dt=$dt, 速度=$currentSpeed, 实际移动距离=$distance, 预期移动距离=$expectedDistance, 位置=$currentPos',
      );
    }
    _lastUpdatePosition = body.position.clone();

    // 检测墙壁碰撞
    _checkWallCollision();

    // 检查碰撞次数
    if (bounceCount <= 0) {
      removeFromParent();
    }

    // 更新上一次的位置
    _lastPosition = body.position.clone();
  }

  static String _getSpritePathForTeam(Team team) {
    switch (team) {
      case Team.red:
        return 'red_ball.png'; // 红队：红色球图片
      case Team.blue:
        return 'blue_ball.png'; // 蓝队：蓝色球图片
    }
  }

  /// 处理与玩家的碰撞
  void handlePlayerCollision(PlayerComponent player) {
    // 防止重复扣血：如果已经击中过玩家，直接返回
    if (_hasHitPlayer) {
      return;
    }

    // 检查玩家是否已经被淘汰或正在被移除
    if (player.isEliminated || player.team == team) {
      return;
    }

    // 标记已经击中玩家，防止重复扣血
    _hasHitPlayer = true;

    // 统一处理：玩家受到伤害（减少生命值）
    player.takeDamage();

    hitPlayerAndContinue();
    onHitPlayer?.call(this, player);
  }

  void reflectOnHorizontalWall() {
    collidedOnce = true;
    // Forge2D 会自动处理物理反弹，我们只需要减少计数
    _decreaseAndCheck();
  }

  void reflectOnVerticalWall() {
    collidedOnce = true;
    // Forge2D 会自动处理物理反弹，我们只需要减少计数
    _decreaseAndCheck();
  }

  void hitPlayerAndContinue() {
    // 命中玩家后：视作有效碰撞并让球立即消失
    collidedOnce = true;
    removeFromParent();
  }

  void _decreaseAndCheck() {
    bounceCount -= 1;
    remainingLabel.text = '$bounceCount';
    if (bounceCount <= 0) {
      removeFromParent();
    }
  }

  /// 检测墙壁碰撞
  void _checkWallCollision() {
    // 如果已经在这一帧处理过墙壁碰撞，跳过
    if (_hasHitWallThisFrame) return;

    final game = findGame();
    if (game == null) return;

    final gameSize = game.size;
    final wallThickness = FieldConfig.wallThickness;
    final currentPos = body.position;
    final velocity = body.linearVelocity;

    // 如果速度太小，不检测碰撞
    if (velocity.length < 0.01) return;

    // 检测左边界（垂直墙壁）
    // 球已经越过或接触到左边界，且速度向左
    if (currentPos.x - ballRadius <= wallThickness && velocity.x < 0) {
      // 检查上一次是否在边界外（避免重复触发）
      if (_lastPosition == null ||
          _lastPosition!.x - ballRadius > wallThickness - 5) {
        reflectOnVerticalWall();
        _hasHitWallThisFrame = true;
        return;
      }
    }

    // 检测右边界（垂直墙壁）
    // 球已经越过或接触到右边界，且速度向右
    if (currentPos.x + ballRadius >= gameSize.x - wallThickness &&
        velocity.x > 0) {
      // 检查上一次是否在边界内（避免重复触发）
      if (_lastPosition == null ||
          _lastPosition!.x + ballRadius < gameSize.x - wallThickness + 5) {
        reflectOnVerticalWall();
        _hasHitWallThisFrame = true;
        return;
      }
    }

    // 检测上边界（水平墙壁）
    // 球已经越过或接触到上边界，且速度向上
    if (currentPos.y - ballRadius <= wallThickness && velocity.y < 0) {
      // 检查上一次是否在边界外（避免重复触发）
      if (_lastPosition == null ||
          _lastPosition!.y - ballRadius > wallThickness - 5) {
        reflectOnHorizontalWall();
        _hasHitWallThisFrame = true;
        return;
      }
    }

    // 检测下边界（水平墙壁）
    // 球已经越过或接触到下边界，且速度向下
    if (currentPos.y + ballRadius >= gameSize.y - wallThickness &&
        velocity.y > 0) {
      // 检查上一次是否在边界内（避免重复触发）
      if (_lastPosition == null ||
          _lastPosition!.y + ballRadius < gameSize.y - wallThickness + 5) {
        reflectOnHorizontalWall();
        _hasHitWallThisFrame = true;
        return;
      }
    }
  }

  @override
  void render(ui.Canvas canvas) {
    super.render(canvas);

    // 调试模式：显示碰撞检测范围
    if (showDebugCollision) {
      final paint = ui.Paint()
        ..color = const ui.Color.fromARGB(100, 255, 0, 0)
        ..style = ui.PaintingStyle.stroke
        ..strokeWidth = 1.0;

      // 在原点绘制圆（因为 BodyComponent 的渲染已经处理了位置转换）
      canvas.drawCircle(ui.Offset.zero, ballRadius, paint);
    }
  }
}
