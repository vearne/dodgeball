import 'dart:ui' as ui;
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'mission_map.dart';
import 'ball_component.dart';
import 'package:flutter/material.dart';

/// 障碍物组件基类
abstract class ObstacleComponent extends PositionComponent
    with CollisionCallbacks, HasGameReference {
  ObstacleComponent({required Vector2 position, required Vector2 size})
    : super(position: position, size: size, anchor: Anchor.topLeft);

  /// 处理球与障碍物的碰撞
  void handleBallCollision(BallComponent ball);
}

/// 原子砖块组件：30px*30px 的基本砖块单元
/// 继承 ObstacleComponent 以便与现有的碰撞检测系统兼容
class AtomicBrickComponent extends ObstacleComponent {
  static const double atomicSize = 30.0; // 原子砖块大小
  Sprite? _brickSprite; // 砖块图片精灵

  AtomicBrickComponent({required Vector2 position})
    : super(position: position, size: Vector2.all(atomicSize));

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // 加载砖块图片
    try {
      _brickSprite = await Sprite.load('wall_30_30.png');
    } catch (e) {
      print('警告：无法加载砖块图片，将使用默认绘制: $e');
    }

    // 添加矩形碰撞箱
    add(RectangleHitbox());
  }

  @override
  void render(ui.Canvas canvas) {
    super.render(canvas);

    if (_brickSprite != null) {
      // 使用图片渲染
      _brickSprite!.render(canvas, size: size);
    } else {
      // 降级方案：使用代码绘制
      // 砖块颜色
      final brickPaint = ui.Paint()
        ..color =
            const ui.Color(0xFFB22222) // 红砖色
        ..style = ui.PaintingStyle.fill;

      // 砖缝颜色
      final mortarPaint = ui.Paint()
        ..color =
            const ui.Color(0xFF8B4513) // 深棕色（砖缝）
        ..style = ui.PaintingStyle.stroke
        ..strokeWidth = 2.0;

      // 绘制砖块本体
      canvas.drawRect(ui.Rect.fromLTWH(0, 0, size.x, size.y), brickPaint);

      // 绘制砖块边框（砖缝）
      canvas.drawRect(ui.Rect.fromLTWH(0, 0, size.x, size.y), mortarPaint);

      // 绘制砖块纹理（横向分割线）
      final texturePaint = ui.Paint()
        ..color =
            const ui.Color(0xFF8B0000) // 深红色纹理
        ..style = ui.PaintingStyle.stroke
        ..strokeWidth = 1.0;

      canvas.drawLine(
        ui.Offset(0, size.y / 2),
        ui.Offset(size.x, size.y / 2),
        texturePaint,
      );
    }
  }

  @override
  void handleBallCollision(BallComponent ball) {
    // 球体消失
    ball.removeFromParent();
    // 原子砖块消失
    removeFromParent();
  }

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    super.onCollisionStart(intersectionPoints, other);

    // 如果是球体碰撞
    if (other is BallComponent) {
      handleBallCollision(other);
    }
  }
}

/// 砖墙组件：由多个原子砖块组成的复合障碍物
class BrickWallComponent extends PositionComponent with HasGameReference {
  final List<AtomicBrickComponent> _atomicBricks = [];

  BrickWallComponent({required Vector2 position, required Vector2 size})
    : super(position: position, size: size, anchor: Anchor.topLeft);

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // 计算需要多少个原子砖块来填充这个区域
    final numColumns = (size.x / AtomicBrickComponent.atomicSize).ceil();
    final numRows = (size.y / AtomicBrickComponent.atomicSize).ceil();

