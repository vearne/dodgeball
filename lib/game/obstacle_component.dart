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

/// 砖墙组件：被球击中后逐渐损坏，最终消失
class BrickWallComponent extends ObstacleComponent {
  // 耐久度系统
  static const int maxDurability = 3; // 最大耐久度（需要3次击中才能摧毁）
  int currentDurability = maxDurability; // 当前耐久度
  
  // 砖块网格系统（用于块状损坏效果）
  static const int bricksPerRow = 4; // 每行4个砖块
  static const int bricksPerColumn = 4; // 每列4个砖块
  final List<bool> _brickGrid = List.filled(bricksPerRow * bricksPerColumn, true); // true=存在，false=已损坏
  
  BrickWallComponent({
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

    // 绘制砖块网格（坦克大战风格）
    _drawBrickGrid(canvas);

    // 绘制耐久度指示器
    _drawDurabilityIndicator(canvas);
  }

  /// 绘制砖块网格（坦克大战风格）
  void _drawBrickGrid(ui.Canvas canvas) {
    final brickWidth = size.x / bricksPerRow;
    final brickHeight = size.y / bricksPerColumn;

    // 砖块颜色
    final brickPaint = ui.Paint()
      ..color = const ui.Color(0xFFB22222) // 红砖色
      ..style = ui.PaintingStyle.fill;

    // 砖缝颜色
    final mortarPaint = ui.Paint()
      ..color = const ui.Color(0xFF8B4513) // 深棕色（砖缝）
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // 绘制每个砖块
    for (int row = 0; row < bricksPerColumn; row++) {
      for (int col = 0; col < bricksPerRow; col++) {
        final index = row * bricksPerRow + col;
        
        // 如果这个砖块还存在，就绘制它
        if (_brickGrid[index]) {
          final x = col * brickWidth;
          final y = row * brickHeight;
          final rect = ui.Rect.fromLTWH(x, y, brickWidth, brickHeight);

          // 绘制砖块本体
          canvas.drawRect(rect, brickPaint);

          // 绘制砖块边框（砖缝）
          canvas.drawRect(rect, mortarPaint);
        }
      }
    }
  }

  /// 绘制耐久度指示器（小圆点）
  void _drawDurabilityIndicator(ui.Canvas canvas) {
    final indicatorPaint = ui.Paint()
      ..style = ui.PaintingStyle.fill;

    final indicatorRadius = 3.0;
    final spacing = 8.0;
    final startX = (size.x - (maxDurability * indicatorRadius * 2 + (maxDurability - 1) * spacing)) / 2;
    final y = size.y - 8.0;

    for (int i = 0; i < maxDurability; i++) {
      indicatorPaint.color = i < currentDurability
          ? const ui.Color(0xFF00FF00) // 绿色：剩余耐久度
          : const ui.Color(0xFF666666); // 灰色：已损失耐久度

      final x = startX + i * (indicatorRadius * 2 + spacing) + indicatorRadius;
      canvas.drawCircle(ui.Offset(x, y), indicatorRadius, indicatorPaint);
    }
  }

  @override
  void handleBallCollision(BallComponent ball) {
    // 减少耐久度
    currentDurability--;

    // 球消失
    ball.removeFromParent();

    // 根据击中位置和当前耐久度，损坏一些砖块
    _damageBricks(ball.position);

    // 检查是否完全损坏
    if (currentDurability <= 0) {
      // 砖墙被完全摧毁
      removeFromParent();
    }
  }

  /// 损坏砖块（坦克大战风格）
  void _damageBricks(Vector2 hitPosition) {
    // 计算击中点相对于障碍物的位置
    final relativeX = hitPosition.x - position.x;
    final relativeY = hitPosition.y - position.y;

    // 计算击中的砖块索引
    final brickWidth = size.x / bricksPerRow;
    final brickHeight = size.y / bricksPerColumn;
    
    final hitCol = (relativeX / brickWidth).floor().clamp(0, bricksPerRow - 1);
    final hitRow = (relativeY / brickHeight).floor().clamp(0, bricksPerColumn - 1);

    // 根据耐久度损失，损坏不同数量的砖块
    final bricksToRemove = maxDurability - currentDurability + 1;
    
    // 获取击中点附近的砖块
    final bricksToRemoveList = <int>[];
    
    // 从击中点开始，向外扩散移除砖块
    for (int dr = -1; dr <= 1; dr++) {
      for (int dc = -1; dc <= 1; dc++) {
        final r = hitRow + dr;
        final c = hitCol + dc;
        if (r >= 0 && r < bricksPerColumn && c >= 0 && c < bricksPerRow) {
          final index = r * bricksPerRow + c;
          if (_brickGrid[index]) {
            bricksToRemoveList.add(index);
          }
        }
      }
    }

    // 随机选择要移除的砖块
    if (bricksToRemoveList.isNotEmpty) {
      bricksToRemoveList.shuffle();
      final numToRemove = (bricksToRemove * 2).clamp(0, bricksToRemoveList.length);
      for (int i = 0; i < numToRemove; i++) {
        _brickGrid[bricksToRemoveList[i]] = false;
      }
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

/// 木墙组件（已废弃，保留以兼容旧地图）
@Deprecated('使用 BrickWallComponent 代替')
class WoodWallComponent extends BrickWallComponent {
  WoodWallComponent({
    required Vector2 position,
    required Vector2 size,
  }) : super(position: position, size: size);
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
    case ObstacleType.brickWall:
      return BrickWallComponent(position: position, size: size);
    case ObstacleType.woodWall: // 兼容旧地图
      return BrickWallComponent(position: position, size: size);
    case ObstacleType.rock:
      return RockComponent(position: position, size: size);
  }
}

