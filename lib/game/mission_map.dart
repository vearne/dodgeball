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

/// 玩家初始位置配置
class PlayerInitialPosition {
  final double x;
  final double y;
  final int playerId; // 玩家ID（0或1）

  const PlayerInitialPosition({
    required this.x,
    required this.y,
    required this.playerId,
  });

  Map<String, dynamic> toJson() => {'x': x, 'y': y, 'playerId': playerId};

  factory PlayerInitialPosition.fromJson(Map<String, dynamic> json) =>
      PlayerInitialPosition(
        x: (json['x'] as num).toDouble(),
        y: (json['y'] as num).toDouble(),
        playerId: json['playerId'] as int,
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
  final List<PlayerInitialPosition>? playerInitialPositions; // 玩家初始位置（可选）
  final int? maxPowerUps; // 道具投放的最大数量（可选，null表示无限制）

  const MissionMap({
    required this.id,
    required this.name,
    required this.description,
    required this.enemyCount,
    this.obstacles = const [],
    this.allowedPowerUps = const [], // 默认为空，表示不生成道具
    this.powerUpSpawnInterval = 30.0, // 默认30秒生成一次
    this.playerInitialPositions, // 可选
    this.maxPowerUps, // 可选
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'enemyCount': enemyCount,
    'obstacles': obstacles.map((o) => o.toJson()).toList(),
    'allowedPowerUps': allowedPowerUps.map((p) => p.name).toList(),
    'powerUpSpawnInterval': powerUpSpawnInterval,
    'playerInitialPositions': playerInitialPositions
        ?.map((p) => p.toJson())
        .toList(),
    'maxPowerUps': maxPowerUps,
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

    // 解析玩家初始位置列表
    final playerInitialPositionsList =
        (json['playerInitialPositions'] as List<dynamic>?)
            ?.map(
              (p) => PlayerInitialPosition.fromJson(p as Map<String, dynamic>),
            )
            .toList();

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
      playerInitialPositions: playerInitialPositionsList,
      maxPowerUps: json['maxPowerUps'] as int?,
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
    List<PlayerInitialPosition>? playerInitialPositions,
    int? maxPowerUps,
  }) {
    return MissionMap(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      enemyCount: enemyCount ?? this.enemyCount,
      obstacles: obstacles ?? this.obstacles,
      allowedPowerUps: allowedPowerUps ?? this.allowedPowerUps,
      powerUpSpawnInterval: powerUpSpawnInterval ?? this.powerUpSpawnInterval,
      playerInitialPositions:
          playerInitialPositions ?? this.playerInitialPositions,
      maxPowerUps: maxPowerUps ?? this.maxPowerUps,
    );
  }
}

/// 地图管理器：负责加载和保存地图
class MissionMapManager {
  static const String _assetMissionsDir = 'assets/config/missions';
  static const String _customMissionsDirName = 'missions';
  static const int _maxBuiltInMissions = 30; // 内置关卡数量

  /// 获取自定义地图目录路径
  static Future<String> _getCustomMissionsDirectory() async {
    final directory = await getApplicationDocumentsDirectory();
    final missionsDir = Directory('${directory.path}/$_customMissionsDirName');
    if (!await missionsDir.exists()) {
      await missionsDir.create(recursive: true);
    }
    return missionsDir.path;
  }

  /// 加载所有地图（包括内置地图和自定义地图）
  static Future<List<MissionMap>> loadMaps() async {
    final List<MissionMap> allMaps = [];

    // 1. 加载内置地图（从assets/missions目录，每个关卡一个文件）
    for (int i = 1; i <= _maxBuiltInMissions; i++) {
      try {
        final missionPath = '$_assetMissionsDir/mission_$i.json';
        final String jsonString = await rootBundle.loadString(missionPath);
        final jsonMap = json.decode(jsonString) as Map<String, dynamic>;
        final mission = MissionMap.fromJson(jsonMap);
        allMaps.add(mission);
      } catch (e) {
        // 如果某个关卡文件不存在，跳过
      }
    }

    // 2. 加载自定义地图（从文档目录/missions）
    try {
      final customMissionsDir = await _getCustomMissionsDirectory();
      final directory = Directory(customMissionsDir);
      if (await directory.exists()) {
        final files = directory.listSync();
        for (final file in files) {
          if (file is File && file.path.endsWith('.json')) {
            try {
              final String jsonString = await file.readAsString();
              final jsonMap = json.decode(jsonString) as Map<String, dynamic>;
              final mission = MissionMap.fromJson(jsonMap);
              allMaps.add(mission);
            } catch (e) {}
          }
        }
      }
    } catch (e) {}

    // 按ID排序（内置关卡按数字，自定义关卡在后面）
    allMaps.sort((a, b) {
      final aIsNumeric = int.tryParse(a.id) != null;
      final bIsNumeric = int.tryParse(b.id) != null;
      if (aIsNumeric && bIsNumeric) {
        return int.parse(a.id).compareTo(int.parse(b.id));
      } else if (aIsNumeric) {
        return -1;
      } else if (bIsNumeric) {
        return 1;
      } else {
        return a.id.compareTo(b.id);
      }
    });

    return allMaps;
  }

  /// 加载自定义地图列表
  static Future<List<MissionMap>> loadCustomMaps() async {
    final List<MissionMap> customMaps = [];
    try {
      final customMissionsDir = await _getCustomMissionsDirectory();
      final directory = Directory(customMissionsDir);
      if (await directory.exists()) {
        final files = directory.listSync();
        for (final file in files) {
          if (file is File && file.path.endsWith('.json')) {
            try {
              final String jsonString = await file.readAsString();
              final jsonMap = json.decode(jsonString) as Map<String, dynamic>;
              final mission = MissionMap.fromJson(jsonMap);
              customMaps.add(mission);
            } catch (e) {}
          }
        }
      }
    } catch (e) {}
    return customMaps;
  }

  /// 保存单个地图（添加或更新）
  static Future<void> saveMap(MissionMap map) async {
    try {
      final customMissionsDir = await _getCustomMissionsDirectory();

      // 确保ID以custom_开头
      final mapId = map.id.startsWith('custom_') ? map.id : 'custom_${map.id}';
      final fileName = 'mission_$mapId.json';
      final filePath = '$customMissionsDir/$fileName';

      final file = File(filePath);
      final jsonString = json.encode(map.copyWith(id: mapId).toJson());
      await file.writeAsString(jsonString);
    } catch (e) {
      rethrow;
    }
  }

  /// 删除地图
  static Future<void> deleteMap(String mapId) async {
    try {
      final customMissionsDir = await _getCustomMissionsDirectory();
      final fileName = mapId.startsWith('custom_')
          ? 'mission_$mapId.json'
          : 'mission_custom_$mapId.json';
      final filePath = '$customMissionsDir/$fileName';
      final file = File(filePath);

      if (await file.exists()) {
        await file.delete();
      } else {}
    } catch (e) {
      rethrow;
    }
  }

  /// 导出地图到指定文件
  static Future<void> exportMap(MissionMap map, String filePath) async {
    try {
      final file = File(filePath);
      final jsonString = json.encode(map.toJson());
      await file.writeAsString(jsonString);
    } catch (e) {
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
      rethrow;
    }
  }
}
