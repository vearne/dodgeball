import 'dart:ui' as ui;
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'mission_map.dart';
import 'ball_component.dart';
import 'package:flutter/material.dart';

/// 障碍物组件基类
abstract class ObstacleComponent extends PositionComponent
    with CollisionCallbacks, HasGameReference {
  ObstacleComponent({
    required Vector2 position,
    required Vector2 size,
  }) : super(
          position: position,
          size: size,
          anchor: Anchor.topLeft,
        );

  /// 处理球与障碍物的碰撞
  void handleBallCollision(BallComponent ball);
}

/// 木墙组件：被球击中后消失，球也消失
class WoodWallComponent extends ObstacleComponent {
  WoodWallComponent({
    required Vector2 position,
    required Vector2 size,
  }) : super(position: position, size: size);

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // 添加矩形碰撞箱
    add(RectangleHitbox());

    // 绘制木墙外观
    // 这里使用简单的矩形绘制，后续可以添加纹理
  }

  @override
  void render(ui.Canvas canvas) {
    super.render(canvas);

    // 绘制木墙：棕色矩形
    final paint = ui.Paint()
      ..color = const ui.Color(0xFF8B4513) // 棕色
      ..style = ui.PaintingStyle.fill;

    canvas.drawRect(
      ui.Rect.fromLTWH(0, 0, size.x, size.y),
      paint,
    );

    // 绘制边框
    final borderPaint = ui.Paint()
      ..color = const ui.Color(0xFF654321) // 深棕色边框
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawRect(
      ui.Rect.fromLTWH(0, 0, size.x, size.y),
      borderPaint,
    );

    // 绘制木纹效果（简单的线条）
    final woodGrainPaint = ui.Paint()
      ..color = const ui.Color(0xFF654321)
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (int i = 1; i < 5; i++) {
      final y = size.y * i / 5;
      canvas.drawLine(
        ui.Offset(0, y),
        ui.Offset(size.x, y),
        woodGrainPaint,
      );
    }
  }

  @override
  void handleBallCollision(BallComponent ball) {
    // 木墙被击中后，木墙和球都消失
    removeFromParent();
    ball.removeFromParent();
  }

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    super.onCollisionStart(intersectionPoints, other);

    if (other is BallComponent) {
      handleBallCollision(other);
    }
  }
}

/// 岩石组件：被球击中后反弹，不消失
class RockComponent extends ObstacleComponent {
  RockComponent({
    required Vector2 position,
    required Vector2 size,
  }) : super(position: position, size: size);

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // 添加矩形碰撞箱
    add(RectangleHitbox());
  }

  @override
  void render(ui.Canvas canvas) {
    super.render(canvas);

    // 绘制岩石：灰色矩形
    final paint = ui.Paint()
      ..color = const ui.Color(0xFF696969) // 灰色
      ..style = ui.PaintingStyle.fill;

    canvas.drawRect(
      ui.Rect.fromLTWH(0, 0, size.x, size.y),
      paint,
    );

    // 绘制边框
    final borderPaint = ui.Paint()
      ..color = const ui.Color(0xFF404040) // 深灰色边框
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawRect(
      ui.Rect.fromLTWH(0, 0, size.x, size.y),
      borderPaint,
    );

    // 绘制岩石纹理（随机点状）
    final texturePaint = ui.Paint()
      ..color = const ui.Color(0xFF505050)
      ..style = ui.PaintingStyle.fill;

    // 简单的点状纹理
    for (int i = 0; i < 10; i++) {
      final x = (i * size.x / 10) % size.x;
      final y = (i * size.y / 10) % size.y;
      canvas.drawCircle(ui.Offset(x, y), 2.0, texturePaint);
    }
  }

  @override
  void handleBallCollision(BallComponent ball) {
    // 岩石反弹：计算反弹方向
    final ballCenter = ball.position;
    final obstacleRect = Rect.fromLTWH(
      position.x,
      position.y,
      size.x,
      size.y,
    );

    // 计算球中心到障碍物各边的距离
    final distToLeft = (ballCenter.x - obstacleRect.left).abs();
    final distToRight = (ballCenter.x - obstacleRect.right).abs();
    final distToTop = (ballCenter.y - obstacleRect.top).abs();
    final distToBottom = (ballCenter.y - obstacleRect.bottom).abs();

    // 找到最近的边
    final minDist = [
      distToLeft,
      distToRight,
      distToTop,
      distToBottom
    ].reduce((a, b) => a < b ? a : b);

    // 根据最近的边决定反弹方向
    if (minDist == distToLeft || minDist == distToRight) {
      // 左右碰撞：水平反弹
      ball.reflectOnVerticalWall();
    } else {
      // 上下碰撞：垂直反弹
      ball.reflectOnHorizontalWall();
    }

    // 调整球的位置，防止穿透
    if (ballCenter.x < obstacleRect.left) {
      ball.position.x = obstacleRect.left - ball.ballRadius;
    } else if (ballCenter.x > obstacleRect.right) {
      ball.position.x = obstacleRect.right + ball.ballRadius;
    }

    if (ballCenter.y < obstacleRect.top) {
      ball.position.y = obstacleRect.top - ball.ballRadius;
    } else if (ballCenter.y > obstacleRect.bottom) {
      ball.position.y = obstacleRect.bottom + ball.ballRadius;
    }
  }

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    super.onCollisionStart(intersectionPoints, other);

    if (other is BallComponent) {
      handleBallCollision(other);
    }
  }
}

/// 从障碍物数据创建障碍物组件
ObstacleComponent createObstacleFromData(Obstacle obstacle) {
  final position = Vector2(obstacle.x, obstacle.y);
  final size = Vector2(obstacle.width, obstacle.height);

  switch (obstacle.type) {
    case ObstacleType.woodWall:
      return WoodWallComponent(position: position, size: size);
    case ObstacleType.rock:
      return RockComponent(position: position, size: size);
  }
}

