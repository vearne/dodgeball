import 'package:flutter/material.dart';
import '../game/mission_map.dart';
import 'map_editor_screen.dart';
import 'mission_game_screen.dart';

/// Mission模式关卡选择界面
class MissionSelectionScreen extends StatefulWidget {
  final double aiIntelligenceLevel;

  const MissionSelectionScreen({
    super.key,
    this.aiIntelligenceLevel = 1.0,
  });

  @override
  State<MissionSelectionScreen> createState() => _MissionSelectionScreenState();
}

class _MissionSelectionScreenState extends State<MissionSelectionScreen> {
  List<MissionMap> _maps = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadMaps();
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
        description: '击败3个敌人',
        enemyCount: 3,
        obstacles: [
          Obstacle(
            type: ObstacleType.brickWall,
            x: 400,
            y: 300,
            width: 40,
            height: 40,
          ),
          Obstacle(
            type: ObstacleType.rock,
            x: 600,
            y: 400,
            width: 40,
            height: 40,
          ),
        ],
      ),
      MissionMap(
        id: '2',
        name: '关卡 2：小试牛刀',
        description: '击败5个敌人',
        enemyCount: 5,
        obstacles: [
          Obstacle(
            type: ObstacleType.brickWall,
            x: 300,
            y: 200,
            width: 40,
            height: 40,
          ),
          Obstacle(
            type: ObstacleType.brickWall,
            x: 500,
            y: 400,
            width: 40,
            height: 40,
          ),
          Obstacle(
            type: ObstacleType.rock,
            x: 700,
            y: 300,
            width: 40,
            height: 40,
          ),
        ],
      ),
      MissionMap(
        id: '3',
        name: '关卡 3：终极挑战',
        description: '击败8个敌人',
        enemyCount: 8,
        obstacles: [
          Obstacle(
            type: ObstacleType.brickWall,
            x: 350,
            y: 250,
            width: 40,
            height: 40,
          ),
          Obstacle(
            type: ObstacleType.brickWall,
            x: 450,
            y: 350,
            width: 40,
            height: 40,
          ),
          Obstacle(
            type: ObstacleType.rock,
            x: 550,
            y: 450,
            width: 40,
            height: 40,
          ),
          Obstacle(
            type: ObstacleType.rock,
            x: 750,
            y: 250,
            width: 40,
            height: 40,
          ),
        ],
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mission模式 - 选择关卡'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          // 地图编辑器按钮
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _openMapEditor,
            tooltip: '地图编辑器',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _maps.isEmpty
              ? _buildEmptyState()
              : _buildMapList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.map, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            '暂无关卡',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _openMapEditor,
            icon: const Icon(Icons.add),
            label: const Text('创建关卡'),
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
                    Text('敌人数量: ${map.enemyCount}'),
                    const SizedBox(width: 16),
                    const Icon(Icons.block, size: 16, color: Colors.orange),
                    const SizedBox(width: 4),
                    Text('障碍物: ${map.obstacles.length}'),
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
                    tooltip: '编辑地图',
                  ),
                // 删除按钮（仅自定义地图可删除）
                if (map.id.startsWith('custom_'))
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteMap(map),
                    tooltip: '删除地图',
                  ),
                const SizedBox(width: 8),
                // 开始按钮
                ElevatedButton(
                  onPressed: () => _startMission(map),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('开始'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openMapEditor() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => const MapEditorScreen(),
      ),
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('内置地图不能删除')),
      );
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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('地图已删除')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('删除失败: $e')),
          );
        }
      }
    }
  }

  void _startMission(MissionMap map) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MissionGameScreen(
          missionMap: map,
          aiIntelligenceLevel: widget.aiIntelligenceLevel,
        ),
      ),
    );
  }
}

