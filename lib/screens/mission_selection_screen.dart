import 'package:flutter/material.dart';
import '../gen_l10n/app_localizations.dart';
import '../game/mission_map.dart';
import '../game/audio_manager.dart';
import 'map_editor_screen.dart';
import 'mission_game_screen.dart';

/// Mission模式关卡选择界面
class MissionSelectionScreen extends StatefulWidget {
  final double aiIntelligenceLevel;
  final int maxHealth;

  const MissionSelectionScreen({
    super.key,
    this.aiIntelligenceLevel = 1.0,
    this.maxHealth = 3,
  });

  @override
  State<MissionSelectionScreen> createState() => _MissionSelectionScreenState();
}

class _MissionSelectionScreenState extends State<MissionSelectionScreen> {
  List<MissionMap> _maps = [];
  bool _loading = true;
  int _playerCount = 1; // 玩家数量（1或2）

  @override
  void initState() {
    super.initState();
    _loadMaps();
    // 当进入关卡选择界面时，停止背景音乐
    _stopGameMusic();
  }

  /// 停止游戏背景音乐
  Future<void> _stopGameMusic() async {
    await AudioManager.instance.stopBackgroundMusic();
  }

  Future<void> _loadMaps() async {
    setState(() {
      _loading = true;
    });

    try {
      final maps = await MissionMapManager.loadMaps();
      setState(() {
        _maps = maps;
        _loading = false;
      });
    } catch (e) {
      // 如果加载失败，使用默认地图
      setState(() {
        _maps = _getDefaultMaps();
        _loading = false;
      });
    }
  }

