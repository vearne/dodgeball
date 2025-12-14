import 'package:flutter/material.dart';
import '../game/mission_map.dart';

/// 地图编辑器界面（网格点击模式）
class MapEditorScreen extends StatefulWidget {
  final MissionMap? existingMap; // 如果提供，则编辑现有地图

  const MapEditorScreen({super.key, this.existingMap});

  @override
  State<MapEditorScreen> createState() => _MapEditorScreenState();
}

class _MapEditorScreenState extends State<MapEditorScreen> {
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _enemyCountController;

  // 使用Map来存储网格位置的障碍物，key是"row_col"
  final Map<String, ObstacleType> _gridObstacles = {};
  ObstacleType _selectedObstacleType = ObstacleType.brickWall;

  // 地图尺寸（与游戏实际尺寸一致）
  static const double mapWidth = 800.0;
  static const double mapHeight = 600.0;
  static const double gridSize = 60.0; // 网格大小（原子障碍物大小）

  // 计算网格行列数
  static const int gridCols = 13; // 800 / 60 = 13.33，向下取整为13
  static const int gridRows = 10; // 600 / 60 = 10

  @override
  void initState() {
    super.initState();

    if (widget.existingMap != null) {
      // 编辑现有地图
      _nameController = TextEditingController(text: widget.existingMap!.name);
      _descriptionController = TextEditingController(
        text: widget.existingMap!.description,
      );
      _enemyCountController = TextEditingController(
        text: widget.existingMap!.enemyCount.toString(),
      );

      // 将现有障碍物转换为网格格式
      _loadObstaclesFromMap(widget.existingMap!);
    } else {
      // 创建新地图
      _nameController = TextEditingController();
      _descriptionController = TextEditingController();
      _enemyCountController = TextEditingController(text: '3');
    }
  }

  /// 从地图加载障碍物到网格
  void _loadObstaclesFromMap(MissionMap map) {
    for (final obstacle in map.obstacles) {
      // 计算障碍物占据的网格范围
      final startCol = (obstacle.x / gridSize).round();
      final startRow = (obstacle.y / gridSize).round();
      final cols = (obstacle.width / gridSize).round();
      final rows = (obstacle.height / gridSize).round();

      // 填充所有网格
      for (int row = startRow; row < startRow + rows; row++) {
        for (int col = startCol; col < startCol + cols; col++) {
          if (col >= 0 && col < gridCols && row >= 0 && row < gridRows) {
            _gridObstacles['${row}_$col'] = obstacle.type;
          }
        }
      }
    }
  }

  /// 从网格生成障碍物列表（合并相邻的同类型障碍物）
  List<Obstacle> _generateObstaclesFromGrid() {
    final List<Obstacle> obstacles = [];
    final Set<String> processed = {};

    // 遍历所有网格
    for (int row = 0; row < gridRows; row++) {
      for (int col = 0; col < gridCols; col++) {
        final key = '${row}_$col';
        if (processed.contains(key) || !_gridObstacles.containsKey(key)) {
          continue;
        }

        final type = _gridObstacles[key]!;

        // 尝试向右和向下扩展，找到最大的矩形
        int width = 1;
        int height = 1;

        // 向右扩展
        while (col + width < gridCols) {
          final nextKey = '${row}_${col + width}';
          if (_gridObstacles[nextKey] == type) {
            width++;
          } else {
            break;
          }
        }

        // 向下扩展（确保整行都匹配）
        bool canExpandDown = true;
        while (canExpandDown && row + height < gridRows) {
          for (int c = col; c < col + width; c++) {
            final nextKey = '${row + height}_$c';
            if (_gridObstacles[nextKey] != type) {
              canExpandDown = false;
              break;
            }
          }
          if (canExpandDown) {
            height++;
          }
        }

        // 标记所有被合并的网格为已处理
        for (int r = row; r < row + height; r++) {
          for (int c = col; c < col + width; c++) {
            processed.add('${r}_$c');
          }
        }

        // 创建障碍物
        obstacles.add(
          Obstacle(
            type: type,
            x: col * gridSize,
            y: row * gridSize,
            width: width * gridSize,
            height: height * gridSize,
          ),
        );
      }
    }

    return obstacles;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _enemyCountController.dispose();
    super.dispose();
  }

  void _saveMap() async {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请输入地图名称')));
      return;
    }

