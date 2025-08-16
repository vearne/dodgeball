import 'package:flutter/material.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'dart:math' as math;

/// 发射按钮组件
class ThrowButton extends PositionComponent with TapCallbacks {
  ThrowButton({
    required this.onThrow,
    required Vector2 size,
    required Vector2 position,
    bool enabled = true,
  }) : super(position: position, size: size) {
    _enabled = enabled;
  }

  final VoidCallback onThrow;
  bool _enabled = true;

  // 渲染相关
  late Paint _buttonPaint;
  late Paint _borderPaint;
  late Paint _disabledPaint;

  @override
  Future<void> onLoad() async {
    super.onLoad();

    // 初始化画笔
    _buttonPaint = Paint()
      ..color = Colors.red.withOpacity(0.8)
      ..style = PaintingStyle.fill;

    _borderPaint = Paint()
      ..color = Colors.red.withOpacity(0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    _disabledPaint = Paint()
      ..color = Colors.grey.withOpacity(0.5)
      ..style = PaintingStyle.fill;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final center = Offset(size.x / 2, size.y / 2);
    final radius = math.min(size.x, size.y) / 2 - 5;

    // 绘制按钮背景
    if (_enabled) {
      canvas.drawCircle(center, radius, _buttonPaint);
      canvas.drawCircle(center, radius, _borderPaint);
    } else {
      canvas.drawCircle(center, radius, _disabledPaint);
    }

    // 绘制发射图标
    final iconPaint = Paint()
      ..color = _enabled ? Colors.white : Colors.grey
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0;

    // 绘制箭头图标
    final arrowSize = radius * 0.6;
    final arrowPath = Path()
      ..moveTo(center.dx - arrowSize, center.dy)
      ..lineTo(center.dx + arrowSize, center.dy)
      ..moveTo(center.dx + arrowSize * 0.7, center.dy - arrowSize * 0.3)
      ..lineTo(center.dx + arrowSize, center.dy)
      ..lineTo(center.dx + arrowSize * 0.7, center.dy + arrowSize * 0.3);

    canvas.drawPath(arrowPath, iconPaint);
  }

  @override
  bool onTapDown(TapDownEvent event) {
    if (_enabled) {
      onThrow();
    }
    return true;
  }

  /// 设置启用状态
  void setEnabled(bool enabled) {
    _enabled = enabled;
  }

  /// 获取启用状态
  bool get enabled => _enabled;
}
