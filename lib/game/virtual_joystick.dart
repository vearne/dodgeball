import 'package:flutter/material.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';

/// 虚拟摇杆组件
class VirtualJoystick extends PositionComponent with TapCallbacks {
  VirtualJoystick({
    required this.onDirectionChanged,
    required Vector2 size,
    required Vector2 position,
    this.deadZone = 0.1,
    this.maxDistance = 50.0,
  }) : super(
         position: position,
         size: size,
       );

  final Function(Vector2 direction) onDirectionChanged;
  final double deadZone;
  final double maxDistance;

  // 摇杆状态
  bool _isDragging = false;
  Vector2 _joystickCenter = Vector2.zero();
  Vector2 _currentDirection = Vector2.zero();
  Vector2 _joystickPosition = Vector2.zero();
  Vector2? _lastTouchPosition;

  // 渲染相关
  late Paint _outerCirclePaint;
  late Paint _innerCirclePaint;
  late Paint _borderPaint;

  @override
  Future<void> onLoad() async {
    super.onLoad();
    
    // 初始化画笔
    _outerCirclePaint = Paint()
      ..color = Colors.blue.withOpacity(0.3)
      ..style = PaintingStyle.fill;

    _innerCirclePaint = Paint()
      ..color = Colors.blue.withOpacity(0.8)
      ..style = PaintingStyle.fill;

    _borderPaint = Paint()
      ..color = Colors.blue.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    // 设置摇杆中心位置
    _joystickCenter = size / 2;
    _joystickPosition = _joystickCenter;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // 绘制外圈（固定）
    canvas.drawCircle(
      Offset(_joystickCenter.x, _joystickCenter.y),
      maxDistance,
      _outerCirclePaint,
    );
    canvas.drawCircle(
      Offset(_joystickCenter.x, _joystickCenter.y),
      maxDistance,
      _borderPaint,
    );

    // 绘制内圈（可移动）
    canvas.drawCircle(
      Offset(_joystickPosition.x, _joystickPosition.y),
      20.0,
      _innerCirclePaint,
    );
    canvas.drawCircle(
      Offset(_joystickPosition.x, _joystickPosition.y),
      20.0,
      _borderPaint,
    );
  }

  @override
  bool onTapDown(TapDownEvent event) {
    _isDragging = true;
    _lastTouchPosition = event.localPosition;
    _updateJoystickPosition(event.localPosition);
    return true;
  }

  @override
  bool onTapUp(TapUpEvent event) {
    _isDragging = false;
    _resetJoystick();
    return true;
  }

  @override
  bool onTapCancel(TapCancelEvent event) {
    _isDragging = false;
    _resetJoystick();
    return true;
  }

  @override
  void update(double dt) {
    super.update(dt);
    
    // 如果正在拖拽，更新摇杆位置
    if (_isDragging && _lastTouchPosition != null) {
      _updateJoystickPosition(_lastTouchPosition!);
    }
  }

  /// 更新摇杆位置
  void _updateJoystickPosition(Vector2 touchPosition) {
    final delta = touchPosition - _joystickCenter;
    final distance = delta.length;

    if (distance > maxDistance) {
      // 限制在最大距离内
      _joystickPosition = _joystickCenter + delta.normalized() * maxDistance;
    } else {
      _joystickPosition = touchPosition;
    }

    // 计算方向
    _currentDirection = (_joystickPosition - _joystickCenter).normalized();

    // 应用死区
    if (distance < deadZone * maxDistance) {
      _currentDirection = Vector2.zero();
    }

    // 通知方向变化
    onDirectionChanged(_currentDirection);
  }

  /// 重置摇杆
  void _resetJoystick() {
    _joystickPosition = _joystickCenter;
    _currentDirection = Vector2.zero();
    _lastTouchPosition = null;
    onDirectionChanged(_currentDirection);
  }

  /// 获取当前方向
  Vector2 get currentDirection => _currentDirection;

  /// 是否正在使用
  bool get isActive => _isDragging;
}
