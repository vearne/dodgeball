import 'dart:ui' as ui;
import 'dart:math' as math;

import 'package:flame/components.dart';

/// 箭头组件，用于表示玩家和移动方向
class ArrowComponent extends Component {
  ArrowComponent({
    required this.size,
    required this.color,
    this.angle = 0.0, // 箭头角度（弧度）
  });

  final double size;
  ui.Color color;
  double angle;

  @override
  void render(ui.Canvas canvas) {
    final paint = ui.Paint()
      ..color = color
      ..style = ui.PaintingStyle.fill;

    final strokePaint = ui.Paint()
      ..color = ui.Color.fromARGB(255, 0, 0, 0)
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.save();

    // 旋转画布到指定角度
    canvas.translate(size / 2, size / 2);
    canvas.rotate(angle);
    canvas.translate(-size / 2, -size / 2);

    // 绘制箭头形状
    final path = ui.Path();

    // 箭头尖端
    path.moveTo(size * 0.9, size * 0.5);

    // 箭头上边
    path.lineTo(size * 0.6, size * 0.2);

    // 箭头主体上边
    path.lineTo(size * 0.6, size * 0.35);
    path.lineTo(size * 0.1, size * 0.35);

    // 箭头主体下边
    path.lineTo(size * 0.1, size * 0.65);
    path.lineTo(size * 0.6, size * 0.65);

    // 箭头下边
    path.lineTo(size * 0.6, size * 0.8);

    // 回到箭头尖端
    path.close();

    // 绘制填充
    canvas.drawPath(path, paint);

    // 绘制边框
    canvas.drawPath(path, strokePaint);

    canvas.restore();
  }

  /// 更新箭头方向
  void updateDirection(Vector2 direction) {
    if (direction.length > 0.1) {
      angle = math.atan2(direction.y, direction.x);
    }
  }
}