    final enemyCount = int.tryParse(_enemyCountController.text) ?? 3;
    if (enemyCount < 1 || enemyCount > 10) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('敌人数量必须在1-10之间')));
      return;
    }

    // 生成地图ID（如果是新地图）
    final mapId =
        widget.existingMap?.id ??
        'custom_${DateTime.now().millisecondsSinceEpoch}';

    // 从网格生成障碍物列表
    final obstacles = _generateObstaclesFromGrid();

    final newMap = MissionMap(
      id: mapId,
      name: _nameController.text,
      description: _descriptionController.text,
      enemyCount: enemyCount,
      obstacles: obstacles,
    );

    try {
      await MissionMapManager.saveMap(newMap);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('地图保存成功！')));
        Navigator.pop(context, true); // 返回true表示保存成功
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('保存失败: $e')));
      }
    }
  }

  void _clearAllObstacles() {
    setState(() {
      _gridObstacles.clear();
    });
  }

  void _toggleGridCell(int row, int col) {
    setState(() {
      final key = '${row}_$col';
      if (_gridObstacles.containsKey(key)) {
        // 如果已有障碍物，移除它
        _gridObstacles.remove(key);
      } else {
        // 如果没有障碍物，放置新的
        _gridObstacles[key] = _selectedObstacleType;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingMap != null ? '编辑地图' : '创建新地图'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveMap,
            tooltip: '保存地图',
          ),
        ],
      ),
      body: Row(
        children: [
          // 左侧：编辑器控制面板
          SizedBox(width: 300, child: _buildControlPanel()),

          // 右侧：地图画布
          Expanded(child: _buildMapCanvas()),
        ],
      ),
    );
  }

  Widget _buildControlPanel() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey[200],
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '地图信息',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: '地图名称',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: '地图描述',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _enemyCountController,
              decoration: const InputDecoration(
                labelText: '敌人数量 (1-10)',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
              ),
              keyboardType: TextInputType.number,
            ),

            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),

            const Text(
              '障碍物工具',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // 障碍物类型选择
            _buildObstacleTypeSelector(),

            const SizedBox(height: 16),

            ElevatedButton.icon(
              onPressed: _clearAllObstacles,
              icon: const Icon(Icons.delete_sweep),
              label: const Text('清空所有障碍物'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                minimumSize: const Size(double.infinity, 48),
              ),
            ),

            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),

            // 障碍物统计
            const Text(
              '障碍物统计',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('共 ${_gridObstacles.length} 个原子障碍物'),
            const SizedBox(height: 8),

            // 统计各类型数量
            Builder(
              builder: (context) {
                final brickCount = _gridObstacles.values
                    .where((t) => t == ObstacleType.brickWall)
                    .length;
                final rockCount = _gridObstacles.values
                    .where((t) => t == ObstacleType.rock)
                    .length;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.web_asset,
                          color: Colors.red,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text('砖墙: $brickCount 个'),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.landscape,
                          color: Colors.grey,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text('岩石: $rockCount 个'),
                      ],
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue, width: 2),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info, color: Colors.blue, size: 20),
                      SizedBox(width: 8),
                      Text(
                        '使用说明',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    '• 选择障碍物类型\n'
                    '• 点击网格单元格放置\n'
                    '• 再次点击可移除\n'
                    '• 相邻同类型自动合并',
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildObstacleTypeSelector() {
    return Column(
      children: [
        RadioListTile<ObstacleType>(
          title: const Row(
            children: [
              Icon(Icons.web_asset, color: Colors.red),
              SizedBox(width: 8),
              Flexible(child: Text('砖墙')),
            ],
          ),
          subtitle: const Padding(
            padding: EdgeInsets.only(left: 32),
            child: Text('被击中后消失', style: TextStyle(fontSize: 12)),
          ),
          value: ObstacleType.brickWall,
          groupValue: _selectedObstacleType,
          onChanged: (value) {
            setState(() {
              _selectedObstacleType = value!;
            });
          },
          activeColor: Colors.red,
        ),
        RadioListTile<ObstacleType>(
          title: const Row(
            children: [
              Icon(Icons.landscape, color: Colors.grey),
              SizedBox(width: 8),
              Text('岩石'),
            ],
          ),
          subtitle: const Padding(
            padding: EdgeInsets.only(left: 32),
            child: Text('球会反弹，不可摧毁', style: TextStyle(fontSize: 12)),
          ),
          value: ObstacleType.rock,
          groupValue: _selectedObstacleType,
          onChanged: (value) {
            setState(() {
              _selectedObstacleType = value!;
            });
          },
          activeColor: Colors.grey,
        ),
      ],
    );
  }

  Widget _buildMapCanvas() {
    return Container(
      color: Colors.white,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 提示信息
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              border: Border.all(color: Colors.green, width: 2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.mouse, color: Colors.green),
                const SizedBox(width: 8),
                Text(
                  '点击网格放置 ${_selectedObstacleType == ObstacleType.brickWall ? "砖墙" : "岩石"}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade900,
                  ),
                ),
              ],
            ),
          ),

          // 地图画布
          Container(
            width: mapWidth,
            height: mapHeight,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black, width: 2),
            ),
            child: GestureDetector(
              onTapDown: (details) {
                final localPosition = details.localPosition;
                final col = (localPosition.dx / gridSize).floor();
                final row = (localPosition.dy / gridSize).floor();

                if (col >= 0 && col < gridCols && row >= 0 && row < gridRows) {
                  _toggleGridCell(row, col);
                }
              },
              child: CustomPaint(
                painter: GridMapCanvasPainter(
                  gridObstacles: _gridObstacles,
                  gridSize: gridSize,
                  gridCols: gridCols,
                  gridRows: gridRows,
                ),
                size: const Size(mapWidth, mapHeight),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 网格地图画布绘制器
class GridMapCanvasPainter extends CustomPainter {
  final Map<String, ObstacleType> gridObstacles;
  final double gridSize;
  final int gridCols;
  final int gridRows;

  GridMapCanvasPainter({
    required this.gridObstacles,
    required this.gridSize,
    required this.gridCols,
    required this.gridRows,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 绘制区域分隔（红方 vs 蓝方）
    _drawAreaDivider(canvas, size);

    // 绘制网格线
    _drawGrid(canvas, size);

    // 绘制障碍物
    _drawObstacles(canvas);
  }

  void _drawAreaDivider(Canvas canvas, Size size) {
    final midX = size.width / 2;

    // 绘制红方区域背景（左侧）
    final redAreaPaint = Paint()
      ..color = Colors.red.withOpacity(0.05)
      ..style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromLTWH(0, 0, midX, size.height), redAreaPaint);

    // 绘制蓝方区域背景（右侧）
    final blueAreaPaint = Paint()
      ..color = Colors.blue.withOpacity(0.05)
      ..style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromLTWH(midX, 0, midX, size.height), blueAreaPaint);

    // 绘制中线
    final centerLinePaint = Paint()
      ..color = Colors.black.withOpacity(0.3)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    const dashWidth = 10.0;
    const dashSpace = 5.0;
    double startY = 0;
    while (startY < size.height) {
      canvas.drawLine(
        Offset(midX, startY),
        Offset(midX, startY + dashWidth),
        centerLinePaint,
      );
      startY += dashWidth + dashSpace;
    }
  }

  void _drawGrid(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.withOpacity(0.3)
      ..strokeWidth = 1;

    // 绘制垂直线
    for (int col = 0; col <= gridCols; col++) {
      final x = col * gridSize;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // 绘制水平线
    for (int row = 0; row <= gridRows; row++) {
      final y = row * gridSize;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  void _drawObstacles(Canvas canvas) {
    for (final entry in gridObstacles.entries) {
      final parts = entry.key.split('_');
      final row = int.parse(parts[0]);
      final col = int.parse(parts[1]);
      final type = entry.value;

      final x = col * gridSize;
      final y = row * gridSize;

      final isBrickWall = type == ObstacleType.brickWall;
      final paint = Paint()
        ..color = isBrickWall ? Colors.red.shade700 : Colors.grey.shade600
        ..style = PaintingStyle.fill;

      final borderPaint = Paint()
        ..color = isBrickWall ? Colors.red.shade900 : Colors.grey.shade900
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      final rect = Rect.fromLTWH(x, y, gridSize, gridSize);
      canvas.drawRect(rect, paint);
      canvas.drawRect(rect, borderPaint);

      // 绘制图标
      final icon = isBrickWall ? '🧱' : '🪨';
      final textPainter = TextPainter(
        text: TextSpan(text: icon, style: const TextStyle(fontSize: 32)),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          x + gridSize / 2 - textPainter.width / 2,
          y + gridSize / 2 - textPainter.height / 2,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(GridMapCanvasPainter oldDelegate) {
    return gridObstacles != oldDelegate.gridObstacles;
  }
}
