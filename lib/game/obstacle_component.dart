import 'dart:ui' as ui;
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flame/components.dart';
import 'mission_map.dart';
import 'ball_component.dart';
import 'package:flutter/material.dart';

/// 障碍物组件基类
abstract class ObstacleComponent extends BodyComponent {
  final Vector2 _size; // 像素尺寸

  ObstacleComponent({required Vector2 position, required Vector2 size})
    : _size = size,
      super(
        bodyDef: BodyDef(
          position: position, // 直接使用像素坐标
          type: BodyType.static, // 障碍物是静态的
        ),
      );

  /// 兼容：获取大小（像素坐标）
  Vector2 get size => _size;

  /// 兼容：获取绝对位置（像素坐标）
  Vector2 get absolutePosition => body.position;

  /// 处理球与障碍物的碰撞
  void handleBallCollision(BallComponent ball);
}

/// 原子砖块组件：30px*30px 的基本砖块单元
class AtomicBrickComponent extends BodyComponent with ContactCallbacks {
  static const double atomicSize = 30.0; // 原子砖块大小
  Sprite? _brickSprite; // 砖块图片精灵

  AtomicBrickComponent({required Vector2 position})
    : super(
        bodyDef: BodyDef(position: position, type: BodyType.static),
        fixtureDefs: [
          FixtureDef(
            PolygonShape()..setAsBoxXY(atomicSize / 2, atomicSize / 2),
            friction: 0.5,
            restitution: 0.0,
          ),
        ],
      );

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // 设置 body.userData 为 this，使 WorldContactListener 能够调用此组件的碰撞回调
    body.userData = this;

    // 设置碰撞回调
    _setupCollisionCallbacks();

    // 加载砖块图片
    try {
      _brickSprite = await Sprite.load('wall_30_30.png');
    } catch (e) {}

    // 添加渲染组件
    final renderComponent = _BrickRenderComponent(
      size: Vector2.all(atomicSize),
      sprite: _brickSprite,
    );
    add(renderComponent);
  }

  /// 设置碰撞回调
  void _setupCollisionCallbacks() {
    onBeginContact = (other, contact) {
      // 处理与球的碰撞
      if (other is BallComponent) {
        handleBallCollision(other as BallComponent);
      }
    };

    onEndContact = (other, contact) {
      // 碰撞结束时的处理（如果需要）
    };
  }

  @override
  void handleBallCollision(BallComponent ball) {
    // 标记球已经击中障碍物，防止一个球摧毁多个原子单位
    if (ball.hasHitObstacle) {
      return;
    }

    // 标记球已经击中障碍物
    ball.hasHitObstacle = true;

    // 球体消失
    ball.removeFromParent();
    // 原子砖块消失
    removeFromParent();
  }
}

/// 砖块的渲染组件
class _BrickRenderComponent extends PositionComponent {
  final Sprite? sprite;

  _BrickRenderComponent({required Vector2 size, this.sprite})
    : super(size: size, anchor: Anchor.center);

  @override
  void render(ui.Canvas canvas) {
    if (sprite != null) {
      // 使用图片渲染
      sprite!.render(canvas, size: size, anchor: Anchor.center);
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
      final halfSize = size / 2;
      canvas.drawRect(
        ui.Rect.fromLTWH(-halfSize.x, -halfSize.y, size.x, size.y),
        brickPaint,
      );

      // 绘制砖块边框（砖缝）
      canvas.drawRect(
        ui.Rect.fromLTWH(-halfSize.x, -halfSize.y, size.x, size.y),
        mortarPaint,
      );

      // 绘制砖块纹理（横向分割线）
      final texturePaint = ui.Paint()
        ..color =
            const ui.Color(0xFF8B0000) // 深红色纹理
        ..style = ui.PaintingStyle.stroke
        ..strokeWidth = 1.0;

      canvas.drawLine(
        ui.Offset(-halfSize.x, 0),
        ui.Offset(halfSize.x, 0),
        texturePaint,
      );
    }
  }
}

/// 砖墙组件：由多个原子砖块组成的复合障碍物
class BrickWallComponent extends BodyComponent {
  final List<AtomicBrickComponent> _atomicBricks = [];
  final Vector2 _size; // 像素尺寸

  BrickWallComponent({required Vector2 position, required Vector2 size})
    : _size = size,
      super(
        bodyDef: BodyDef(position: position, type: BodyType.static),
      );

  /// 兼容：获取大小
  Vector2 get size => _size;

  /// 兼容：获取绝对位置
  Vector2 get absolutePosition => body.position;

