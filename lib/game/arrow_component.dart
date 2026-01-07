import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

/// 箭头组件：负责渲染箭头、承载王冠/文字，并提供与箭头形状一致的碰撞体
/// 箭头设计为紧凑形状，完全在碰撞框内部，无论旋转角度如何都不会超出边界
class ArrowComponent extends PositionComponent with CollisionCallbacks {
  ArrowComponent({required double sideLength, required this.color})
    : super(size: Vector2.all(sideLength), anchor: Anchor.center);

  ui.Color color;

  // 紧凑的箭头形状参数（相对于组件大小，0.5 为中心）
  // 所有点距离中心不超过 0.35（即 32*0.35=11.2 像素），确保旋转后不超出边界
  // 箭头边界：中心(0.5, 0.5)，范围 [0.15, 0.85] x [0.25, 0.75]
  static const double _tipX = 0.78;       // 尖端 X（距中心 0.28）
  static const double _tipY = 0.50;       // 尖端 Y（中心）
  static const double _arrowBaseX = 0.55; // 箭头三角形底边 X
  static const double _arrowTopY = 0.28;  // 箭头三角形顶部 Y（距中心 0.22）
  static const double _arrowBottomY = 0.72; // 箭头三角形底部 Y
  static const double _bodyTopY = 0.38;   // 箭身上边 Y
  static const double _bodyBottomY = 0.62; // 箭身下边 Y
  static const double _tailX = 0.22;      // 尾部 X（距中心 0.28）

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    // 使用矩形碰撞箱
    add(RectangleHitbox());
  }

  @override
  void render(ui.Canvas canvas) {
    final double s = size.x; // 正方形尺寸

    final paint = ui.Paint()
      ..color = color
      ..style = ui.PaintingStyle.fill;

    final strokePaint = ui.Paint()
      ..color = const ui.Color.fromARGB(255, 0, 0, 0)
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = 2.0;

    // 绘制紧凑的箭头形状
    final path = ui.Path()
      ..moveTo(s * _tipX, s * _tipY)             // 尖端
      ..lineTo(s * _arrowBaseX, s * _arrowTopY)  // 箭头上角
      ..lineTo(s * _arrowBaseX, s * _bodyTopY)   // 箭身上
      ..lineTo(s * _tailX, s * _bodyTopY)        // 箭身左上
      ..lineTo(s * _tailX, s * _bodyBottomY)     // 箭身左下
      ..lineTo(s * _arrowBaseX, s * _bodyBottomY) // 箭身下
      ..lineTo(s * _arrowBaseX, s * _arrowBottomY) // 箭头下角
      ..close();

    canvas.drawPath(path, paint);
    canvas.drawPath(path, strokePaint);
  }

  /// 更新箭头方向（旋转组件）
  void updateDirection(Vector2 direction) {
    if (direction.length > 0.1) {
      angle = math.atan2(direction.y, direction.x);
    }
  }
}
