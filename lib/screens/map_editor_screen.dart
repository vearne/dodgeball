import 'package:flutter/material.dart';
import '../game/mission_map.dart';
import '../game/field_config.dart';

/// 地图编辑器界面
class MapEditorScreen extends StatefulWidget {
  final MissionMap? initialMap; // 如果提供，则编辑现有地图；否则创建新地图

  const MapEditorScreen({super.key, this.initialMap});

  @override
  State<MapEditorScreen> createState() => _MapEditorScreenState();
}

class _MapEditorScreenState extends State<MapEditorScreen> {
  late MissionMap _currentMap;
  ObstacleType _selectedObstacleType = ObstacleType.woodWall;
  final List<Obstacle> _obstacles = [];
  int _enemyCount = 5;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _enemyCountController = TextEditingController();

  // 地图尺寸（与游戏尺寸一致）
  static const double mapWidth = 1280.0;
  static const double mapHeight = 720.0;
  static const double gridSize = 40.0; // 网格大小

  @override
  void initState() {
    super.initState();
    if (widget.initialMap != null) {
      _currentMap = widget.initialMap!;
      _obstacles.addAll(_currentMap.obstacles);
      _enemyCount = _currentMap.enemyCount;
      _nameController.text = _currentMap.name;
      _descriptionController.text = _currentMap.description;
    } else {
      _currentMap = MissionMap(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: '新地图',
        description: '',
        enemyCount: 5,
      );
      _nameController.text = '新地图';
    }
    _enemyCountController.text = _enemyCount.toString();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _enemyCountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('地图编辑器'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Row(
        children: [
          // 左侧工具栏
          _buildToolbar(),
          // 中间地图编辑区域
          Expanded(
            child: _buildMapEditor(),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbar() {
    return Container(
      width: 300,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border(right: BorderSide(color: Colors.grey[300]!)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 地图信息
            _buildMapInfoSection(),
            const SizedBox(height: 24),
            // 障碍物类型选择
            _buildObstacleTypeSection(),
            const SizedBox(height: 24),
            // 敌人数量设置
            _buildEnemyCountSection(),
            const SizedBox(height: 24),
            // 操作按钮
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildMapInfoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '地图信息',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: '地图名称',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {});
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: '地图描述',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              onChanged: (value) {
                setState(() {});
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildObstacleTypeSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '障碍物类型',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            RadioListTile<ObstacleType>(
              title: const Text('木墙'),
              subtitle: const Text('被球击中后消失'),
              value: ObstacleType.woodWall,
              groupValue: _selectedObstacleType,
              onChanged: (value) {
                setState(() {
                  _selectedObstacleType = value!;
                });
              },
            ),
            RadioListTile<ObstacleType>(
              title: const Text('岩石'),
              subtitle: const Text('被球击中后反弹'),
              value: ObstacleType.rock,
              groupValue: _selectedObstacleType,
              onChanged: (value) {
                setState(() {
                  _selectedObstacleType = value!;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnemyCountSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '敌人数量',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _enemyCountController,
              decoration: const InputDecoration(
                labelText: '敌人数量',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                final count = int.tryParse(value);
                if (count != null && count > 0) {
                  setState(() {
                    _enemyCount = count;
                  });
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton.icon(
          onPressed: _saveMap,
          icon: const Icon(Icons.save),
          label: const Text('保存地图'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: _clearAllObstacles,
          icon: const Icon(Icons.clear_all),
          label: const Text('清除所有障碍物'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close),
          label: const Text('取消'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildMapEditor() {
    return Container(
      color: Colors.grey[200],
      child: Center(
        child: AspectRatio(
          aspectRatio: mapWidth / mapHeight,
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black, width: 2),
              color: FieldConfig.fieldBackgroundColor,
            ),
            child: GestureDetector(
              onTapDown: (details) {
                _handleMapTap(details.localPosition);
              },
              child: CustomPaint(
                painter: MapEditorPainter(
                  obstacles: _obstacles,
                  gridSize: gridSize,
                ),
                child: Stack(
                  children: [
                    // 显示玩家和敌人区域提示
                    Positioned(
                      left: 0,
                      top: 0,
                      bottom: 0,
                      width: mapWidth / 2,
                      child: Container(
                        decoration: BoxDecoration(
                          color: FieldConfig.redTeamAreaColor,
                          border: Border(
                            right: BorderSide(color: Colors.red, width: 2),
                          ),
                        ),
                        child: const Center(
                          child: Text(
                            '玩家区域',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 0,
                      top: 0,
                      bottom: 0,
                      width: mapWidth / 2,
                      child: Container(
                        decoration: BoxDecoration(
                          color: FieldConfig.blueTeamAreaColor,
                          border: Border(
                            left: BorderSide(color: Colors.blue, width: 2),
                          ),
                        ),
                        child: const Center(
                          child: Text(
                            '敌人区域',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _handleMapTap(Offset localPosition) {
    // 将点击位置对齐到网格
    final gridX = (localPosition.dx / gridSize).floor() * gridSize;
    final gridY = (localPosition.dy / gridSize).floor() * gridSize;

    // 检查是否点击了现有障碍物（删除）
    final clickedObstacle = _obstacles.firstWhere(
      (obs) =>
          gridX >= obs.x &&
          gridX < obs.x + obs.width &&
          gridY >= obs.y &&
          gridY < obs.y + obs.height,
      orElse: () => Obstacle(
        type: ObstacleType.woodWall,
        x: -1,
        y: -1,
        width: 0,
        height: 0,
      ),
    );

    if (clickedObstacle.x >= 0) {
      // 删除障碍物
      setState(() {
        _obstacles.remove(clickedObstacle);
      });
    } else {
      // 添加新障碍物
      setState(() {
        _obstacles.add(Obstacle(
          type: _selectedObstacleType,
          x: gridX,
          y: gridY,
          width: gridSize,
          height: gridSize,
        ));
      });
    }
  }

  void _clearAllObstacles() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认清除'),
        content: const Text('确定要清除所有障碍物吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _obstacles.clear();
              });
              Navigator.of(context).pop();
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _saveMap() {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入地图名称')),
      );
      return;
    }

    final savedMap = MissionMap(
      id: widget.initialMap?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
      enemyCount: _enemyCount,
      obstacles: List.from(_obstacles),
    );

    // 返回保存的地图
    Navigator.of(context).pop(savedMap);
  }
}

/// 地图编辑器绘制器
class MapEditorPainter extends CustomPainter {
  final List<Obstacle> obstacles;
  final double gridSize;

  MapEditorPainter({
    required this.obstacles,
    required this.gridSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 绘制网格
    final gridPaint = Paint()
      ..color = Colors.grey[300]!
      ..strokeWidth = 1.0;

    for (double x = 0; x < size.width; x += gridSize) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        gridPaint,
      );
    }

    for (double y = 0; y < size.height; y += gridSize) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        gridPaint,
      );
    }

    // 绘制障碍物
    for (final obstacle in obstacles) {
      final paint = Paint()
        ..color = obstacle.type == ObstacleType.woodWall
            ? const Color(0xFF8B4513) // 棕色木墙
            : const Color(0xFF696969) // 灰色岩石
        ..style = PaintingStyle.fill;

      canvas.drawRect(
        Rect.fromLTWH(
          obstacle.x,
          obstacle.y,
          obstacle.width,
          obstacle.height,
        ),
        paint,
      );

      // 绘制边框
      final borderPaint = Paint()
        ..color = obstacle.type == ObstacleType.woodWall
            ? const Color(0xFF654321)
            : const Color(0xFF404040)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;

      canvas.drawRect(
        Rect.fromLTWH(
          obstacle.x,
          obstacle.y,
          obstacle.width,
          obstacle.height,
        ),
        borderPaint,
      );
    }
  }

  @override
  bool shouldRepaint(MapEditorPainter oldDelegate) {
    return obstacles.length != oldDelegate.obstacles.length ||
        obstacles != oldDelegate.obstacles;
  }
}

