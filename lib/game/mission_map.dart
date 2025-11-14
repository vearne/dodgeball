import 'dart:convert';
import 'package:flutter/services.dart';

/// 地图障碍物类型
enum ObstacleType {
  woodWall, // 木墙：被球击中后消失，球也消失
  rock, // 岩石：被球击中后反弹，不消失
}

/// 障碍物数据
class Obstacle {
  final ObstacleType type;
  final double x;
  final double y;
  final double width;
  final double height;

  const Obstacle({
    required this.type,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  Map<String, dynamic> toJson() => {
    'type': type.name,
    'x': x,
    'y': y,
    'width': width,
    'height': height,
  };

  factory Obstacle.fromJson(Map<String, dynamic> json) => Obstacle(
    type: ObstacleType.values.firstWhere(
      (e) => e.name == json['type'],
      orElse: () => ObstacleType.woodWall,
    ),
    x: (json['x'] as num).toDouble(),
    y: (json['y'] as num).toDouble(),
    width: (json['width'] as num).toDouble(),
    height: (json['height'] as num).toDouble(),
  );
}

/// Mission关卡地图数据
class MissionMap {
  final String id;
  final String name;
  final String description;
  final int enemyCount; // 敌人数量
  final List<Obstacle> obstacles; // 障碍物列表

  const MissionMap({
    required this.id,
    required this.name,
    required this.description,
    required this.enemyCount,
    this.obstacles = const [],
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'enemyCount': enemyCount,
    'obstacles': obstacles.map((o) => o.toJson()).toList(),
  };

  factory MissionMap.fromJson(Map<String, dynamic> json) => MissionMap(
    id: json['id'] as String,
    name: json['name'] as String,
    description: json['description'] as String,
    enemyCount: json['enemyCount'] as int,
    obstacles:
        (json['obstacles'] as List<dynamic>?)
            ?.map((o) => Obstacle.fromJson(o as Map<String, dynamic>))
            .toList() ??
        [],
  );

  /// 创建副本用于编辑
  MissionMap copyWith({
    String? id,
    String? name,
    String? description,
    int? enemyCount,
    List<Obstacle>? obstacles,
  }) {
    return MissionMap(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      enemyCount: enemyCount ?? this.enemyCount,
      obstacles: obstacles ?? this.obstacles,
    );
  }
}

/// 地图管理器：负责加载和保存地图
class MissionMapManager {
  static const String _mapsPath = 'assets/config/mission_maps.json';

  /// 加载所有地图
  static Future<List<MissionMap>> loadMaps() async {
    try {
      final String jsonString = await rootBundle.loadString(_mapsPath);
      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList
          .map((json) => MissionMap.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      // 如果文件不存在，返回空列表
      return [];
    }
  }

  /// 保存地图列表（需要实现文件写入功能）
  static Future<void> saveMaps(List<MissionMap> maps) async {
    // 注意：在Flutter中，assets目录是只读的
    // 实际应用中应该保存到应用数据目录
    // 这里先返回，后续可以改为保存到应用文档目录
    throw UnimplementedError('保存地图功能需要实现文件写入，建议保存到应用文档目录');
  }
}
