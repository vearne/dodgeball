import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

/// 箭头组件：负责渲染箭头、承载王冠/文字，并提供圆形碰撞体
/// 设计为淡紫色圆形背景 + 红色箭头指示方向
class ArrowComponent extends PositionComponent with CollisionCallbacks {
  ArrowComponent({required double sideLength, required this.color})
    : super(size: Vector2.all(sideLength), anchor: Anchor.center);

  ui.Color color;

  // 圆形背景颜色（淡紫色）
  static const ui.Color _backgroundFillColor = ui.Color(0xFFE8D8F0);  // 淡紫色填充
  static const ui.Color _backgroundStrokeColor = ui.Color(0xFFB8A0C8); // 紫色边框

  // 箭头形状参数（相对于组件大小，0.5 为中心）
  // 箭头设计为粗壮的指向箭头，适合在圆形内显示
  static const double _tipX = 0.85;       // 尖端 X
  static const double _tipY = 0.50;       // 尖端 Y（中心）
  static const double _arrowBaseX = 0.50; // 箭头三角形底边 X
  static const double _arrowTopY = 0.20;  // 箭头三角形顶部 Y
  static const double _arrowBottomY = 0.80; // 箭头三角形底部 Y
  static const double _bodyTopY = 0.35;   // 箭身上边 Y
  static const double _bodyBottomY = 0.65; // 箭身下边 Y
  static const double _tailX = 0.18;      // 尾部 X

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    // 使用圆形碰撞箱
    add(CircleHitbox());
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
    final arrowPaint = ui.Paint()
      ..color = color
      ..style = ui.PaintingStyle.fill;

    // 绘制粗壮的箭头形状
    final path = ui.Path()
      ..moveTo(s * _tipX, s * _tipY)             // 尖端
      ..lineTo(s * _arrowBaseX, s * _arrowTopY)  // 箭头上角
      ..lineTo(s * _arrowBaseX, s * _bodyTopY)   // 箭身上
      ..lineTo(s * _tailX, s * _bodyTopY)        // 箭身左上
      ..lineTo(s * _tailX, s * _bodyBottomY)     // 箭身左下
      ..lineTo(s * _arrowBaseX, s * _bodyBottomY) // 箭身下
      ..lineTo(s * _arrowBaseX, s * _arrowBottomY) // 箭头下角
      ..close();

    canvas.drawPath(path, arrowPaint);
  }

  /// 更新箭头方向（旋转组件）
  void updateDirection(Vector2 direction) {
    if (direction.length > 0.1) {
      angle = math.atan2(direction.y, direction.x);
    }
  }
}
