import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

/// 箭头组件：负责渲染箭头、承载王冠/文字，并提供与箭头形状一致的碰撞体
class ArrowComponent extends PositionComponent with CollisionCallbacks {
  ArrowComponent({required double sideLength, required this.color})
    : super(size: Vector2.all(sideLength), anchor: Anchor.center);

  ui.Color color;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    // 使用两个凸多边形近似箭头：一个矩形（箭身）+ 一个三角形（箭头）
    // 调整碰撞体大小，提高碰撞检测精度
    add(
      PolygonHitbox.relative([
        Vector2(0.15, 0.30), // 稍微扩大碰撞区域
        Vector2(0.65, 0.30),
        Vector2(0.65, 0.70),
        Vector2(0.15, 0.70),
      ], parentSize: size),
    );

    add(
      PolygonHitbox.relative([
        Vector2(0.65, 0.15), // 扩大箭头部分碰撞区域
        Vector2(0.95, 0.50),
        Vector2(0.65, 0.85),
      ], parentSize: size),
    );
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

    // 绘制箭头形状（本地坐标，旋转由组件的 angle 控制）
    final path = ui.Path()
      ..moveTo(s * 0.9, s * 0.5)
      ..lineTo(s * 0.6, s * 0.2)
      ..lineTo(s * 0.6, s * 0.35)
      ..lineTo(s * 0.1, s * 0.35)
      ..lineTo(s * 0.1, s * 0.65)
      ..lineTo(s * 0.6, s * 0.65)
      ..lineTo(s * 0.6, s * 0.8)
      ..close();

    canvas.drawPath(path, paint);
    canvas.drawPath(path, strokePaint);
  }

  /// 更新箭头方向（旋转组件，使碰撞体与渲染一致）
  void updateDirection(Vector2 direction) {
    if (direction.length > 0.1) {
      angle = math.atan2(direction.y, direction.x);
    }
  }
}
