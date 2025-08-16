import 'package:flame/components.dart';
import 'package:flutter/services.dart';

/// 输入控制器，处理键盘和手柄输入
class InputController extends Component {
  InputController({
    required this.onMove,
    required this.onThrow,
    this.playerId = 0,
  });

  final Function(Vector2 direction) onMove;
  final Function(Vector2 direction) onThrow;
  final int playerId;

  // 键盘状态
  final Set<LogicalKeyboardKey> _pressedKeys = <LogicalKeyboardKey>{};

  // 移动状态
  Vector2 _movementInput = Vector2.zero();

  // 定时器
  TimerComponent? _inputUpdateTimer;

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
    _updateMovement();
  }

  /// 更新键盘输入
  void _updateKeyboardInput() {
    // 玩家1控制 (WASD + 空格投掷)
    if (playerId == 0) {
      _movementInput = Vector2.zero();

      // WASD 移动
      if (_pressedKeys.contains(LogicalKeyboardKey.keyW)) {
        _movementInput.y -= 1;
      }
      if (_pressedKeys.contains(LogicalKeyboardKey.keyS)) {
        _movementInput.y += 1;
      }
      if (_pressedKeys.contains(LogicalKeyboardKey.keyA)) {
        _movementInput.x -= 1;
      }
      if (_pressedKeys.contains(LogicalKeyboardKey.keyD)) {
        _movementInput.x += 1;
      }

      // 空格键投掷（使用当前移动方向）
      if (_pressedKeys.contains(LogicalKeyboardKey.space)) {
        if (_movementInput.length > 0.1) {
          onThrow(_movementInput.normalized());
        } else {
          // 如果没有移动，默认向右投掷
          onThrow(Vector2(1, 0));
        }
        _pressedKeys.remove(LogicalKeyboardKey.space); // 防止连续投掷
      }
    }
    // 玩家2控制 (IJKL + 数字0投掷)
    else if (playerId == 1) {
      _movementInput = Vector2.zero();

      // IJKL 移动
      if (_pressedKeys.contains(LogicalKeyboardKey.keyI)) {
        _movementInput.y -= 1;
      }
      if (_pressedKeys.contains(LogicalKeyboardKey.keyK)) {
        _movementInput.y += 1;
      }
      if (_pressedKeys.contains(LogicalKeyboardKey.keyJ)) {
        _movementInput.x -= 1;
      }
      if (_pressedKeys.contains(LogicalKeyboardKey.keyL)) {
        _movementInput.x += 1;
      }

      // 数字0投掷（使用当前移动方向）
      if (_pressedKeys.contains(LogicalKeyboardKey.digit0)) {
        if (_movementInput.length > 0.1) {
          onThrow(_movementInput.normalized());
        } else {
          // 如果没有移动，默认向右投掷
          onThrow(Vector2(1, 0));
        }
        _pressedKeys.remove(LogicalKeyboardKey.digit0);
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
