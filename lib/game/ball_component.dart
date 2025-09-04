import 'dart:ui' as ui;
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

import 'arrow_component.dart';
import 'dodgeball_game.dart';
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
         position: position,
         size: Vector2.all(radius * 2), // sprite需要size而不是radius
         anchor: Anchor.center,
       ) {
    velocity = initialVelocity;
    remainingLabel = TextComponent(
      text: '$bounceCount',
      anchor: Anchor.center,
      position: Vector2(ballRadius * 0.8, ballRadius * 0.8),
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

  // 调试模式：显示碰撞检测范围
  static bool showDebugCollision = false;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // 根据队伍加载相应的球图片
    final spritePath = _getSpritePathForTeam(team);
    sprite = await Sprite.load(spritePath);

    // 添加圆形碰撞箱，使用ballRadius
    add(CircleHitbox(radius: ballRadius));
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

    // 简化移动逻辑
    position += velocity * dt;

    // 添加连续碰撞检测，防止高速球穿透
    _checkContinuousCollisions(dt);
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
    // 检查玩家是否已经被淘汰或正在被移除
    if (player.isEliminated || player.team == team) {
      return;
    }

    // 验证碰撞的有效性
    if (_isValidPlayerCollision(player)) {
      // 根据游戏模式处理碰撞
      final game = findGame();
      if (game != null && game is DodgeballGame) {
        // 统一处理：玩家受到伤害
        player.takeDamage();
      } else {
        // 默认行为：淘汰
        player.eliminate();
      }

      hitPlayerAndContinue();
      onHitPlayer?.call(this, player);
    }
  }

  /// 连续碰撞检测，防止高速球穿透
  void _checkContinuousCollisions(double dt) {
    final game = findGame();
    if (game == null) return;

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
    // 计算球在这一帧内的移动轨迹
    final startPos = position - velocity * dt;
    final endPos = position;

    // 计算球轨迹与玩家碰撞体的最近距离
    final closestPoint = _getClosestPointOnLineToCircle(
      startPos,
      endPos,
      player.position,
      player.radius,
    );

    // 如果最近距离小于球的半径，说明发生了碰撞
    final distance = closestPoint.distanceTo(player.position);
    return distance <= ballRadius;
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

  @override
  void render(ui.Canvas canvas) {
    super.render(canvas);

    // 调试模式：显示碰撞检测范围
    if (showDebugCollision) {
      final paint = ui.Paint()
        ..color = const ui.Color.fromARGB(100, 255, 0, 0)
        ..style = ui.PaintingStyle.stroke
        ..strokeWidth = 1.0;

      canvas.drawCircle(ui.Offset.zero, ballRadius, paint);
    }
  }

  /// 验证与玩家的碰撞是否有效
  bool _isValidPlayerCollision(PlayerComponent player) {
    // 检查距离 - 使用更严格的碰撞距离
    final distance = position.distanceTo(player.position);
    final collisionDistance = ballRadius + player.radius * 0.9; // 减少到0.9倍半径，更严格

    if (distance > collisionDistance) {
      return false; // 距离太远
    }

    // 对于高速球，使用更严格的穿透检测
    if (velocity.length > 120) {
      // 降低阈值，更早检测
      final toPlayer = (player.position - position).normalized();
      final velocityDirection = velocity.normalized();
      final dotProduct = toPlayer.dot(velocityDirection);

      // 如果球正在远离玩家，可能是穿透
      if (dotProduct < -0.15) {
        // 更严格的阈值
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
