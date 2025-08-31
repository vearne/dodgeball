import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import 'field_config.dart';
import 'mobile_controller.dart';
import 'multiplayer_dodgeball_game.dart';

/// MultiplayerDodgeballGame的扩展方法
extension MultiplayerDodgeballGameExtension on MultiplayerDodgeballGame {
  /// 添加外围边界墙壁
  void addBoundaryWalls() {
    final wallThickness = FieldConfig.wallThickness;

    // 顶部墙壁
    final topWall = RectangleComponent(
      position: Vector2(0, 0),
      size: Vector2(size.x, wallThickness),
      paint: Paint()..color = FieldConfig.wallColor,
    );
    add(topWall);

    // 底部墙壁
    final bottomWall = RectangleComponent(
      position: Vector2(0, size.y - wallThickness),
      size: Vector2(size.x, wallThickness),
      paint: Paint()..color = FieldConfig.wallColor,
    );
    add(bottomWall);

    // 左侧墙壁
    final leftWall = RectangleComponent(
      position: Vector2(0, 0),
      size: Vector2(wallThickness, size.y),
      paint: Paint()..color = FieldConfig.wallColor,
    );
    add(leftWall);

    // 右侧墙壁
    final rightWall = RectangleComponent(
      position: Vector2(size.x - wallThickness, 0),
      size: Vector2(wallThickness, size.y),
      paint: Paint()..color = FieldConfig.wallColor,
    );
    add(rightWall);
  }

  /// 添加移动设备控制器
  void addMobileController() {
    final mobileController = MobileController(
      gameSize: size,
      onMove: handleMobileMove,
      onThrow: handleMobileThrow,
    );
    add(mobileController);
  }
}
