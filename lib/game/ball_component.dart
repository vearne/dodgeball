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

  @override
  void update(double dt) {
    super.update(dt);

    // 重置墙壁碰撞标记
    _hasHitWallThisFrame = false;

    // 同步 sprite 位置和旋转到物理体
    _spriteComponent.position = Vector2.zero();
    _spriteComponent.angle = body.angle;

    // 保持恒定速度（忽略碰撞后的速度损失，只使用弹性系数）
    final currentSpeed = body.linearVelocity.length;
    if (currentSpeed > 0.01) {
      final targetSpeed = 400.0; // 直接使用像素单位
      if (currentSpeed != targetSpeed) {
        body.linearVelocity = body.linearVelocity.normalized() * targetSpeed;
      }
    }

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
      if (_lastPosition == null || _lastPosition!.x - ballRadius > wallThickness - 5) {
        reflectOnVerticalWall();
        _hasHitWallThisFrame = true;
        return;
      }
    }

    // 检测右边界（垂直墙壁）
    // 球已经越过或接触到右边界，且速度向右
    if (currentPos.x + ballRadius >= gameSize.x - wallThickness && velocity.x > 0) {
      // 检查上一次是否在边界内（避免重复触发）
      if (_lastPosition == null || _lastPosition!.x + ballRadius < gameSize.x - wallThickness + 5) {
        reflectOnVerticalWall();
        _hasHitWallThisFrame = true;
        return;
      }
    }

    // 检测上边界（水平墙壁）
    // 球已经越过或接触到上边界，且速度向上
    if (currentPos.y - ballRadius <= wallThickness && velocity.y < 0) {
      // 检查上一次是否在边界外（避免重复触发）
      if (_lastPosition == null || _lastPosition!.y - ballRadius > wallThickness - 5) {
        reflectOnHorizontalWall();
        _hasHitWallThisFrame = true;
        return;
      }
    }

    // 检测下边界（水平墙壁）
    // 球已经越过或接触到下边界，且速度向下
    if (currentPos.y + ballRadius >= gameSize.y - wallThickness && velocity.y > 0) {
      // 检查上一次是否在边界内（避免重复触发）
      if (_lastPosition == null || _lastPosition!.y + ballRadius < gameSize.y - wallThickness + 5) {
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
