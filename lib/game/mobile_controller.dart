import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';
import 'virtual_joystick.dart';
import 'throw_button.dart';

/// 移动设备控制器
class MobileController extends PositionComponent {
  MobileController({
    required Vector2 gameSize,
    required this.onMove,
    required this.onThrow,
  }) : super(position: Vector2.zero(), size: gameSize);

  final Function(Vector2 direction) onMove;
  final VoidCallback onThrow;

  // 控制组件
  VirtualJoystick? _joystick;
  ThrowButton? _throwButton;

  // 控制区域大小
  static const double _joystickSize = 120.0;
  static const double _buttonSize = 80.0;
  static const double _margin = 20.0;

  @override
  Future<void> onLoad() async {
    super.onLoad();

    // 创建虚拟摇杆（左下角）
    _joystick = VirtualJoystick(
      onDirectionChanged: onMove,
      size: Vector2.all(_joystickSize),
      position: Vector2(_margin, size.y - _joystickSize - _margin),
    );
    add(_joystick!);

    // 创建发射按钮（右下角）
    _throwButton = ThrowButton(
      onThrow: onThrow,
      size: Vector2.all(_buttonSize),
      position: Vector2(
        size.x - _buttonSize - _margin,
        size.y - _buttonSize - _margin,
      ),
    );
    add(_throwButton!);
  }

  /// 设置发射按钮状态
  void setThrowButtonEnabled(bool enabled) {
    _throwButton?.setEnabled(enabled);
  }

  /// 检查是否为移动设备
  static bool get isMobileDevice {
    return defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.android;
  }

  /// 获取摇杆当前方向
  Vector2? get joystickDirection => _joystick?.currentDirection;

  /// 摇杆是否激活
  bool get isJoystickActive => _joystick?.isActive ?? false;
}
