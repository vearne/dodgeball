import 'dart:ui' as ui;
import 'package:flame/components.dart';

/// 王冠组件，用于标识人类玩家
class CrownComponent extends Component {
  CrownComponent({required this.size, this.color = const ui.Color(0xFFFFD700)});
  
  final double size;
  final ui.Color color;
  
  @override
  void render(ui.Canvas canvas) {
    final paint = ui.Paint()
      ..color = color
      ..style = ui.PaintingStyle.fill;
    
    final strokePaint = ui.Paint()
      ..color = const ui.Color(0xFFFFAA00)
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = 1.0;
    
    // 绘制王冠路径
    final path = ui.Path();
    
    // 王冠底部
    final baseY = size * 0.7;
    final baseWidth = size * 0.8;
    final centerX = 0.0;
    
    path.moveTo(centerX - baseWidth / 2, baseY);
    path.lineTo(centerX + baseWidth / 2, baseY);
    
    // 王冠的三个尖角
    final peak1X = centerX - baseWidth / 3;
    final peak2X = centerX;
    final peak3X = centerX + baseWidth / 3;
    final peak1Y = -size * 0.3;
    final peak2Y = -size * 0.5; // 中间最高
    final peak3Y = -size * 0.3;
    
    // 绘制王冠轮廓
    path.lineTo(centerX + baseWidth / 2, baseY - size * 0.1);
    path.lineTo(peak3X, peak3Y);
    path.lineTo(peak2X, peak2Y);
    path.lineTo(peak1X, peak1Y);
    path.lineTo(centerX - baseWidth / 2, baseY - size * 0.1);
    path.close();
    
    // 填充王冠
    canvas.drawPath(path, paint);
    
    // 绘制边框
    canvas.drawPath(path, strokePaint);
    
    // 添加装饰点（宝石）
    final gemPaint = ui.Paint()
      ..color = const ui.Color(0xFFFF4444)
      ..style = ui.PaintingStyle.fill;
    
    // 在三个尖角添加红色宝石（缩小尺寸）
    canvas.drawCircle(ui.Offset(peak1X, peak1Y), size * 0.03, gemPaint);
    canvas.drawCircle(ui.Offset(peak2X, peak2Y), size * 0.04, gemPaint);
    canvas.drawCircle(ui.Offset(peak3X, peak3Y), size * 0.03, gemPaint);
  }
}
