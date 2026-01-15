import 'dart:ui' as ui;
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';

import 'mission_dodgeball_game.dart';
import 'player_component.dart';

/// 道具类型
enum PowerUpType {
  speedBoost, // 速度靴子：移动速度增加20%，持续10秒
  attackSpeed, // 攻速球：投掷冷却时间缩短（保留原有功能）
  health, // 血瓶：增加1条生命
  coin, // 金币：增加1个金币
  support, // 支援：召唤一个友军AI玩家，不受活动区域限制
  extraBounce, // 额外弹跳：下一次投掷增加1-3次弹跳
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
         // 不在构造函数中创建 fixture，而是在 onLoad 中动态创建以支持偏移
       );

  final PowerUpType type;
  final VoidCallback? onCollected; // 道具被拾取时的回调
  bool _collected = false;
  Sprite? _sprite;

  /// 获取道具是否已被收集
  bool get isCollected => _collected;

  @override
  void update(double dt) {
    super.update(dt);

    if (_collected) return;

    // 备用检测：检查是否有玩家在碰撞范围内（防止物理引擎漏检）
    try {
      final game = findGame();
      if (game != null && game is MissionDodgeballGame) {
        final players = [
          ...(game as MissionDodgeballGame).playerTeam,
          ...(game as MissionDodgeballGame).enemyTeam,
        ];

        for (final player in players) {
          if (player.isEliminated) continue;

          final distance = body.position.distanceTo(player.center);
          // 碰撞半径：道具18 + 玩家16 = 34，留一点余量，使用32作为触发阈值
          if (distance < 32.0) {
            // 玩家在碰撞范围内，手动触发收集
            if (!_collected) {
              print('距离检测触发：玩家 ${player.playerId} 收集道具 $type，距离=$distance');

              // 通过game来应用道具效果
              final gameInstance = game as MissionDodgeballGame;

              switch (type) {
                case PowerUpType.speedBoost:
                  gameInstance.applySpeedBoost(player);
                  break;
                case PowerUpType.attackSpeed:
                  gameInstance.applyAttackSpeedBoost(player);
                  break;
                case PowerUpType.health:
                  player.setCurrentHealth(player.currentHealth + 1);
                  break;
                case PowerUpType.coin:
                  gameInstance.addCoin(1);
                  break;
                case PowerUpType.support:
                  gameInstance.spawnSupportAI(player);
                  break;
                case PowerUpType.extraBounce:
                  final extraBounces =
                      gameInstance.random.nextInt(3) + 1; // 1-3随机
                  gameInstance.setExtraBounces(player, extraBounces);
                  break;
              }

              // 标记为已收集
              markAsCollected();
              return; // 只能被一个玩家收集
            }
          }
        }
      }
    } catch (e) {
      // 忽略错误，继续下一帧
    }
  }

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
      case PowerUpType.support:
        return 'support_36_36.png';
      case PowerUpType.extraBounce:
        return 'extra_bounce_36_36.png';
    }
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // 设置 body.userData 为 this，使 WorldContactListener 能够调用此组件的碰撞回调
    body.userData = this;

    // 动态创建带偏移的碰撞体
    // 使用 CircleShape 的 position 属性来设置偏移（相对于 body 中心）
    // 注意：碰撞体半径设置为18，与视觉半径一致
    final shape = CircleShape()..radius = 18.0;
    final fixtureDef = FixtureDef(
      shape,
      isSensor: true, // 恢复为传感器，避免与球碰撞
    );
    final fixture = body.createFixture(fixtureDef);

    // 设置碰撞回调
    _setupCollisionCallbacks();

    print(
      '道具加载完成: 位置=${body.position}, 类型=$type, 碰撞体半径=${shape.radius}, 传感器=${fixtureDef.isSensor}',
    );

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
    // 道具使用传感器，不会触发物理碰撞
    // 距离检测在 update() 中处理
    onBeginContact = (other, contact) {};
    onEndContact = (other, contact) {};
  }

  @override
  void render(ui.Canvas canvas) {
    // 不调用 super.render(canvas)，避免 BodyComponent 的默认调试渲染显示白色碰撞体
    // 如果需要显示碰撞体，可以取消下面的注释并调整颜色
    /*
    super.render(canvas);
    
    // 可选：自定义调试渲染碰撞体
    final paint = ui.Paint()
      ..color = const ui.Color.fromARGB(100, 255, 255, 255) // 半透明白色
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = 2.0;
    
    // 在偏移位置绘制碰撞体圆（因为 BodyComponent 的渲染已经处理了位置转换）
    canvas.drawCircle(const ui.Offset(-18.0, -18.0), 16.0, paint);
    */
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
      case PowerUpType.support:
        paint.color = const ui.Color(0xFF00CED1); // 青色
        break;
      case PowerUpType.extraBounce:
        paint.color = const ui.Color(0xFF9932CC); // 紫色
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

  double _sin(double x) {
    // 简单的正弦近似
    x = x % 6.28318;
    if (x > 3.14159) x -= 6.28318;
    return x - (x * x * x) / 6.0 + (x * x * x * x * x * x) / 120.0;
  }
}
