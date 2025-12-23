import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'power_up_component.dart';

/// 地图障碍物类型
enum ObstacleType {
  brickWall, // 砖墙：被球击中后逐渐损坏，最终消失（耐久度3）
  rock, // 岩石：被球击中后反弹，不消失
  // 保留旧的类型以兼容旧地图
  @Deprecated('使用 brickWall 代替')
  woodWall, // 木墙（已废弃）
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
  final List<PowerUpType> allowedPowerUps; // 允许出现的道具类型
  final double powerUpSpawnInterval; // 道具生成间隔（秒）

  const MissionMap({
    required this.id,
    required this.name,
    required this.description,
    required this.enemyCount,
    this.obstacles = const [],
    this.allowedPowerUps = const [], // 默认为空，表示不生成道具
    this.powerUpSpawnInterval = 30.0, // 默认30秒生成一次
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'enemyCount': enemyCount,
    'obstacles': obstacles.map((o) => o.toJson()).toList(),
    'allowedPowerUps': allowedPowerUps.map((p) => p.name).toList(),
    'powerUpSpawnInterval': powerUpSpawnInterval,
  };

  factory MissionMap.fromJson(Map<String, dynamic> json) {
    // 解析道具类型列表
    final allowedPowerUpsList =
        (json['allowedPowerUps'] as List<dynamic>?)
            ?.map((p) {
              try {
                return PowerUpType.values.firstWhere((e) => e.name == p);
              } catch (e) {
                return null;
              }
            })
            .where((p) => p != null)
            .cast<PowerUpType>()
            .toList() ??
        [];

    return MissionMap(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      enemyCount: json['enemyCount'] as int,
      obstacles:
          (json['obstacles'] as List<dynamic>?)
              ?.map((o) => Obstacle.fromJson(o as Map<String, dynamic>))
              .toList() ??
          [],
      allowedPowerUps: allowedPowerUpsList,
      powerUpSpawnInterval:
          (json['powerUpSpawnInterval'] as num?)?.toDouble() ?? 30.0,
    );
  }

  /// 创建副本用于编辑
  MissionMap copyWith({
    String? id,
    String? name,
    String? description,
    int? enemyCount,
    List<Obstacle>? obstacles,
    List<PowerUpType>? allowedPowerUps,
    double? powerUpSpawnInterval,
  }) {
    return MissionMap(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      enemyCount: enemyCount ?? this.enemyCount,
      obstacles: obstacles ?? this.obstacles,
      allowedPowerUps: allowedPowerUps ?? this.allowedPowerUps,
      powerUpSpawnInterval: powerUpSpawnInterval ?? this.powerUpSpawnInterval,
    );
  }
}

/// 地图管理器：负责加载和保存地图
class MissionMapManager {
  static const String _assetMapsPath = 'assets/config/mission_maps.json';
  static const String _customMapsFileName = 'custom_mission_maps.json';

  /// 获取自定义地图文件路径
  static Future<String> _getCustomMapsFilePath() async {
    final directory = await getApplicationDocumentsDirectory();
    return '${directory.path}/$_customMapsFileName';
  }

  /// 加载所有地图（包括内置地图和自定义地图）
  static Future<List<MissionMap>> loadMaps() async {
    final List<MissionMap> allMaps = [];

    // 1. 加载内置地图（从assets）
    try {
      final String jsonString = await rootBundle.loadString(_assetMapsPath);
      final List<dynamic> jsonList = json.decode(jsonString);
      final builtInMaps = jsonList
          .map((json) => MissionMap.fromJson(json as Map<String, dynamic>))
          .toList();
      allMaps.addAll(builtInMaps);
    } catch (e) {
      // 如果内置地图不存在，继续
      print('加载内置地图失败: $e');
    }

    // 2. 加载自定义地图（从文档目录）
    try {
      final customMapsPath = await _getCustomMapsFilePath();
      final file = File(customMapsPath);
      if (await file.exists()) {
        final String jsonString = await file.readAsString();
        final List<dynamic> jsonList = json.decode(jsonString);
        final customMaps = jsonList
            .map((json) => MissionMap.fromJson(json as Map<String, dynamic>))
            .toList();
        allMaps.addAll(customMaps);
      }
    } catch (e) {
      // 如果自定义地图不存在或读取失败，继续
      print('加载自定义地图失败: $e');
    }

    return allMaps;
  }

  /// 加载自定义地图列表
  static Future<List<MissionMap>> loadCustomMaps() async {
    try {
      final customMapsPath = await _getCustomMapsFilePath();
      final file = File(customMapsPath);
      if (await file.exists()) {
        final String jsonString = await file.readAsString();
        final List<dynamic> jsonList = json.decode(jsonString);
        return jsonList
            .map((json) => MissionMap.fromJson(json as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      print('加载自定义地图失败: $e');
    }
    return [];
  }

  /// 保存自定义地图列表到文档目录
  static Future<void> saveCustomMaps(List<MissionMap> maps) async {
    try {
      final customMapsPath = await _getCustomMapsFilePath();
      final file = File(customMapsPath);
      final jsonList = maps.map((map) => map.toJson()).toList();
      final jsonString = json.encode(jsonList);
      await file.writeAsString(jsonString);
      print('成功保存 ${maps.length} 个自定义地图到: $customMapsPath');
    } catch (e) {
      print('保存自定义地图失败: $e');
      rethrow;
    }
  }

  /// 保存单个地图（添加或更新）
  static Future<void> saveMap(MissionMap map) async {
    final customMaps = await loadCustomMaps();

    // 查找是否已存在相同ID的地图
    final existingIndex = customMaps.indexWhere((m) => m.id == map.id);

    if (existingIndex >= 0) {
      // 更新现有地图
      customMaps[existingIndex] = map;
    } else {
      // 添加新地图
      customMaps.add(map);
    }

    await saveCustomMaps(customMaps);
  }

  /// 删除地图
  static Future<void> deleteMap(String mapId) async {
    final customMaps = await loadCustomMaps();
    customMaps.removeWhere((m) => m.id == mapId);
    await saveCustomMaps(customMaps);
  }

  /// 导出地图到指定文件
  static Future<void> exportMap(MissionMap map, String filePath) async {
    try {
      final file = File(filePath);
      final jsonString = json.encode(map.toJson());
      await file.writeAsString(jsonString);
      print('成功导出地图到: $filePath');
    } catch (e) {
      print('导出地图失败: $e');
      rethrow;
    }
  }

  /// 从文件导入地图
  static Future<MissionMap> importMap(String filePath) async {
    try {
      final file = File(filePath);
      final jsonString = await file.readAsString();
      final jsonMap = json.decode(jsonString) as Map<String, dynamic>;
      return MissionMap.fromJson(jsonMap);
    } catch (e) {
      print('导入地图失败: $e');
      rethrow;
    }
  }
}
