import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

/// 箭头组件：负责渲染箭头、承载王冠/文字，并提供圆形碰撞体
/// 设计为淡紫色圆形背景 + 红色箭头指示方向
class ArrowComponent extends PositionComponent with CollisionCallbacks {
  ArrowComponent({required double sideLength, required this.color})
    : super(size: Vector2.all(sideLength), anchor: Anchor.topLeft);

  ui.Color color;

  // 圆形背景颜色（淡紫色）
  static const ui.Color _backgroundFillColor = ui.Color(0xFFE8D8F0); // 淡紫色填充
  static const ui.Color _backgroundStrokeColor = ui.Color(0xFFB8A0C8); // 紫色边框

  // 箭头形状参数（相对于组件大小，0.5 为中心）
  // 箭头设计为粗壮的指向箭头，适合在圆形内显示
  static const double _tipX = 0.85; // 尖端 X
  static const double _tipY = 0.50; // 尖端 Y（中心）
  static const double _arrowBaseX = 0.50; // 箭头三角形底边 X
  static const double _arrowTopY = 0.20; // 箭头三角形顶部 Y
  static const double _arrowBottomY = 0.80; // 箭头三角形底部 Y
  static const double _bodyTopY = 0.35; // 箭身上边 Y
  static const double _bodyBottomY = 0.65; // 箭身下边 Y
  static const double _tailX = 0.18; // 尾部 X

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    // 使用圆形碰撞箱
    // 因为父组件是topLeft，碰撞箱也应该居中放置
    final radius = size.x / 2;
    add(
      CircleHitbox(
        radius: radius,
        position: Vector2(radius, radius),
        anchor: Anchor.center,
      ),
    );
  }

  @override
  void render(ui.Canvas canvas) {
    final double s = size.x; // 正方形尺寸
    final double radius = s / 2;
    final center = ui.Offset(radius, radius);

    // 1. 绘制圆形背景
    final bgFillPaint = ui.Paint()
      ..color = _backgroundFillColor
      ..style = ui.PaintingStyle.fill;

    final bgStrokePaint = ui.Paint()
      ..color = _backgroundStrokeColor
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = 3.0;

    canvas.drawCircle(center, radius - 2, bgFillPaint);
    canvas.drawCircle(center, radius - 2, bgStrokePaint);

    // 2. 绘制箭头（使用 color 属性，红队红色，蓝队蓝色）
    // 应用旋转变换
    canvas.save();
    canvas.translate(radius, radius);
    canvas.rotate(_rotation);
    canvas.translate(-radius, -radius);

    final arrowPaint = ui.Paint()
      ..color = color
      ..style = ui.PaintingStyle.fill;

    // 绘制粗壮的箭头形状
    final path = ui.Path()
      ..moveTo(s * _tipX, s * _tipY) // 尖端
      ..lineTo(s * _arrowBaseX, s * _arrowTopY) // 箭头上角
      ..lineTo(s * _arrowBaseX, s * _bodyTopY) // 箭身上
      ..lineTo(s * _tailX, s * _bodyTopY) // 箭身左上
      ..lineTo(s * _tailX, s * _bodyBottomY) // 箭身左下
      ..lineTo(s * _arrowBaseX, s * _bodyBottomY) // 箭身下
      ..lineTo(s * _arrowBaseX, s * _arrowBottomY) // 箭头下角
      ..close();

    canvas.drawPath(path, arrowPaint);
    canvas.restore();
  }

  /// 更新箭头方向（旋转组件）
  void updateDirection(Vector2 direction) {
    if (direction.length > 0.1) {
      // 旋转中心默认为anchor，对于PositionComponent，旋转是围绕anchor点的。
      // 但是我们希望围绕中心旋转。
      // 当anchor为topLeft时，旋转中心是左上角。
      // 我们可以设置 angle，但如果 anchor 是 topLeft，旋转会围绕左上角，导致组件位置偏移。
      // 为了围绕中心旋转，我们需要设置 anchor 为 center，或者手动调整位置。
      // 或者：既然我们已经将 anchor 改为 topLeft，我们需要一种方式让旋转看起来是围绕中心的。
      // 实际上，Flame 的 angle 属性是围绕 anchor 旋转的。
      // 如果我们希望物理位置是 topLeft，但旋转围绕中心，这有点矛盾。

      // 修正：对于需要旋转的组件，如果 anchor 设为 topLeft，旋转确实会很怪。
      // 但是 PlayerComponent 也是 topLeft，它的旋转是怎么处理的？
      // PlayerComponent 并没有设置 angle，它是让 _arrowIcon 旋转。
      // 如果 _arrowIcon 是 topLeft，它旋转会围绕左上角。
      // 这会导致箭头在玩家身上“摆动”，而不是原地自转。

      // 解决方案：
      // 保持 _arrowIcon 的 anchor 为 center。
      // 但是为了统一性，我们在 PlayerComponent 中放置它时，需要将它的位置设为中心。
      // PlayerComponent (topLeft) 的中心在 (radius, radius)。
      // 所以 _arrowIcon (center) 的位置应该是 (radius, radius)。

      // 等等，之前的代码中 _arrowIcon 没有设置位置，且 anchor 为 center。
      // 如果父组件是 topLeft，父组件的 (0,0) 是左上角。
      // _arrowIcon 在 (0,0) 处 anchor 为 center，意味着它的中心在父组件的左上角。
      // 这说明之前的代码逻辑可能就是依赖某些默认行为，或者显示其实是偏的。

      // 让我们回看 PlayerComponent.dart
      // add(_arrowIcon!); 没有设置 position。
      // 如果 PlayerComponent 是 topLeft， _arrowIcon 在 (0,0)。
      // 如果 _arrowIcon 是 center，它的中心在 (0,0)，也就是玩家的左上角。
      // 这样显示肯定是不对的。

      // 我之前的推断：PlayerComponent 之前可能是 anchor: Anchor.center。
      // 检查之前的 git diff 或历史？ 不用了，现在的任务是修复。

      // 如果我把 ArrowComponent 改回 anchor: Anchor.center。
      // 并在 PlayerComponent 中设置它的位置为 playerRadius, playerRadius。
      // 这样既满足了统一使用 topLeft (对于 PlayerComponent)，又解决了旋转问题。
      // 或者，我可以在 ArrowComponent 中使用 anchor: Anchor.center，并在构造函数中处理位置偏移？
      // 不，子组件的位置是相对于父组件的。

      // 更好的做法：
      // ArrowComponent 保持 Anchor.center，以便旋转。
      // 在 PlayerComponent 中，将 ArrowComponent 的位置设置为 Vector2(radius, radius)。

      // 但是用户要求“所有组件的anchor属性都被设置为了Anchor.topLeft”。
      // 如果我必须设为 topLeft，那么旋转时我需要做什么？
      // 可以在 render 时变换 canvas。

      // 让我们看看 render 方法：
      // render 方法使用了 size 和 center 变量，并不依赖 anchor。
      // 但是 updateDirection 使用了 `angle = ...`。
      // 设置 angle 会影响 render 时的变换矩阵。
      // 如果 anchor 是 topLeft，变换矩阵会围绕左上角旋转。

      // 结论：对于需要旋转的组件，强制使用 Anchor.topLeft 会导致旋转中心问题。
      // 除非我们在外层再包一个容器，或者在 render 里自己处理旋转。

      // 鉴于用户明确要求“调整到 Anchor.topLeft”，我应该照做，并修复旋转带来的副作用。
      // 修复方法：
      // 不使用 `angle` 属性。
      // 而是增加一个 `_rotation` 变量。
      // 在 `render` 方法中：
      // canvas.save();
      // canvas.translate(center.x, center.y);
      // canvas.rotate(_rotation);
      // canvas.translate(-center.x, -center.y);
      // ... 绘制代码 ...
      // canvas.restore();

      _rotation = math.atan2(direction.y, direction.x);
    }
  }

  double _rotation = 0;
}
