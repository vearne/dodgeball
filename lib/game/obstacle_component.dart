import 'dart:ui' as ui;
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flame/components.dart';
import 'mission_map.dart';
import 'ball_component.dart';

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
  final Vector2 _initialPosition; // 保存初始位置用于调试

  AtomicBrickComponent({required Vector2 position})
    : _initialPosition = position,
      super(
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

    // 添加渲染组件（位置设置为 Vector2.zero() 以确保在 body 中心）
    final renderComponent = _BrickRenderComponent(
      size: Vector2.all(atomicSize),
      sprite: _brickSprite,
    )..position = Vector2.zero();
    add(renderComponent);
    
    // 调试：打印原子砖块的详细信息
    print('=== 原子砖块调试信息 ===');
    print('构造函数传入的 position: $_initialPosition');
    print('body.position (onLoad后): ${body.position}');
    print('renderComponent.position: ${renderComponent.position}');
    print('parent: ${parent?.runtimeType}');
    if (parent is PositionComponent) {
      print('parent.position: ${(parent as PositionComponent).position}');
    }
    if (parent is BodyComponent) {
      print('parent.body.position: ${(parent as BodyComponent).body.position}');
    }
    print('body.position (绝对位置): ${body.position}');
    print('======================');
  }

  /// 设置碰撞回调
  void _setupCollisionCallbacks() {
    onBeginContact = (other, contact) {
      // 处理与球的碰撞
      if (other is BallComponent) {
        handleBallCollision(other);
      }
    };

    onEndContact = (other, contact) {
      // 碰撞结束时的处理（如果需要）
    };
  }

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
  bool _debugPrinted = false; // 调试标志，避免重复打印

  _BrickRenderComponent({required Vector2 size, this.sprite})
    : super(size: size, anchor: Anchor.center);

  @override
  void render(ui.Canvas canvas) {
    // 调试：打印渲染信息（只打印一次，避免刷屏）
    if (!_debugPrinted) {
      print('=== _BrickRenderComponent 渲染 ===');
      print('组件 position: $position');
      print('组件 size: $size');
      print('组件 anchor: $anchor');
      print('父组件: ${parent?.runtimeType}');
      if (parent is BodyComponent) {
        final bodyParent = parent as BodyComponent;
        print('父组件 body.position: ${bodyParent.body.position}');
        // 计算渲染矩形的实际位置
        final renderLeft = bodyParent.body.position.x - size.x / 2;
        final renderTop = bodyParent.body.position.y - size.y / 2;
        final renderRight = bodyParent.body.position.x + size.x / 2;
        final renderBottom = bodyParent.body.position.y + size.y / 2;
        print('渲染矩形左上角: ($renderLeft, $renderTop)');
        print('渲染矩形右下角: ($renderRight, $renderBottom)');
        print('渲染矩形中心: (${bodyParent.body.position.x}, ${bodyParent.body.position.y})');
      }
      print('canvas 原点应该在组件中心（因为 anchor 是 center）');
      print('dstRect 应该是: (-${size.x/2}, -${size.y/2}, ${size.x}, ${size.y})');
      _debugPrinted = true;
    }
    
    if (sprite != null) {
      // 使用图片渲染
      // canvas 的原点在组件中心（因为 anchor 是 center）
      // 需要添加 (width/2, height/2) 的偏移来对齐碰撞体
      final offsetX = size.x / 2;
      final offsetY = size.y / 2;
      
      final paint = ui.Paint()
        ..isAntiAlias = true
        ..filterQuality = ui.FilterQuality.high;
      
      final srcRect = sprite!.src;
      final dstRect = ui.Rect.fromLTWH(
        -size.x / 2 + offsetX,
        -size.y / 2 + offsetY,
        size.x,
        size.y,
      );
      
      canvas.drawImageRect(sprite!.image, srcRect, dstRect, paint);
    } else {
      // 降级方案：使用代码绘制
      // canvas 的原点在组件中心（因为 anchor 是 center）
      // 需要添加 (width/2, height/2) 的偏移来对齐碰撞体
      final halfSize = size / 2;
      final offsetX = size.x / 2;
      final offsetY = size.y / 2;
      
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
      canvas.drawRect(
        ui.Rect.fromLTWH(-halfSize.x + offsetX, -halfSize.y + offsetY, size.x, size.y),
        brickPaint,
      );

      // 绘制砖块边框（砖缝）
      canvas.drawRect(
        ui.Rect.fromLTWH(-halfSize.x + offsetX, -halfSize.y + offsetY, size.x, size.y),
        mortarPaint,
      );

      // 绘制砖块纹理（横向分割线）
      final texturePaint = ui.Paint()
        ..color =
            const ui.Color(0xFF8B0000) // 深红色纹理
        ..style = ui.PaintingStyle.stroke
        ..strokeWidth = 1.0;

      canvas.drawLine(
        ui.Offset(-halfSize.x + offsetX, offsetY),
        ui.Offset(halfSize.x + offsetX, offsetY),
        texturePaint,
      );
    }
  }
}