    // 创建原子砖块网格
    for (int row = 0; row < numRows; row++) {
      for (int col = 0; col < numColumns; col++) {
        final brickX = col * AtomicBrickComponent.atomicSize;
        final brickY = row * AtomicBrickComponent.atomicSize;

        // 确保砖块不超出定义的大小
        if (brickX < size.x && brickY < size.y) {
          final atomicBrick = AtomicBrickComponent(
            position: position + Vector2(brickX, brickY),
          );
          _atomicBricks.add(atomicBrick);
          await add(atomicBrick);
        }
      }
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    // 移除已经被销毁的原子砖块引用
    _atomicBricks.removeWhere((brick) => brick.parent == null);

    // 如果所有原子砖块都被销毁，移除整个砖墙
    if (_atomicBricks.isEmpty) {
      removeFromParent();
    }
  }
}

/// 木墙组件（已废弃，保留以兼容旧地图）
/// 现在与砖墙行为完全一致
@Deprecated('使用 BrickWallComponent 代替')
class WoodWallComponent extends BrickWallComponent {
  WoodWallComponent({required Vector2 position, required Vector2 size})
    : super(position: position, size: size);
}

/// 岩石组件：被球击中后反弹，不消失
class RockComponent extends ObstacleComponent {
  Sprite? _rockSprite; // 岩石图片精灵

  RockComponent({required Vector2 position, required Vector2 size})
    : super(position: position, size: size);

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // 加载岩石图片
    try {
      _rockSprite = await Sprite.load('stone_30_30.png');
    } catch (e) {
      print('警告：无法加载岩石图片，将使用默认绘制: $e');
    }

    // 添加矩形碰撞箱
    add(RectangleHitbox());
  }

  @override
  void render(ui.Canvas canvas) {
    super.render(canvas);

    if (_rockSprite != null) {
      // 使用图片渲染（平铺方式填充整个区域）
      final tileSize = 30.0;
      final tilesX = (size.x / tileSize).ceil();
      final tilesY = (size.y / tileSize).ceil();

      for (int row = 0; row < tilesY; row++) {
        for (int col = 0; col < tilesX; col++) {
          final offsetX = col * tileSize;
          final offsetY = row * tileSize;

          // 计算需要绘制的部分大小
          final drawWidth = (offsetX + tileSize > size.x) ? size.x - offsetX : tileSize;
          final drawHeight = (offsetY + tileSize > size.y) ? size.y - offsetY : tileSize;

          canvas.save();
          canvas.translate(offsetX, offsetY);

          // 裁剪以防止超出边界
          canvas.clipRect(ui.Rect.fromLTWH(0, 0, drawWidth, drawHeight));

          _rockSprite!.render(canvas, size: Vector2(tileSize, tileSize));

          canvas.restore();
        }
      }
    } else {
      // 降级方案：使用代码绘制
      // 绘制岩石：灰色矩形
      final paint = ui.Paint()
        ..color =
            const ui.Color(0xFF696969) // 灰色
        ..style = ui.PaintingStyle.fill;

      canvas.drawRect(ui.Rect.fromLTWH(0, 0, size.x, size.y), paint);

      // 绘制边框
      final borderPaint = ui.Paint()
        ..color =
            const ui.Color(0xFF404040) // 深灰色边框
        ..style = ui.PaintingStyle.stroke
        ..strokeWidth = 2.0;

      canvas.drawRect(ui.Rect.fromLTWH(0, 0, size.x, size.y), borderPaint);

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
  }

  @override
  void handleBallCollision(BallComponent ball) {
    // 岩石反弹：计算反弹方向
    final ballCenter = ball.position;
    final obstacleRect = Rect.fromLTWH(position.x, position.y, size.x, size.y);

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
      distToBottom,
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
/// 注意：BrickWallComponent 不再是 ObstacleComponent，而是一个容器组件
PositionComponent createObstacleFromData(Obstacle obstacle) {
  final position = Vector2(obstacle.x, obstacle.y);
  final size = Vector2(obstacle.width, obstacle.height);

  switch (obstacle.type) {
    case ObstacleType.brickWall:
      return BrickWallComponent(position: position, size: size);
    case ObstacleType.woodWall: // 兼容旧地图
      return BrickWallComponent(position: position, size: size);
    case ObstacleType.rock:
      return RockComponent(position: position, size: size);
  }
}