  @override
  void onMount() {
    super.onMount();

    // 计算砖墙的左上角（地图坐标是中心点，需要转换为左上角）
    final topLeftX = absolutePosition.x - _size.x / 2;
    final topLeftY = absolutePosition.y - _size.y / 2;

    // 计算需要多少个原子砖块来填充这个区域
    final numColumns = (_size.x / AtomicBrickComponent.atomicSize).ceil();
    final numRows = (_size.y / AtomicBrickComponent.atomicSize).ceil();

    // 创建原子砖块网格
    for (int row = 0; row < numRows; row++) {
      for (int col = 0; col < numColumns; col++) {
        final brickX = col * AtomicBrickComponent.atomicSize;
        final brickY = row * AtomicBrickComponent.atomicSize;

        // 确保砖块不超出定义的大小
        if (brickX < _size.x && brickY < _size.y) {
          // 计算原子砖块的中心位置
          final brickCenterX =
              topLeftX + brickX + AtomicBrickComponent.atomicSize / 2;
          final brickCenterY =
              topLeftY + brickY + AtomicBrickComponent.atomicSize / 2;
          final atomicBrick = AtomicBrickComponent(
            position: Vector2(brickCenterX, brickCenterY),
          );
          _atomicBricks.add(atomicBrick);
          add(atomicBrick);
        }
      }
    }
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    // 原子砖块在 onMount() 中创建
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
class RockComponent extends ObstacleComponent with ContactCallbacks {
  Sprite? _rockSprite; // 岩石图片精灵

  RockComponent({required Vector2 position, required Vector2 size})
    : super(position: position, size: size);

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // 设置 body.userData 为 this，使 WorldContactListener 能够调用此组件的碰撞回调
    body.userData = this;

    // 设置碰撞回调
    _setupCollisionCallbacks();

    // 加载岩石图片
    try {
      _rockSprite = await Sprite.load('stone_30_30.png');
    } catch (e) {}

    // 添加矩形碰撞体
    final shape = PolygonShape();
    shape.setAsBoxXY(_size.x / 100.0, _size.y / 100.0); // 转换为物理世界的单位
    final fixtureDef = FixtureDef(
      shape,
      friction: 0.5,
      restitution: 0.8, // 岩石反弹
    );
    body.createFixture(fixtureDef);

    // 添加渲染组件
    final renderComponent = _RockRenderComponent(
      size: _size,
      sprite: _rockSprite,
    );
    add(renderComponent);
  }

  /// 设置碰撞回调
  void _setupCollisionCallbacks() {
    onBeginContact = (other, contact) {
      // 处理与球的碰撞
      if (other is BallComponent) {
        handleBallCollision(other as BallComponent);
      }
    };

    onEndContact = (other, contact) {
      // 碰撞结束时的处理（如果需要）
    };
  }

  @override
  void handleBallCollision(BallComponent ball) {
    // Forge2D 会自动处理物理反弹，这里只需要减少弹跳次数
    ball.reflectOnHorizontalWall(); // 水平或垂直会由 Forge2D 自动判断
  }
}

/// 岩石的渲染组件
class _RockRenderComponent extends PositionComponent {
  final Sprite? sprite;
  final Vector2 _size;

  _RockRenderComponent({required Vector2 size, this.sprite})
    : _size = size,
      super(size: size, anchor: Anchor.center);

  @override
  void render(ui.Canvas canvas) {
    if (sprite != null) {
      // 使用图片渲染（平铺方式填充整个区域）
      final tileSize = 30.0;
      final tilesX = (_size.x / tileSize).ceil();
      final tilesY = (_size.y / tileSize).ceil();

      final halfSize = _size / 2;
      canvas.save();
      canvas.translate(-halfSize.x, -halfSize.y);

      for (int row = 0; row < tilesY; row++) {
        for (int col = 0; col < tilesX; col++) {
          final offsetX = col * tileSize - halfSize.x;
          final offsetY = row * tileSize - halfSize.y;

          // 计算需要绘制的部分大小
          final drawWidth = (offsetX + tileSize > halfSize.x)
              ? halfSize.x - offsetX
              : tileSize;
          final drawHeight = (offsetY + tileSize > halfSize.y)
              ? halfSize.y - offsetY
              : tileSize;

          canvas.save();
          canvas.translate(offsetX, offsetY);

          // 裁剪以防止超出边界
          canvas.clipRect(ui.Rect.fromLTWH(0, 0, drawWidth, drawHeight));

          sprite!.render(
            canvas,
            size: Vector2(tileSize, tileSize),
            anchor: Anchor.topLeft,
          );

          canvas.restore();
        }
      }
      canvas.restore();
    } else {
      // 降级方案：使用代码绘制
      final halfSize = _size / 2;

      // 绘制岩石：灰色矩形
      final paint = ui.Paint()
        ..color =
            const ui.Color(0xFF696969) // 灰色
        ..style = ui.PaintingStyle.fill;

      canvas.drawRect(
        ui.Rect.fromLTWH(-halfSize.x, -halfSize.y, _size.x, _size.y),
        paint,
      );

      // 绘制边框
      final borderPaint = ui.Paint()
        ..color =
            const ui.Color(0xFF404040) // 深灰色边框
        ..style = ui.PaintingStyle.stroke
        ..strokeWidth = 2.0;

      canvas.drawRect(
        ui.Rect.fromLTWH(-halfSize.x, -halfSize.y, _size.x, _size.y),
        borderPaint,
      );

      // 绘制岩石纹理（随机点状）
      final texturePaint = ui.Paint()
        ..color = const ui.Color(0xFF505050)
        ..style = ui.PaintingStyle.fill;

      // 简单的点状纹理
      for (int i = 0; i < 10; i++) {
        final x = (i * _size.x / 10 - halfSize.x) % _size.x;
        final y = (i * _size.y / 10 - halfSize.y) % _size.y;
        canvas.drawCircle(ui.Offset(x, y), 2.0, texturePaint);
      }
    }
  }
}

/// 从障碍物数据创建障碍物组件
BodyComponent createObstacleFromData(Obstacle obstacle) {
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