/// 砖墙组件：由多个原子砖块组成的复合障碍物
class BrickWallComponent extends BodyComponent {
  final List<AtomicBrickComponent> _atomicBricks = [];
  final Vector2 _size; // 像素尺寸
  final Vector2 _centerPosition; // 保存中心点位置，避免在 onMount 时 body.position 可能未初始化

  BrickWallComponent({required Vector2 position, required Vector2 size})
    : _size = size,
      _centerPosition = position,
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

    // 由于 body 中心位置是 (x, y)（左上角），而渲染偏移是 (width/2, height/2)，
    // 原子砖块的左上角应该从 (x, y) 开始
    // 使用保存的中心点位置（实际上是左上角），确保在 onMount 时能正确获取
    // 计算左上角坐标（中心坐标减去一半的尺寸）
    final topLeftX = _centerPosition.x - _size.x / 2;
    final topLeftY = _centerPosition.y - _size.y / 2;
    
    // 调试：打印砖墙组件信息
    print('=== 砖墙组件 onMount ===');
    print('_centerPosition: (${_centerPosition.x}, ${_centerPosition.y})');
    print('body.position: ${body.position}');
    print('topLeft: ($topLeftX, $topLeftY)');
    print('_size: (${_size.x}, ${_size.y})');
    print('parent: ${parent?.runtimeType}');
    if (parent is PositionComponent) {
      print('parent.position: ${(parent as PositionComponent).position}');
    }
    print('========================');

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
          
          // 调试：打印砖块位置
          print('=== 创建原子砖块 ===');
          print('计算的中心位置: ($brickCenterX, $brickCenterY)');
          print('topLeft: ($topLeftX, $topLeftY)');
          print('brickX: $brickX, brickY: $brickY');
          print('砖墙中心(_centerPosition): (${_centerPosition.x}, ${_centerPosition.y})');
          print('砖墙大小: (${_size.x}, ${_size.y})');
          print('body.position (创建时): ${body.position}');
          
          _atomicBricks.add(atomicBrick);
          // 将原子砖块直接添加到游戏世界，而不是作为 BrickWallComponent 的子组件
          // 这样可以避免可能的坐标转换问题
          if (parent != null) {
            parent!.add(atomicBrick);
          } else {
            add(atomicBrick);
          }
          
          // 等待原子砖块加载完成后打印实际位置
          atomicBrick.loaded.then((_) {
            print('=== 原子砖块加载完成后的位置 ===');
            print('body.position: ${atomicBrick.body.position}');
            print('渲染组件数量: ${atomicBrick.children.length}');
            for (final child in atomicBrick.children) {
              if (child is PositionComponent) {
                print('  子组件 ${child.runtimeType}: position=${child.position}, size=${child.size}');
              }
            }
            print('================================');
          });
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

    // 由于 body 中心位置是 (x, y)（左上角），而渲染偏移是 (width/2, height/2)，
    // 我们需要调整碰撞体的位置，使其左上角在 (x, y)
    // 如果 body 中心是 (x, y)（左上角），那么要得到左上角在 (x, y) 的碰撞体，
    // 碰撞体的顶点应该是相对于 body 中心的，也就是从 (0, 0) 开始
    // 顶点顺序：左上、右上、右下、左下（逆时针）
    shape.set([
      Vector2(0, 0), // 左上：在 body 中心位置（也就是左上角位置）
      Vector2(_size.x, 0), // 右上
      Vector2(_size.x, _size.y), // 右下
      Vector2(0, _size.y), // 左下
    ]);

    final fixtureDef = FixtureDef(
      shape,
      friction: 0.5,
      restitution: 0.8, // 岩石反弹
    );
    body.createFixture(fixtureDef);

