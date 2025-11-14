import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'player_component.dart';

/// 道具类型
enum PowerUpType {
  speedBoost, // 精灵鞋：移动速度加速
  attackSpeed, // 攻速球：投掷冷却时间缩短
}

/// 道具组件
class PowerUpComponent extends PositionComponent
    with CollisionCallbacks, HasGameReference {
  PowerUpComponent({
    required this.type,
    required Vector2 position,
  }) : super(
          position: position,
          size: Vector2.all(32),
          anchor: Anchor.center,
        );

  final PowerUpType type;
  bool _collected = false;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // 添加圆形碰撞箱
    add(CircleHitbox(radius: 16));

    // 添加旋转动画效果
    add(RotatingComponent());
  }

  @override
  void render(ui.Canvas canvas) {
    super.render(canvas);

    if (_collected) return;

    // 根据道具类型绘制不同的外观
    switch (type) {
      case PowerUpType.speedBoost:
        _drawSpeedBoost(canvas);
        break;
      case PowerUpType.attackSpeed:
        _drawAttackSpeed(canvas);
        break;
    }
  }

  void _drawSpeedBoost(ui.Canvas canvas) {
    // 绘制精灵鞋：黄色星星形状
    final paint = ui.Paint()
      ..color = const ui.Color(0xFFFFD700) // 金色
      ..style = ui.PaintingStyle.fill;

    // 绘制星星
    final path = ui.Path();
    final center = ui.Offset(size.x / 2, size.y / 2);
    final outerRadius = 12.0;
    final innerRadius = 6.0;
    final points = 5;

    for (int i = 0; i < points * 2; i++) {
      final angle = (i * math.pi) / points - math.pi / 2;
      final radius = i.isEven ? outerRadius : innerRadius;
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();

    canvas.drawPath(path, paint);

    // 绘制边框
    final borderPaint = ui.Paint()
      ..color = const ui.Color(0xFFFFA500) // 橙色边框
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawPath(path, borderPaint);
  }

  void _drawAttackSpeed(ui.Canvas canvas) {
    // 绘制攻速球：红色球形状
    final paint = ui.Paint()
      ..color = const ui.Color(0xFFFF0000) // 红色
      ..style = ui.PaintingStyle.fill;

    final center = ui.Offset(size.x / 2, size.y / 2);
    canvas.drawCircle(center, 12.0, paint);

    // 绘制边框
    final borderPaint = ui.Paint()
      ..color = const ui.Color(0xFFCC0000) // 深红色边框
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawCircle(center, 12.0, borderPaint);

    // 绘制闪电符号
    final lightningPaint = ui.Paint()
      ..color = const ui.Color(0xFFFFFFFF) // 白色
      ..style = ui.PaintingStyle.fill;

    final lightningPath = ui.Path();
    lightningPath.moveTo(center.dx, center.dy - 8);
    lightningPath.lineTo(center.dx + 3, center.dy);
    lightningPath.lineTo(center.dx - 2, center.dy);
    lightningPath.lineTo(center.dx, center.dy + 8);
    lightningPath.lineTo(center.dx - 3, center.dy);
    lightningPath.lineTo(center.dx + 2, center.dy);
    lightningPath.close();

    canvas.drawPath(lightningPath, lightningPaint);
  }

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    super.onCollisionStart(intersectionPoints, other);

    if (other is PlayerComponent && !_collected) {
      _applyPowerUp(other);
      _collected = true;
      removeFromParent();
    }
  }

  void _applyPowerUp(PlayerComponent player) {
    switch (type) {
      case PowerUpType.speedBoost:
        _applySpeedBoost(player);
        break;
      case PowerUpType.attackSpeed:
        _applyAttackSpeed(player);
        break;
    }
  }

  /// 应用精灵鞋效果：移动速度加速
  void _applySpeedBoost(PlayerComponent player) {
    // 增加移动速度（持续30秒）
    final originalSpeed = player.movementSpeed;
    player.movementSpeed = originalSpeed * 1.5; // 1.5倍速度

    // 30秒后恢复
    final game = findGame();
    if (game != null) {
      game.add(
        TimerComponent(
          period: 30.0,
          onTick: () {
            player.movementSpeed = originalSpeed;
          },
        ),
      );
    }
  }

  /// 应用攻速球效果：投掷冷却时间缩短
  void _applyAttackSpeed(PlayerComponent player) {
    // 减少投掷冷却时间（持续30秒）
    // 注意：这需要修改PlayerComponent的冷却机制
    // 这里我们通过设置一个标记来实现
    player.setAttackSpeedBoost(true);

    // 30秒后恢复
    final game = findGame();
    if (game != null) {
      game.add(
        TimerComponent(
          period: 30.0,
          onTick: () {
            player.setAttackSpeedBoost(false);
          },
        ),
      );
    }
  }
}

/// 旋转组件：让道具旋转
class RotatingComponent extends Component {
  double _rotation = 0.0;

  @override
  void update(double dt) {
    super.update(dt);
    _rotation += dt * 2.0; // 每秒旋转2弧度
    if (_rotation > 6.28318) {
      _rotation -= 6.28318;
    }
  }

  @override
  void render(ui.Canvas canvas) {
    // 旋转效果由父组件处理
  }
}

