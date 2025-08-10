import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// 游戏场地配置
class FieldConfig {
  static const double wallThickness = 20.0;
  static const double playAreaMargin = 30.0; // 玩家活动区域与墙壁的间距
  static const double centerGap = 40.0; // 红蓝区域之间的间隔
  
  // 场地颜色
  static const Color redTeamAreaColor = Color(0x30E53935);  // 半透明红色
  static const Color blueTeamAreaColor = Color(0x301E88E5); // 半透明蓝色
  static const Color wallColor = Color(0xFF424242);         // 深灰色墙壁
  static const Color fieldBackgroundColor = Color(0xFFF5F5F5); // 浅灰色背景
  
  /// 获取整个可玩区域（被墙壁包围的内部区域）
  static Rect getPlayableArea(Vector2 gameSize) {
    return Rect.fromLTWH(
      wallThickness,
      wallThickness,
      gameSize.x - wallThickness * 2,
      gameSize.y - wallThickness * 2,
    );
  }
  
  /// 获取红队区域（左半边，有中间间隔）
  static Rect getRedTeamArea(Vector2 gameSize) {
    final playableArea = getPlayableArea(gameSize);
    return Rect.fromLTWH(
      playableArea.left + playAreaMargin,
      playableArea.top + playAreaMargin,
      (playableArea.width - centerGap) / 2 - playAreaMargin,
      playableArea.height - playAreaMargin * 2,
    );
  }
  
  /// 获取蓝队区域（右半边，有中间间隔）
  static Rect getBluTeamArea(Vector2 gameSize) {
    final playableArea = getPlayableArea(gameSize);
    return Rect.fromLTWH(
      playableArea.left + (playableArea.width + centerGap) / 2,
      playableArea.top + playAreaMargin,
      (playableArea.width - centerGap) / 2 - playAreaMargin,
      playableArea.height - playAreaMargin * 2,
    );
  }
  
  /// 检查位置是否在可玩区域内（不撞墙）
  static bool isInPlayableArea(Vector2 position, Vector2 gameSize) {
    final area = getPlayableArea(gameSize);
    return area.contains(Offset(position.x, position.y));
  }
  
  /// 获取玩家在可玩区域内的有效位置
  static Vector2 clampToPlayableArea(Vector2 position, Vector2 gameSize) {
    final area = getPlayableArea(gameSize);
    
    final clampedX = position.x.clamp(area.left, area.right);
    final clampedY = position.y.clamp(area.top, area.bottom);
    
    return Vector2(clampedX, clampedY);
  }
  
  /// 检查位置是否在红队初始区域内（仅用于生成位置）
  static bool isInRedTeamArea(Vector2 position, Vector2 gameSize) {
    final area = getRedTeamArea(gameSize);
    return area.contains(Offset(position.x, position.y));
  }
  
  /// 检查位置是否在蓝队初始区域内（仅用于生成位置）
  static bool isInBlueTeamArea(Vector2 position, Vector2 gameSize) {
    final area = getBluTeamArea(gameSize);
    return area.contains(Offset(position.x, position.y));
  }
  
  /// 获取玩家在指定队伍区域内的有效位置
  static Vector2 clampToTeamArea(Vector2 position, bool isRedTeam, Vector2 gameSize) {
    final area = isRedTeam ? getRedTeamArea(gameSize) : getBluTeamArea(gameSize);
    
    final clampedX = position.x.clamp(area.left, area.right);
    final clampedY = position.y.clamp(area.top, area.bottom);
    
    return Vector2(clampedX, clampedY);
  }
}