    // 添加渲染组件（位置设置为 Vector2.zero() 以确保在 body 中心）
    final renderComponent = _RockRenderComponent(
      size: _size,
      sprite: _rockSprite,
    )..position = Vector2.zero();
    add(renderComponent);
  }

  /// 设置碰撞回调
  void _setupCollisionCallbacks() {
    onBeginContact = (other, contact) {
      // 处理与球的碰撞
      if (other is BallComponent) {
        handleBallCollision(other);
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
  bool _debugPrinted = false; // 调试标志，避免重复打印

  _RockRenderComponent({required Vector2 size, this.sprite})
    : _size = size,
      super(size: size, anchor: Anchor.center);

  @override
  void render(ui.Canvas canvas) {
    // 调试：打印渲染信息（只打印一次，避免刷屏）
    if (!_debugPrinted) {
      print('=== _RockRenderComponent 渲染 ===');
      print('组件 position: $position');
      print('组件 size: $_size');
      print('组件 anchor: $anchor');
      print('父组件: ${parent?.runtimeType}');
      if (parent is BodyComponent) {
        final bodyParent = parent as BodyComponent;
        print('父组件 body.position: ${bodyParent.body.position}');
      }
      print('canvas 原点应该在组件中心（因为 anchor 是 center）');
      _debugPrinted = true;
    }
    
    if (sprite != null) {
      // 使用图片渲染（平铺方式填充整个区域）
      // 注意：canvas 的原点在组件中心（因为 anchor 是 center）
      final tileSize = 30.0;
      final tilesX = (_size.x / tileSize).ceil();
      final tilesY = (_size.y / tileSize).ceil();

      final halfSize = _size / 2;

      // 使用高质量渲染设置
      final paint = ui.Paint()
        ..isAntiAlias = true
        ..filterQuality = ui.FilterQuality.high;

      for (int row = 0; row < tilesY; row++) {
        for (int col = 0; col < tilesX; col++) {
          // 计算每个 tile 的左上角位置（相对于组件中心，因为 anchor 是 center）
          final tileLeft = -halfSize.x + col * tileSize;
          final tileTop = -halfSize.y + row * tileSize;
          final tileRight = tileLeft + tileSize;
          final tileBottom = tileTop + tileSize;
          
          // 只绘制在组件边界内的 tile
          if (tileRight > -halfSize.x && tileLeft < halfSize.x &&
              tileBottom > -halfSize.y && tileTop < halfSize.y) {
            // 计算需要绘制的部分（裁剪到组件边界）
            final drawLeft = tileLeft.clamp(-halfSize.x, halfSize.x);
            final drawTop = tileTop.clamp(-halfSize.y, halfSize.y);
            final drawRight = tileRight.clamp(-halfSize.x, halfSize.x);
            final drawBottom = tileBottom.clamp(-halfSize.y, halfSize.y);
            
            final drawWidth = drawRight - drawLeft;
            final drawHeight = drawBottom - drawTop;
            
            if (drawWidth > 0 && drawHeight > 0) {
              // 计算源矩形（如果 tile 被裁剪，需要相应裁剪源矩形）
              final srcWidth = sprite!.src.width;
              final srcHeight = sprite!.src.height;
              
              // 计算裁剪的偏移量（相对于 tile 的左上角）
              final clipOffsetX = drawLeft - tileLeft;
              final clipOffsetY = drawTop - tileTop;
              
              // 计算源矩形的裁剪部分
              final srcX = sprite!.src.left + (clipOffsetX / tileSize) * srcWidth;
              final srcY = sprite!.src.top + (clipOffsetY / tileSize) * srcHeight;
              final srcW = (drawWidth / tileSize) * srcWidth;
              final srcH = (drawHeight / tileSize) * srcHeight;
              
              final srcRect = ui.Rect.fromLTWH(srcX, srcY, srcW, srcH);
              
              // 目标矩形是相对于组件中心的（因为 anchor 是 center）
              // drawLeft 和 drawTop 已经是相对于组件中心的正确坐标
              final dstRect = ui.Rect.fromLTWH(
                drawLeft,
                drawTop,
                drawWidth,
                drawHeight,
              );
              
              canvas.drawImageRect(sprite!.image, srcRect, dstRect, paint);
            }
          }
        }
      }
    } else {
      // 降级方案：使用代码绘制
      // canvas 的原点在组件中心（因为 anchor 是 center）
      // 所以岩石的左上角应该在 (-_size.x/2, -_size.y/2)
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
  // 障碍物数据中的 x, y 是左上角坐标，需要转换为中心点坐标（Forge2D使用中心点）
  final size = Vector2(obstacle.width, obstacle.height);
  
  // 将左上角坐标转换为中心坐标
  // 地图编辑器中的 (x, y) 是左上角，Forge2D 需要中心坐标
  final centerPosition = Vector2(
    obstacle.x + size.x / 2, // 中心 x = 左上角 x + 宽度的一半
    obstacle.y + size.y / 2, // 中心 y = 左上角 y + 高度的一半
  );
  
  // 调试：打印障碍物创建信息
  print('=== 创建障碍物组件 ===');
  print('障碍物类型: ${obstacle.type}');
  print('地图编辑器坐标 (左上角): (${obstacle.x}, ${obstacle.y})');
  print('大小: (${size.x}, ${size.y})');
  print('计算的中心位置: (${centerPosition.x}, ${centerPosition.y})');
  print('====================');

  switch (obstacle.type) {
    case ObstacleType.brickWall:
      return BrickWallComponent(position: centerPosition, size: size);
    case ObstacleType.rock:
      return RockComponent(position: centerPosition, size: size);
  }
}