  List<MissionMap> _getDefaultMaps() {
    return [
      MissionMap(
        id: '1',
        name: '关卡 1：新手训练',
        description: '击败3个敌人，熟悉游戏操作',
        enemyCount: 3,
        obstacles: [
          Obstacle(
            type: ObstacleType.brickWall,
            x: 360,
            y: 240,
            width: 60,
            height: 60,
          ),
        ],
      ),
      MissionMap(
        id: '2',
        name: '关卡 2：障碍挑战',
        description: '击败5个敌人，学会利用障碍物',
        enemyCount: 5,
        obstacles: [
          Obstacle(
            type: ObstacleType.brickWall,
            x: 300,
            y: 180,
            width: 60,
            height: 60,
          ),
          Obstacle(
            type: ObstacleType.rock,
            x: 480,
            y: 300,
            width: 60,
            height: 60,
          ),
          Obstacle(
            type: ObstacleType.brickWall,
            x: 420,
            y: 420,
            width: 60,
            height: 60,
          ),
        ],
      ),
      MissionMap(
        id: '3',
        name: '关卡 3：终极考验',
        description: '击败8个敌人，证明你的实力',
        enemyCount: 8,
        obstacles: [
          Obstacle(
            type: ObstacleType.rock,
            x: 360,
            y: 240,
            width: 60,
            height: 60,
          ),
          Obstacle(
            type: ObstacleType.brickWall,
            x: 480,
            y: 180,
            width: 120,
            height: 60,
          ),
          Obstacle(
            type: ObstacleType.rock,
            x: 540,
            y: 360,
            width: 60,
            height: 60,
          ),
          Obstacle(
            type: ObstacleType.brickWall,
            x: 420,
            y: 420,
            width: 60,
            height: 120,
          ),
        ],
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.missionModeSelectLevel),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          // 地图编辑器按钮
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _openMapEditor,
            tooltip: AppLocalizations.of(context)!.mapEditor,
          ),
        ],
      ),
      body: Column(
        children: [
          // 玩家数量选择器
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.blue.shade50,
            child: Row(
              children: [
                Text(
                  AppLocalizations.of(context)!.playerCount,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 16),
                SegmentedButton<int>(
                  segments: [
                    ButtonSegment(
                      value: 1,
                      label: Text(AppLocalizations.of(context)!.onePlayer),
                      icon: const Icon(Icons.person),
                    ),
                    ButtonSegment(
                      value: 2,
                      label: Text(AppLocalizations.of(context)!.twoPlayers),
                      icon: const Icon(Icons.people),
                    ),
                  ],
                  selected: {_playerCount},
                  onSelectionChanged: (Set<int> newSelection) {
                    setState(() {
                      _playerCount = newSelection.first;
                    });
                  },
                ),
              ],
            ),
          ),
          // 关卡列表
          Expanded(
            child: _loading
          ? const Center(child: CircularProgressIndicator())
          : _maps.isEmpty
          ? _buildEmptyState()
          : _buildMapList(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.map, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context)!.noMaps,
            style: const TextStyle(fontSize: 18, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _openMapEditor,
            icon: const Icon(Icons.add),
            label: Text(AppLocalizations.of(context)!.createMap),
          ),
        ],
      ),
    );
  }

  Widget _buildMapList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _maps.length,
      itemBuilder: (context, index) {
        final map = _maps[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            title: Text(
              map.name,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Text(map.description),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.people, size: 16, color: Colors.blue),
                    const SizedBox(width: 4),
                    Text(AppLocalizations.of(context)!.enemyCount(map.enemyCount)),
                    const SizedBox(width: 16),
                    const Icon(Icons.block, size: 16, color: Colors.orange),
                    const SizedBox(width: 4),
                    Text(AppLocalizations.of(context)!.obstacles(map.obstacles.length)),
                  ],
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 编辑按钮（仅自定义地图可编辑）
                if (map.id.startsWith('custom_'))
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () => _editMap(map),
                    tooltip: AppLocalizations.of(context)!.edit,
                  ),
                // 删除按钮（仅自定义地图可删除）
                if (map.id.startsWith('custom_'))
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteMap(map),
                    tooltip: AppLocalizations.of(context)!.delete,
                  ),
                const SizedBox(width: 8),
                // 开始按钮 - 只允许从第1关开始
                  if( _isFirstMission(map))
                      ? ElevatedButton(
                          onPressed: () => _startMission(map),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                          child: Text(AppLocalizations.of(context)!.start),
                        )
              ],
            ),
          ),
        );
      },
    );
  }

  void _openMapEditor() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (context) => const MapEditorScreen()),
    );

    // 如果保存成功，重新加载地图列表
    if (result == true && mounted) {
      _loadMaps();
    }
  }

  void _editMap(MissionMap map) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => MapEditorScreen(existingMap: map),
      ),
    );

    // 如果保存成功，重新加载地图列表
    if (result == true && mounted) {
      _loadMaps();
    }
  }

  void _deleteMap(MissionMap map) async {
    // 只能删除自定义地图（ID以custom_开头）
    if (!map.id.startsWith('custom_')) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.builtinMapCannotDelete)));
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除地图 "${map.name}" 吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await MissionMapManager.deleteMap(map.id);
        _loadMaps();
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.mapDeleted)));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.deleteFailed(e.toString()))));
        }
      }
    }
  }

  /// 判断是否是第1关（允许开始的关卡）
  bool _isFirstMission(MissionMap map) {
    // 检查是否是列表中的第一个关卡，或者ID为'1'
    final index = _maps.indexOf(map);
    return index == 0 || map.id == '1';
  }

  void _startMission(MissionMap map) {
    // 只允许从第1关开始
    if (!_isFirstMission(map)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.missionOnlyFromFirst),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    // 找到当前关卡的索引
    final currentIndex = _maps.indexOf(map);

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MissionGameScreen(
          missionMap: map,
          aiIntelligenceLevel: widget.aiIntelligenceLevel,
          maxHealth: widget.maxHealth,
          allMaps: _maps,
          currentMapIndex: currentIndex,
          playerCount: _playerCount,
        ),
      ),
    );
  }
}
