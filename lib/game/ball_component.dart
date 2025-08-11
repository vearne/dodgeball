import 'dart:ui' as ui;

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

import 'arrow_component.dart';
import 'player_component.dart';
import 'team.dart';

class BallComponent extends CircleComponent
    with CollisionCallbacks, HasGameReference {
  BallComponent({
    required this.team,
    required this.ownerPlayerId,
    required Vector2 position,
    required Vector2 initialVelocity,
    required this.bounceCount,
    double radius = 8,
    this.onHitPlayer,
  }) : super(
         position: position,
         radius: radius,
         anchor: Anchor.center,
         paint: ui.Paint()..color = _colorForTeam(team),
       ) {
    velocity = initialVelocity;
    remainingLabel = TextComponent(
      text: '$bounceCount',
      anchor: Anchor.center,
      position: Vector2.zero(),
      scale: Vector2.all(0.7),
      priority: 1,
    );
  }

  final Team team;
  final int ownerPlayerId; // 发球者ID，用于计分
  late Vector2 velocity;
  int bounceCount; // 初始为 1..5 的随机数
  late final TextComponent remainingLabel;
  bool collidedOnce = false; // 首次与墙/玩家发生碰撞后置为 true
  final void Function(BallComponent ball, PlayerComponent hitPlayer)? onHitPlayer;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(CircleHitbox());
    add(remainingLabel);
  }

  static ui.Color _colorForTeam(Team team) {
    switch (team) {
      case Team.red:
        return const ui.Color(0xFFFF5252); // 红队：红色球
      case Team.blue:
        return const ui.Color(0xFF42A5F5); // 蓝队：蓝色球
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    position += velocity * dt;
  }

  void reflectOnHorizontalWall() {
    collidedOnce = true;
    velocity.y = -velocity.y;
    _decreaseAndCheck();
  }

  void reflectOnVerticalWall() {
    collidedOnce = true;
    velocity.x = -velocity.x;
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

  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);

    // 与玩家箭头发生碰撞：只对敌方有效
    if (other is ArrowComponent) {
      final parentComponent = other.parent;
      if (parentComponent is PlayerComponent) {
        final player = parentComponent;
        if (!player.isEliminated && player.team != team) {
          player.eliminate();
          hitPlayerAndContinue();
          // 交由游戏回调处理计分等逻辑
          onHitPlayer?.call(this, player);
        }
      }
    }
  }
}
