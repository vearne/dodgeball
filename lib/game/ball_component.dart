import 'dart:ui' as ui;
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import 'arrow_component.dart';
import 'obstacle_component.dart';
import 'player_component.dart';
import 'team.dart';

class BallComponent extends SpriteComponent
    with CollisionCallbacks, HasGameReference {
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
         position: position - Vector2.all(radius), // 将中心位置转换为topLeft位置
         size: Vector2.all(radius * 2), // sprite需要size而不是radius
         anchor: Anchor.topLeft,
       ) {
    velocity = initialVelocity;
    remainingLabel = TextComponent(
      text: '$bounceCount',
      anchor: Anchor.center,
      position: Vector2(ballRadius, ballRadius), // 居中
      scale: Vector2.all(0.5), // 调小字体大小
      priority: 1,
    );
  }

  final Team team;
  final int ownerPlayerId; // 发球者ID，用于计分
  late Vector2 velocity;
  int bounceCount; // 初始为 1..5 的随机数
  late final TextComponent remainingLabel;
  bool collidedOnce = false; // 首次与墙/玩家发生碰撞后置为 true
  final void Function(BallComponent ball, PlayerComponent hitPlayer)?
  onHitPlayer;
  final double ballRadius; // 球的半径，用于碰撞检测
  bool _hasHitPlayer = false; // 防止重复扣血：记录是否已经击中玩家

  // 调试模式：显示碰撞检测范围
  static bool showDebugCollision = false;

  // 获取球的中心位置
  @override
  Vector2 get center => position + Vector2.all(ballRadius);

  // 公共访问器：障碍物组件需要检查和设置此标记
  bool hasHitObstacle = false;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // 根据队伍加载相应的球图片
    final spritePath = _getSpritePathForTeam(team);
    sprite = await Sprite.load(spritePath);

    // 添加圆形碰撞箱，使用ballRadius
    // 父组件anchor是topLeft，所以碰撞体中心应该在(ballRadius, ballRadius)位置
    add(
      CircleHitbox(
        radius: ballRadius,
        position: Vector2.all(ballRadius),
        anchor: Anchor.center,
      ),
    );
    add(remainingLabel);
  }

  static String _getSpritePathForTeam(Team team) {
    switch (team) {
      case Team.red:
        return 'red_ball.png'; // 红队：红色球图片
      case Team.blue:
        return 'blue_ball.png'; // 蓝队：蓝色球图片
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    // 使用多步物理更新提高精度
    _updatePhysicsWithSubsteps(dt);
  }

  /// 使用子步长进行物理更新，提高精度
  void _updatePhysicsWithSubsteps(double dt) {
    // 根据球的速度动态调整子步数
    final speed = velocity.length;
    int substeps = 10;

    if (speed > 400) {
      substeps = 50; // 极高速球使用50个子步
    } else if (speed > 300) {
      substeps = 20; // 高速球使用20个子步
    } else if (speed > 200) {
      substeps = 15; // 中速球使用15个子步
    } else if (speed > 100) {
      substeps = 10; // 低中速球使用10个子步
    }

    final subDt = dt / substeps;

    for (int i = 0; i < substeps; i++) {
      // 更新位置
      position += velocity * subDt;

      // 检查连续碰撞
      _checkContinuousCollisions(subDt);
    }
  }

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    super.onCollisionStart(intersectionPoints, other);

    // 检测与玩家组件的碰撞
    if (other is PlayerComponent) {
      _handlePlayerCollision(other);
    }
    // 保留与箭头组件的碰撞检测作为备用
    else if (other is ArrowComponent) {
      final parentComponent = other.parent;
      if (parentComponent is PlayerComponent) {
        final player = parentComponent;
        _handlePlayerCollision(player);
      }
    }
  }

  /// 处理与玩家的碰撞
  void _handlePlayerCollision(PlayerComponent player) {
    // 防止重复扣血：如果已经击中过玩家，直接返回
    if (_hasHitPlayer) {
      return;
    }

    // 检查玩家是否已经被淘汰或正在被移除
    if (player.isEliminated || player.team == team) {
      return;
    }

    // 验证碰撞的有效性
    if (_isValidPlayerCollision(player)) {
      // 标记已经击中玩家，防止重复扣血
      _hasHitPlayer = true;

      // 统一处理：玩家受到伤害（减少生命值）
      // 这样可以支持所有游戏模式（包括 DodgeballGame 和 MissionDodgeballGame）
      player.takeDamage();

      hitPlayerAndContinue();
      onHitPlayer?.call(this, player);
    }
  }

  /// 连续碰撞检测，防止高速球穿透
  void _checkContinuousCollisions(double dt) {
    final game = findGame();
    if (game == null) return;

    // 优先检查障碍物碰撞（因为障碍物会反弹球，玩家会消除球）
    for (final obstacle in game.children.whereType<ObstacleComponent>()) {
      if (_checkContinuousObstacleCollision(obstacle, dt)) {
        obstacle.handleBallCollision(this);
        return; // 只处理第一个碰撞
      }
    }

    // 检查所有玩家
    for (final player in game.children.whereType<PlayerComponent>()) {
      if (player.isEliminated || player.team == team) continue;

      // 使用连续碰撞检测
      if (_checkContinuousPlayerCollision(player, dt)) {
        _handlePlayerCollision(player);
        return; // 只处理第一个碰撞
      }
    }
  }

  /// 连续碰撞检测算法
  bool _checkContinuousPlayerCollision(PlayerComponent player, double dt) {
    // 计算球在这一帧内的移动轨迹（使用球心）
    final currentCenter = center;
    final startPos = currentCenter - velocity * dt;
    final endPos = currentCenter;

    // 如果球没有移动，使用静态碰撞检测
    final moveDistance = (endPos - startPos).length;
    if (moveDistance < 0.001) {
      // 静态碰撞检测：直接检查距离
      final distance = currentCenter.distanceTo(player.center);
      return distance <= (ballRadius + player.radius);
    }

    // 计算球轨迹与玩家碰撞体的最近距离
    final closestPoint = _getClosestPointOnLineToCircle(
      startPos,
      endPos,
      player.center,
      player.radius,
    );

    // 计算轨迹上最近点到玩家圆心的距离
    final distance = closestPoint.distanceTo(player.center);
    // 如果距离小于球半径+玩家半径，说明发生了碰撞
    final collisionDistance = ballRadius + player.radius;
    return distance <= collisionDistance;
  }

  /// 计算线段到圆心的最近点
  Vector2 _getClosestPointOnLineToCircle(
    Vector2 lineStart,
    Vector2 lineEnd,
    Vector2 circleCenter,
    double circleRadius,
  ) {
    final lineVector = lineEnd - lineStart;
    final lineLength = lineVector.length;

    if (lineLength < 0.001) return lineStart; // 线段太短

    final normalizedLine = lineVector / lineLength;
    final toCircle = circleCenter - lineStart;

    // 计算投影点
    final projection = toCircle.dot(normalizedLine);
    final clampedProjection = projection.clamp(0.0, lineLength);

    return lineStart + normalizedLine * clampedProjection;
  }

  /// 连续碰撞检测算法：球与障碍物
  bool _checkContinuousObstacleCollision(
    ObstacleComponent obstacle,
    double dt,
  ) {
    // 计算球在这一帧内的移动轨迹（使用球心）
    final currentCenter = center;
    final startPos = currentCenter - velocity * dt;
    final endPos = currentCenter;

    // 如果球没有移动，使用静态碰撞检测
    final moveDistance = (endPos - startPos).length;
    if (moveDistance < 0.001) {
      // 静态碰撞检测：检查球心到障碍物矩形的距离
      return _checkCircleRectCollision(currentCenter, obstacle);
    }

    // 创建扩展后的障碍物矩形（考虑球的半径）
    final obstacleRect = Rect.fromLTWH(
      obstacle.position.x - ballRadius,
      obstacle.position.y - ballRadius,
      obstacle.size.x + ballRadius * 2,
      obstacle.size.y + ballRadius * 2,
    );

    // 检查线段与扩展矩形是否相交
    return _lineSegmentRectIntersection(startPos, endPos, obstacleRect);
  }

  /// 检查圆与矩形的碰撞
  bool _checkCircleRectCollision(
    Vector2 circleCenter,
    ObstacleComponent obstacle,
  ) {
    final obstacleRect = Rect.fromLTWH(
      obstacle.position.x,
      obstacle.position.y,
      obstacle.size.x,
      obstacle.size.y,
    );

    // 找到矩形上离圆心最近的点
    final closestX = circleCenter.x.clamp(
      obstacleRect.left,
      obstacleRect.right,
    );
    final closestY = circleCenter.y.clamp(
      obstacleRect.top,
      obstacleRect.bottom,
    );

    // 计算最近点到圆心的距离
    final distanceX = circleCenter.x - closestX;
    final distanceY = circleCenter.y - closestY;
    final distanceSquared = distanceX * distanceX + distanceY * distanceY;

    // 如果距离小于半径的平方，则发生碰撞
    return distanceSquared < ballRadius * ballRadius;
  }

  /// 检查线段与矩形是否相交
  bool _lineSegmentRectIntersection(Vector2 start, Vector2 end, Rect rect) {
    // 检查任意端点是否在矩形内
    if (rect.contains(Offset(start.x, start.y)) ||
        rect.contains(Offset(end.x, end.y))) {
      return true;
    }

    // 检查线段与矩形四条边的交点
    final edges = [
      [rect.topLeft, rect.topRight], // 上边
      [rect.topRight, rect.bottomRight], // 右边
      [rect.bottomRight, rect.bottomLeft], // 下边
      [rect.bottomLeft, rect.topLeft], // 左边
    ];

    for (final edge in edges) {
      final edgeStart = Vector2(edge[0].dx, edge[0].dy);
      final edgeEnd = Vector2(edge[1].dx, edge[1].dy);
      if (_lineIntersection(start, end, edgeStart, edgeEnd) != null) {
        return true;
      }
    }

    return false;
  }

  /// 计算两条线段的交点
  Vector2? _lineIntersection(Vector2 p1, Vector2 p2, Vector2 p3, Vector2 p4) {
    final denom = (p4.y - p3.y) * (p2.x - p1.x) - (p4.x - p3.x) * (p2.y - p1.y);
    if (denom.abs() < 0.0001) return null; // 平行或重合

    final ua =
        ((p4.x - p3.x) * (p1.y - p3.y) - (p4.y - p3.y) * (p1.x - p3.x)) / denom;
    final ub =
        ((p2.x - p1.x) * (p1.y - p3.y) - (p2.y - p1.y) * (p1.x - p3.x)) / denom;

    // 检查交点是否在两条线段上
    if (ua >= 0.0 && ua <= 1.0 && ub >= 0.0 && ub <= 1.0) {
      return Vector2(p1.x + ua * (p2.x - p1.x), p1.y + ua * (p2.y - p1.y));
    }

    return null;
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

      // 调整圆心位置到组件中心
      canvas.drawCircle(ui.Offset(ballRadius, ballRadius), ballRadius, paint);
    }
  }

  /// 验证与玩家的碰撞是否有效
  bool _isValidPlayerCollision(PlayerComponent player) {
    // 检查距离 - 使用标准碰撞距离（球半径 + 玩家半径）
    final distance = center.distanceTo(player.center);
    final collisionDistance = ballRadius + player.radius;

    if (distance > collisionDistance) {
      return false; // 距离太远
    }

    // 对于高速球，使用穿透检测防止误判
    if (velocity.length > 120) {
      final toPlayer = (player.center - center).normalized();
      final velocityDirection = velocity.normalized();
      final dotProduct = toPlayer.dot(velocityDirection);

      // 如果球正在远离玩家（点积为负），可能是已经穿透或误判
      // 使用更宽松的阈值，避免漏检
      if (dotProduct < -0.3) {
        return false;
      }
    }

    return true;
  }

  void reflectOnHorizontalWall() {
    collidedOnce = true;
    velocity.y = -velocity.y * 0.8; // 20%能量损失，与多人模式保持一致
    _decreaseAndCheck();
  }

  void reflectOnVerticalWall() {
    collidedOnce = true;
    velocity.x = -velocity.x * 0.8; // 20%能量损失，与多人模式保持一致
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
}
