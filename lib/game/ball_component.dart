import 'dart:ui' as ui;

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

import 'arrow_component.dart';
import 'dodgeball_game.dart';
import 'game_mode.dart';
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
  final void Function(BallComponent ball, PlayerComponent hitPlayer)?
  onHitPlayer;

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

    // 简化移动逻辑
    position += velocity * dt;
  }

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    super.onCollisionStart(intersectionPoints, other);

    // 与玩家组件直接碰撞
    if (other is PlayerComponent) {
      _handlePlayerCollision(other);
    }
    // 与玩家箭头发生碰撞（备用检测）
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
    if (player.isEliminated || player.team == team) return;

    // 验证碰撞的有效性
    if (_isValidPlayerCollision(player)) {
      // 根据游戏模式处理碰撞
      final game = findGame();
      if (game != null && game is DodgeballGame) {
        if (game.gameplayMode == GameplayMode.elimination) {
          // 淘汰赛：直接淘汰
          player.eliminate();
        } else if (game.gameplayMode == GameplayMode.timeLimit) {
          // 限时赛：受到伤害但不立即淘汰
          player.takeDamage();
        }
      } else {
        // 默认行为：淘汰
        player.eliminate();
      }

      hitPlayerAndContinue();
      onHitPlayer?.call(this, player);
    }
  }

  /// 验证与玩家的碰撞是否有效
  bool _isValidPlayerCollision(PlayerComponent player) {
    // 检查距离
    final distance = position.distanceTo(player.position);
    final collisionDistance = radius + player.radius * 1.0; // 使用1.0倍半径

    if (distance > collisionDistance) {
      return false; // 距离太远
    }

    // 对于高速球，检查方向
    if (velocity.length > 150) {
      final toPlayer = (player.position - position).normalized();
      final velocityDirection = velocity.normalized();
      final dotProduct = toPlayer.dot(velocityDirection);

      // 如果球正在远离玩家，可能是穿透
      if (dotProduct < -0.2) {
        return false;
      }
    }

    return true;
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
}
