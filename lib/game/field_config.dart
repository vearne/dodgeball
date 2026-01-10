import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// 游戏场地配置
class FieldConfig {
  static const double gridSize = 30.0; // 网格大小（原子障碍物大小：30px*30px）
  // 墙壁厚度：60px
  // 游戏区域：1380 x 720，可玩区域：1260 x 600（都是30的倍数）
  // 完全对称且网格对齐方案：
  // 左右空白：各 60px（2个网格）
  // 队伍区域：各 540px 宽×高（18个网格）
  // 中间间隔：60px（2个网格）
  // 验证：60 + 540 + 60 + 540 + 60 = 1260 ✓
  // 红队：120 → 660（540px），蓝队：720 → 1260（540px）
  // 中心点：(120+1260)/2 = 690，完全对称
  // 上下空白：各 30px（1个网格），队伍区域垂直范围：90 → 630（540px）
  static const double wallThickness = 60.0;
  static const double playAreaMargin = 0.0; // 玩家活动区域与墙壁的间距
  static const double centerGap = 60.0; // 红蓝区域之间的间隔（60px = 2个30px网格）

  // 场地颜色
  static const Color redTeamAreaColor = Color(0x30E53935); // 半透明红色
  static const Color blueTeamAreaColor = Color(0x301E88E5); // 半透明蓝色
  static const Color wallColor = Color(0xFF000000); // 黑色墙壁
  static const Color fieldBackgroundColor = Color(0xFFD0D0D0); // 中灰色背景

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

    // 团队区域宽度：540px（18个网格）
    final teamWidth = 18 * gridSize;

    // 团队区域高度：540px（18个网格）
    final teamHeight = 18 * gridSize;

    // 红队区域左边界 = 可玩区域左边界 + 左侧空白（60px）
    final redAreaLeft = playableArea.left + 2 * gridSize;

    // 红队区域上边界 = 可玩区域上边界 + 上侧空白（30px）
    final redAreaTop = playableArea.top + 1 * gridSize;

    return Rect.fromLTWH(redAreaLeft, redAreaTop, teamWidth, teamHeight);
  }

  /// 获取蓝队区域（右半边，有中间间隔）
  static Rect getBluTeamArea(Vector2 gameSize) {
    // 先获取红队区域，确保高度一致
    final redArea = getRedTeamArea(gameSize);
    final teamWidth = redArea.width;
    final teamHeight = redArea.height;

    final playableArea = getPlayableArea(gameSize);

    // 蓝队区域左边界 = 可玩区域右边界 - 右侧空白（60px） - 队伍宽度（540px）
    final blueAreaLeft = playableArea.right - 2 * gridSize - teamWidth;

    // 蓝队区域上边界 = 可玩区域上边界 + 上侧空白（30px）
    final blueAreaTop = playableArea.top + 1 * gridSize;

    return Rect.fromLTWH(blueAreaLeft, blueAreaTop, teamWidth, teamHeight);
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
  static bool isInRedTeamArea(
    Vector2 position,
    Vector2 gameSize, {
    double playerRadius = 0.0,
  }) {
    final area = getRedTeamArea(gameSize);
    // 考虑玩家半径，确保玩家完全在区域内
    final result =
        position.x >= area.left + playerRadius &&
        position.x <= area.right - playerRadius &&
        position.y >= area.top + playerRadius &&
        position.y <= area.bottom - playerRadius;
    return result;
  }

  /// 检查位置是否在蓝队初始区域内（仅用于生成位置）
  static bool isInBlueTeamArea(
    Vector2 position,
    Vector2 gameSize, {
    double playerRadius = 0.0,
  }) {
    final area = getBluTeamArea(gameSize);
    // 考虑玩家半径，确保玩家完全在区域内
    return position.x >= area.left + playerRadius &&
        position.x <= area.right - playerRadius &&
        position.y >= area.top + playerRadius &&
        position.y <= area.bottom - playerRadius;
  }

  /// 获取玩家在指定队伍区域内的有效位置
  static Vector2 clampToTeamArea(
    Vector2 position,
    bool isRedTeam,
    Vector2 gameSize, {
    double playerRadius = 0.0,
  }) {
    final area = isRedTeam
        ? getRedTeamArea(gameSize)
        : getBluTeamArea(gameSize);

    // 考虑玩家半径，确保玩家完全在区域内
    final clampedX = position.x.clamp(
      area.left + playerRadius,
      area.right - playerRadius,
    );
    final clampedY = position.y.clamp(
      area.top + playerRadius,
      area.bottom - playerRadius,
    );

    return Vector2(clampedX, clampedY);
  }
}
