import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'field_config.dart';

/// 场地背景组件
class FieldBackground extends Component {
  FieldBackground({required this.gameSize});

  final Vector2 gameSize;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // 背景
    final background = RectangleComponent(
      size: gameSize,
      paint: Paint()..color = FieldConfig.fieldBackgroundColor,
    );
    add(background);

    // 可玩区域背景（稍微不同的颜色以区分墙壁）
    final playableArea = FieldConfig.getPlayableArea(gameSize);
    final playAreaBackground = RectangleComponent(
      position: Vector2(playableArea.left, playableArea.top),
      size: Vector2(playableArea.width, playableArea.height),
      paint: Paint()..color = const Color(0xFFFFFFFF), // 白色游戏区域
    );
    add(playAreaBackground);

    // 添加红队和蓝队区域标识
    _addTeamAreas();
  }

  void _addTeamAreas() {
    // 红队区域（左半边，带淡色背景）
    final redArea = FieldConfig.getRedTeamArea(gameSize);
    final redBackground = RectangleComponent(
      position: Vector2(redArea.left, redArea.top),
      size: Vector2(redArea.width, redArea.height),
      paint: Paint()..color = FieldConfig.redTeamAreaColor,
    );
    add(redBackground);

    // 蓝队区域（右半边，带淡色背景）
    final blueArea = FieldConfig.getBluTeamArea(gameSize);
    final blueBackground = RectangleComponent(
      position: Vector2(blueArea.left, blueArea.top),
      size: Vector2(blueArea.width, blueArea.height),
      paint: Paint()..color = FieldConfig.blueTeamAreaColor,
    );
    add(blueBackground);
  }
}
