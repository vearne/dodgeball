import 'dart:ui' as ui;
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';
import 'player_component.dart';

/// 道具类型
enum PowerUpType {
  speedBoost, // 速度靴子：移动速度增加20%，持续10秒
  attackSpeed, // 攻速球：投掷冷却时间缩短（保留原有功能）
  health, // 血瓶：增加1条生命
}

/// 道具组件
class PowerUpComponent extends PositionComponent
    with CollisionCallbacks, HasGameReference {
  PowerUpComponent({
    required this.type,
    required Vector2 position,
    this.onCollected,
  }) : super(
         position: position - Vector2.all(18), // 将中心位置转换为topLeft位置 (36/2)
         size: Vector2.all(36), // 36x36像素
         anchor: Anchor.topLeft,
       );

  final PowerUpType type;
  final VoidCallback? onCollected; // 道具被拾取时的回调
  bool _collected = false;
  Sprite? _sprite;

  /// 获取道具图片路径
  String get _imagePath {
    switch (type) {
      case PowerUpType.health:
        return 'hp_potion_36_36.png';
      case PowerUpType.speedBoost:
        return 'boot_36_36.png';
      case PowerUpType.attackSpeed:
        return 'speed_ball_36_36.png';
    }
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // 加载道具图片，使用 Sprite.load 确保正确加载透明 PNG
    try {
      _sprite = await Sprite.load(_imagePath);
    } catch (e) {
      // 如果图片加载失败，使用备用绘制
    }

    // 添加圆形碰撞箱
    add(
      CircleHitbox(
        radius: 16,
        position: Vector2(18, 18), // 居中: 36/2 = 18
        anchor: Anchor.center,
      ),
    );

    // 添加上下浮动动画效果
    add(FloatingComponent(parent: this));
  }

  @override
  void render(ui.Canvas canvas) {
    super.render(canvas);

    if (_collected) return;

    if (_sprite != null) {
      // 使用高质量渲染设置
      final paint = ui.Paint()
        ..isAntiAlias = true
        ..filterQuality = ui.FilterQuality.high;

      // 渲染道具图片（支持透明PNG）
      final srcRect = _sprite!.src;
      final dstRect = ui.Rect.fromLTWH(0, 0, size.x, size.y);
      canvas.drawImageRect(_sprite!.image, srcRect, dstRect, paint);
    } else {
      // 备用：如果图片未加载，使用简单的颜色方块
      _drawFallback(canvas);
    }
  }

  /// 备用绘制方法（当图片加载失败时使用）
  void _drawFallback(ui.Canvas canvas) {
    final paint = ui.Paint()..style = ui.PaintingStyle.fill;

    switch (type) {
      case PowerUpType.health:
        paint.color = const ui.Color(0xFFFF1493); // 粉红色
        break;
      case PowerUpType.speedBoost:
        paint.color = const ui.Color(0xFF8B4513); // 棕色
        break;
      case PowerUpType.attackSpeed:
        paint.color = const ui.Color(0xFFFF8C00); // 橙色
        break;
    }

    final center = ui.Offset(size.x / 2, size.y / 2);
    canvas.drawCircle(center, 16.0, paint);

    // 边框
    final borderPaint = ui.Paint()
      ..color = const ui.Color(0xFF000000)
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(center, 16.0, borderPaint);
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
      // 调用回调
      onCollected?.call();
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
      case PowerUpType.health:
        _applyHealth(player);
        break;
    }
  }

  /// 应用速度靴子效果：移动速度加速
  void _applySpeedBoost(PlayerComponent player) {
    final game = findGame();
    if (game != null) {
      // 检查是否是MissionDodgeballGame
      if (game.runtimeType.toString().contains('MissionDodgeballGame')) {
        // 使用反射或动态调用（Dart不直接支持反射，所以使用duck typing）
        try {
          (game as dynamic).applySpeedBoost(player);
        } catch (e) {
          // 降级方案：直接创建定时器
          _applySpeedBoostFallback(player, game);
        }
      } else {
        // 其他游戏模式使用降级方案
        _applySpeedBoostFallback(player, game);
      }
    }
  }

  void _applySpeedBoostFallback(PlayerComponent player, dynamic game) {
    const originalSpeed = 120.0;
    player.movementSpeed = originalSpeed * 1.2; // 20%增速

    game.add(
      TimerComponent(
        period: 10.0, // 10秒
        onTick: () {
          player.movementSpeed = originalSpeed;
        },
      ),
    );
  }

  /// 应用血瓶效果：增加1条生命
  void _applyHealth(PlayerComponent player) {
    // 增加1条生命值（可以超过初始最大生命值）
    player.setCurrentHealth(player.currentHealth + 1);
  }

  /// 应用攻速球效果：投掷冷却时间缩短
  void _applyAttackSpeed(PlayerComponent player) {
    final game = findGame();
    if (game != null) {
      // 检查是否是MissionDodgeballGame
      if (game.runtimeType.toString().contains('MissionDodgeballGame')) {
        try {
          (game as dynamic).applyAttackSpeedBoost(player);
        } catch (e) {
          // 降级方案：直接创建定时器
          _applyAttackSpeedFallback(player, game);
        }
      } else {
        // 其他游戏模式使用降级方案
        _applyAttackSpeedFallback(player, game);
      }
    }
  }

  void _applyAttackSpeedFallback(PlayerComponent player, dynamic game) {
    player.setAttackSpeedBoost(true);

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

/// 浮动组件：让道具上下浮动
class FloatingComponent extends Component {
  FloatingComponent({required this.parent});

  final PositionComponent parent;
  double _time = 0.0;
  late final double _baseY;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _baseY = parent.position.y;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt * 3.0; // 浮动频率

    // 使用正弦函数创建上下浮动效果
    parent.position.y = _baseY + 4.0 * _sin(_time);
  }

  double _sin(double x) {
    // 简单的正弦近似
    x = x % 6.28318;
    if (x > 3.14159) x -= 6.28318;
    return x - (x * x * x) / 6.0 + (x * x * x * x * x) / 120.0;
  }
}
