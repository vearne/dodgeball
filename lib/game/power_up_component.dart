import 'dart:ui' as ui;
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';
import 'player_component.dart';

/// 道具类型
enum PowerUpType {
  speedBoost, // 速度靴子：移动速度增加20%，持续10秒
  attackSpeed, // 攻速球：投掷冷却时间缩短（保留原有功能）
  health, // 血瓶：增加1条生命
  coin, // 金币：增加1个金币
}

/// 道具组件
class PowerUpComponent extends BodyComponent with ContactCallbacks {
  PowerUpComponent({
    required this.type,
    required Vector2 position,
    this.onCollected,
  }) : super(
         bodyDef: BodyDef(
           position: position,
           type: BodyType.static, // 道具是静态的
         ),
         fixtureDefs: [
           FixtureDef(
             CircleShape()..radius = 16.0,
             isSensor: true, // 设置为传感器，不会对玩家产生物理碰撞
           ),
         ],
       );

  final PowerUpType type;
  final VoidCallback? onCollected; // 道具被拾取时的回调
  bool _collected = false;
  Sprite? _sprite;

  /// 获取道具是否已被收集
  bool get isCollected => _collected;

  /// 标记道具为已收集
  void markAsCollected() {
    _collected = true;
    removeFromParent();
    // 调用回调
    onCollected?.call();
  }

  /// 获取道具图片路径
  String get _imagePath {
    switch (type) {
      case PowerUpType.health:
        return 'hp_potion_36_36.png';
      case PowerUpType.speedBoost:
        return 'boot_36_36.png';
      case PowerUpType.attackSpeed:
        return 'speed_ball_36_36.png';
      case PowerUpType.coin:
        return 'coin_36_36.png';
    }
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // 设置 body.userData 为 this，使 WorldContactListener 能够调用此组件的碰撞回调
    body.userData = this;

    // 设置碰撞回调
    _setupCollisionCallbacks();

    // 加载道具图片，使用 Sprite.load 确保正确加载透明 PNG
    try {
      _sprite = await Sprite.load(_imagePath);
    } catch (e) {
      // 如果图片加载失败，使用备用绘制
    }

    // 添加渲染组件
    final renderComponent = _PowerUpRenderComponent(
      size: Vector2.all(36),
      sprite: _sprite,
      type: type,
    );
    add(renderComponent);

  }

  /// 设置碰撞回调
  void _setupCollisionCallbacks() {
    // 不需要在这里处理碰撞，碰撞逻辑由 PlayerComponent 处理
    // PowerUpComponent 作为传感器，被玩家触发碰撞时调用 PlayerComponent 的方法
    onBeginContact = (other, contact) {};
    onEndContact = (other, contact) {};
  }
}

/// 道具的渲染组件
class _PowerUpRenderComponent extends PositionComponent {
  final Sprite? sprite;
  final PowerUpType type;

  _PowerUpRenderComponent({
    required Vector2 size,
    this.sprite,
    required this.type,
  }) : super(size: size, anchor: Anchor.center);

  @override
  void render(ui.Canvas canvas) {
    if (sprite != null) {
      // 使用高质量渲染设置
      final paint = ui.Paint()
        ..isAntiAlias = true
        ..filterQuality = ui.FilterQuality.high;

      // 渲染道具图片（支持透明PNG）
      final srcRect = sprite!.src;
      final dstRect = ui.Rect.fromLTWH(
        -size.x / 2,
        -size.y / 2,
        size.x,
        size.y,
      );
      canvas.drawImageRect(sprite!.image, srcRect, dstRect, paint);
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
      case PowerUpType.coin:
        paint.color = const ui.Color(0xFFFFD700); // 金色
        break;
    }

    final center = ui.Offset(0, 0);
    canvas.drawCircle(center, 16.0, paint);

    // 边框
    final borderPaint = ui.Paint()
      ..color = const ui.Color(0xFF000000)
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(center, 16.0, borderPaint);
  }
}

/// 浮动组件：让道具上下浮动
class FloatingComponent extends Component {
  FloatingComponent({required this.parent});

  final PowerUpComponent parent;
  double _time = 0.0;
  late final double _baseY;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _baseY = parent.body.position.y;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt * 3.0; // 浮动频率

    // 使用正弦函数创建上下浮动效果
    parent.body.position.y = _baseY + 4.0 * _sin(_time);
  }

  double _sin(double x) {
    // 简单的正弦近似
    x = x % 6.28318;
    if (x > 3.14159) x -= 6.28318;
    return x - (x * x * x) / 6.0 + (x * x * x * x * x * x) / 120.0;
  }
}
