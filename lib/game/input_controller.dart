import 'package:flame/components.dart';
import 'package:flutter/services.dart';
import 'keyboard_config.dart';
import 'gamepad_config.dart';

/// 输入控制器，处理键盘和手柄输入
class InputController extends Component {
  InputController({
    required this.onMove,
    required this.onThrow,
    this.playerId = 0,
    KeyboardConfig? keyboardConfig,
    GamepadConfig? gamepadConfig,
  })  : _keyboardConfig = keyboardConfig ?? KeyboardConfig.getDefault(playerId),
        _gamepadConfig = gamepadConfig ?? GamepadConfig(playerId: playerId);

  final Function(Vector2 direction) onMove;
  final Function(Vector2 direction) onThrow;
  final int playerId;
  KeyboardConfig _keyboardConfig;
  final GamepadConfig _gamepadConfig;

  // 键盘状态
  final Set<LogicalKeyboardKey> _pressedKeys = <LogicalKeyboardKey>{};

  // 移动状态
  Vector2 _movementInput = Vector2.zero();

  // 定时器
  TimerComponent? _inputUpdateTimer;

  // 手柄输入状态
  Vector2 _gamepadStickInput = Vector2.zero();
  bool _gamepadThrowPressed = false;

  @override
  Future<void> onLoad() async {
    super.onLoad();
    _inputUpdateTimer = TimerComponent(
      period: 0.016, // ~60fps
      repeat: true,
      onTick: _updateInput,
    );
    add(_inputUpdateTimer!);
  }

  @override
  void onRemove() {
    _inputUpdateTimer?.removeFromParent();
    super.onRemove();
  }

  /// 处理键盘输入事件
  void handleKeyEvent(Set<LogicalKeyboardKey> keysPressed) {
    // 更新按键状态
    _pressedKeys.clear();
    _pressedKeys.addAll(keysPressed);
  }

  /// 设置键盘配置
  void setKeyboardConfig(KeyboardConfig config) {
    _keyboardConfig = config;
  }

  /// 获取键盘配置
  KeyboardConfig get keyboardConfig => _keyboardConfig;

  /// 处理手柄摇杆输入
  void handleGamepadStick(Vector2 direction) {
    _gamepadStickInput = direction;
  }

  /// 处理手柄按钮输入
  void handleGamepadButton(bool pressed) {
    _gamepadThrowPressed = pressed;
  }

  /// 处理移动设备输入
  void handleMobileInput(Vector2 direction) {
    _movementInput = direction;
  }

  /// 处理移动设备投掷
  void handleMobileThrow() {
    if (_movementInput.length > 0.1) {
      onThrow(_movementInput.normalized());
    } else {
      // 如果没有移动，默认向右投掷
      onThrow(Vector2(1, 0));
    }
  }

  /// 更新输入状态
  void _updateInput() {
    _updateKeyboardInput();
    _updateGamepadInput();
    _updateMovement();
  }

  /// 更新键盘输入
  void _updateKeyboardInput() {
    _movementInput = Vector2.zero();

    // 使用配置的按键
    if (_pressedKeys.contains(_keyboardConfig.up)) {
      _movementInput.y -= 1;
    }
    if (_pressedKeys.contains(_keyboardConfig.down)) {
      _movementInput.y += 1;
    }
    if (_pressedKeys.contains(_keyboardConfig.left)) {
      _movementInput.x -= 1;
    }
    if (_pressedKeys.contains(_keyboardConfig.right)) {
      _movementInput.x += 1;
    }

    // 投掷键（使用当前移动方向）
    if (_pressedKeys.contains(_keyboardConfig.throwKey)) {
      if (_movementInput.length > 0.1) {
        onThrow(_movementInput.normalized());
      } else {
        // 如果没有移动，默认向右投掷
        onThrow(Vector2(1, 0));
      }
      _pressedKeys.remove(_keyboardConfig.throwKey); // 防止连续投掷
    }
  }

  /// 更新手柄输入
  void _updateGamepadInput() {
    // 如果手柄有输入，优先使用手柄
    if (_gamepadStickInput.length > 0.1) {
      _movementInput = _gamepadStickInput;
    }

    // 手柄投掷按钮
    if (_gamepadThrowPressed) {
      if (_movementInput.length > 0.1) {
        onThrow(_movementInput.normalized());
      } else {
        onThrow(Vector2(1, 0));
      }
      _gamepadThrowPressed = false; // 防止连续投掷
    }

    // 同时处理手柄按键映射（通过键盘事件）
    final (gamepadDirection, gamepadThrow) = _gamepadConfig.handleGamepadInput(_pressedKeys);
    if (gamepadDirection.length > 0.1) {
      _movementInput = gamepadDirection;
    }
    if (gamepadThrow) {
      if (_movementInput.length > 0.1) {
        onThrow(_movementInput.normalized());
      } else {
        onThrow(Vector2(1, 0));
      }
    }
  }

  /// 更新移动
  void _updateMovement() {
    // 应用死区
    const deadZone = 0.1;

    if (_movementInput.length > deadZone) {
      onMove(_movementInput.normalized());
    }
  }

  /// 获取当前移动方向（用于UI显示）
  Vector2 get currentMovement => _movementInput.length > 0.1
      ? _movementInput.normalized()
      : Vector2.zero();
}
