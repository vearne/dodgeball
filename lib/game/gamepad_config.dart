import 'package:flame/components.dart';
import 'package:flutter/services.dart';

/// 手柄配置和输入处理
class GamepadConfig {
  final int playerId;
  
  // 手柄死区（避免摇杆漂移）
  static const double deadZone = 0.2;
  
  GamepadConfig({required this.playerId});

  /// 处理手柄输入
  /// 返回移动方向和是否投掷
  (Vector2 direction, bool shouldThrow) handleGamepadInput(
    Set<LogicalKeyboardKey> keysPressed,
  ) {
    Vector2 direction = Vector2.zero();
    bool shouldThrow = false;

    // 检查是否有手柄连接（通过检查手柄按键）
    // Flutter的手柄输入会映射到特定的LogicalKeyboardKey
    
    // 玩家1的手柄控制（第一个手柄）
    if (playerId == 0) {
      // 左摇杆方向键（WASD或方向键）
      // 这些可能被手柄映射
      if (keysPressed.contains(LogicalKeyboardKey.arrowUp) ||
          keysPressed.contains(LogicalKeyboardKey.keyW)) {
        direction.y -= 1;
      }
      if (keysPressed.contains(LogicalKeyboardKey.arrowDown) ||
          keysPressed.contains(LogicalKeyboardKey.keyS)) {
        direction.y += 1;
      }
      if (keysPressed.contains(LogicalKeyboardKey.arrowLeft) ||
          keysPressed.contains(LogicalKeyboardKey.keyA)) {
        direction.x -= 1;
      }
      if (keysPressed.contains(LogicalKeyboardKey.arrowRight) ||
          keysPressed.contains(LogicalKeyboardKey.keyD)) {
        direction.x += 1;
      }

      // 手柄按钮（通常映射到空格或Enter）
      if (keysPressed.contains(LogicalKeyboardKey.space) ||
          keysPressed.contains(LogicalKeyboardKey.enter)) {
        shouldThrow = true;
      }
    }
    // 玩家2的手柄控制（第二个手柄）
    else if (playerId == 1) {
      // 使用不同的按键组合
      if (keysPressed.contains(LogicalKeyboardKey.keyI)) {
        direction.y -= 1;
      }
      if (keysPressed.contains(LogicalKeyboardKey.keyK)) {
        direction.y += 1;
      }
      if (keysPressed.contains(LogicalKeyboardKey.keyJ)) {
        direction.x -= 1;
      }
      if (keysPressed.contains(LogicalKeyboardKey.keyL)) {
        direction.x += 1;
      }

      if (keysPressed.contains(LogicalKeyboardKey.digit0)) {
        shouldThrow = true;
      }
    }

    // 应用死区
    if (direction.length < deadZone) {
      direction = Vector2.zero();
    } else {
      direction = direction.normalized();
    }

    return (direction, shouldThrow);
  }

  /// 处理手柄摇杆输入（通过RawGamepadEvent）
  /// 注意：这需要Flutter的RawKeyboardListener或类似机制
  Vector2 handleGamepadStick(double x, double y) {
    final direction = Vector2(x, y);
    
    // 应用死区
    if (direction.length < deadZone) {
      return Vector2.zero();
    }
    
    // 归一化
    return direction.normalized();
  }
}

