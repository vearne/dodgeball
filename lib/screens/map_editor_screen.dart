import 'package:flutter/material.dart';
import '../game/mission_map.dart';
import 'dart:math' as math;

/// 地图编辑器界面
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
  
  List<Obstacle> _obstacles = [];
  ObstacleType _selectedObstacleType = ObstacleType.brickWall;
  bool _isPlacingObstacle = false;
  Offset? _dragStart;
  Offset? _dragEnd;

  // 地图尺寸（与游戏实际尺寸一致）
  static const double mapWidth = 800.0;
  static const double mapHeight = 600.0;
  
  @override
  void initState() {
    super.initState();
    
    if (widget.existingMap != null) {
      // 编辑现有地图
      _nameController = TextEditingController(text: widget.existingMap!.name);
      _descriptionController = TextEditingController(text: widget.existingMap!.description);
      _enemyCountController = TextEditingController(text: widget.existingMap!.enemyCount.toString());
      _obstacles = List.from(widget.existingMap!.obstacles);
    } else {
      // 创建新地图
      _nameController = TextEditingController();
      _descriptionController = TextEditingController();
      _enemyCountController = TextEditingController(text: '3');
    }
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入地图名称')),
      );
      return;
    }

    final enemyCount = int.tryParse(_enemyCountController.text) ?? 3;
    if (enemyCount < 1 || enemyCount > 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('敌人数量必须在1-10之间')),
      );
      return;
    }

    // 生成地图ID（如果是新地图）
    final mapId = widget.existingMap?.id ?? 
        'custom_${DateTime.now().millisecondsSinceEpoch}';

    final newMap = MissionMap(
      id: mapId,
      name: _nameController.text,
      description: _descriptionController.text,
      enemyCount: enemyCount,
      obstacles: _obstacles,
    );

    try {
      await MissionMapManager.saveMap(newMap);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('地图保存成功！')),
        );
        Navigator.pop(context, true); // 返回true表示保存成功
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存失败: $e')),
        );
      }
    }
  }

  void _deleteObstacle(int index) {
    setState(() {
      _obstacles.removeAt(index);
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
          SizedBox(
            width: 300,
            child: _buildControlPanel(),
          ),
          
          // 右侧：地图画布
          Expanded(
            child: _buildMapCanvas(),
          ),
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
              onPressed: () {
                setState(() {
                  _isPlacingObstacle = !_isPlacingObstacle;
                });
              },
              icon: Icon(_isPlacingObstacle ? Icons.close : Icons.add),
              label: Text(_isPlacingObstacle ? '取消放置' : '放置障碍物'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _isPlacingObstacle ? Colors.orange : Colors.blue,
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
            
            const SizedBox(height: 16),
            
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _obstacles.clear();
                });
              },
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
            
            // 障碍物列表
            const Text(
              '障碍物列表',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('共 ${_obstacles.length} 个障碍物'),
            const SizedBox(height: 8),
            
            ..._obstacles.asMap().entries.map((entry) {
              final index = entry.key;
              final obstacle = entry.value;
              final isBrickWall = obstacle.type == ObstacleType.brickWall || 
                                  obstacle.type == ObstacleType.woodWall;
              return Card(
                child: ListTile(
                  leading: Icon(
                    isBrickWall ? Icons.web_asset : Icons.landscape,
                    color: isBrickWall ? Colors.red : Colors.grey,
                  ),
                  title: Text(
                    isBrickWall ? '砖墙 (耐久3)' : '岩石',
                  ),
                  subtitle: Text(
                    '位置: (${obstacle.x.toInt()}, ${obstacle.y.toInt()})\n'
                    '大小: ${obstacle.width.toInt()} x ${obstacle.height.toInt()}',
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteObstacle(index),
                  ),
                ),
              );
            }),
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
              Flexible(
                child: Text('砖墙（耐久度3，逐渐损坏）'),
              ),
            ],
          ),
          subtitle: const Padding(
            padding: EdgeInsets.only(left: 32),
            child: Text('被击中3次后才会完全摧毁', style: TextStyle(fontSize: 12)),
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
              Text('岩石（反弹，不可摧毁）'),
            ],
          ),
          subtitle: const Padding(
            padding: EdgeInsets.only(left: 32),
            child: Text('球会反弹，永不损坏', style: TextStyle(fontSize: 12)),
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
          if (_isPlacingObstacle)
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.orange.shade100,
                border: Border.all(color: Colors.orange, width: 2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.info, color: Colors.orange),
                  const SizedBox(width: 8),
                  Text(
                    '放置模式已激活：在地图上拖动创建障碍物',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange.shade900,
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
              border: Border.all(
                color: _isPlacingObstacle ? Colors.orange : Colors.black,
                width: _isPlacingObstacle ? 3 : 2,
              ),
              boxShadow: _isPlacingObstacle
                  ? [
                      BoxShadow(
                        color: Colors.orange.withOpacity(0.3),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
            child: GestureDetector(
              onPanStart: _isPlacingObstacle ? _onPanStart : null,
              onPanUpdate: _isPlacingObstacle ? _onPanUpdate : null,
              onPanEnd: _isPlacingObstacle ? _onPanEnd : null,
              child: CustomPaint(
                painter: MapCanvasPainter(
                  obstacles: _obstacles,
                  dragStart: _dragStart,
                  dragEnd: _dragEnd,
                  selectedType: _selectedObstacleType,
                  isPlacingMode: _isPlacingObstacle,
                ),
                size: const Size(mapWidth, mapHeight),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onPanStart(DragStartDetails details) {
    setState(() {
      _dragStart = details.localPosition;
      _dragEnd = details.localPosition;
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      _dragEnd = details.localPosition;
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (_dragStart != null && _dragEnd != null) {
      final x = math.min(_dragStart!.dx, _dragEnd!.dx);
      final y = math.min(_dragStart!.dy, _dragEnd!.dy);
      final width = (_dragEnd!.dx - _dragStart!.dx).abs();
      final height = (_dragEnd!.dy - _dragStart!.dy).abs();

      // 最小尺寸检查（降低到10x10）
      if (width > 10 && height > 10) {
        setState(() {
          _obstacles.add(Obstacle(
            type: _selectedObstacleType,
            x: x,
            y: y,
            width: width,
            height: height,
          ));
        });
        
        // 显示成功提示
        final typeName = _selectedObstacleType == ObstacleType.brickWall ? "砖墙" : "岩石";
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('已添加$typeName'),
            duration: const Duration(seconds: 1),
          ),
        );
      } else {
        // 提示尺寸太小
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('障碍物太小了！请拖动更大的区域'),
            duration: Duration(seconds: 1),
          ),
        );
      }
    }

    setState(() {
      _dragStart = null;
      _dragEnd = null;
    });
  }
}

/// 地图画布绘制器
class MapCanvasPainter extends CustomPainter {
  final List<Obstacle> obstacles;
  final Offset? dragStart;
  final Offset? dragEnd;
  final ObstacleType selectedType;
  final bool isPlacingMode;

  MapCanvasPainter({
    required this.obstacles,
    this.dragStart,
    this.dragEnd,
    required this.selectedType,
    this.isPlacingMode = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 绘制背景网格
    _drawGrid(canvas, size);

    // 绘制区域分隔线（玩家区域 vs 敌人区域）
    _drawAreaDivider(canvas, size);

    // 绘制现有障碍物
    for (final obstacle in obstacles) {
      _drawObstacle(canvas, obstacle);
    }

    // 绘制正在拖动的障碍物预览
    if (dragStart != null && dragEnd != null) {
      final rect = Rect.fromPoints(dragStart!, dragEnd!);
      final isBrickWall = selectedType == ObstacleType.brickWall || 
                          selectedType == ObstacleType.woodWall;
      final paint = Paint()
        ..color = isBrickWall
            ? Colors.red.withOpacity(0.5)
            : Colors.grey.withOpacity(0.5)
        ..style = PaintingStyle.fill;
      
      final borderPaint = Paint()
        ..color = isBrickWall ? Colors.red : Colors.grey
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      canvas.drawRect(rect, paint);
      canvas.drawRect(rect, borderPaint);
      
      // 显示尺寸信息
      final width = (rect.right - rect.left).abs();
      final height = (rect.bottom - rect.top).abs();
      final sizeText = TextPainter(
        text: TextSpan(
          text: '${width.toInt()} x ${height.toInt()}',
          style: const TextStyle(
            color: Colors.black,
            fontSize: 14,
            fontWeight: FontWeight.bold,
            backgroundColor: Colors.white,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      sizeText.layout();
      sizeText.paint(
        canvas,
        Offset(
          rect.center.dx - sizeText.width / 2,
          rect.center.dy - sizeText.height / 2,
        ),
      );
    } else if (isPlacingMode && obstacles.isEmpty) {
      // 当处于放置模式但没有障碍物时，显示提示
      final textPainter = TextPainter(
        text: const TextSpan(
          text: '👆 在地图上按住拖动创建障碍物\n最小尺寸: 10x10',
          style: TextStyle(
            color: Colors.grey,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          size.width / 2 - textPainter.width / 2,
          size.height / 2 - textPainter.height / 2,
        ),
      );
    }
  }

  void _drawGrid(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.withOpacity(0.2)
      ..strokeWidth = 0.5;

    const gridSize = 50.0;

    // 绘制垂直线
    for (double x = 0; x <= size.width; x += gridSize) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }

    // 绘制水平线
    for (double y = 0; y <= size.height; y += gridSize) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }
  }

  void _drawAreaDivider(Canvas canvas, Size size) {
    final midX = size.width / 2;

    // 绘制红方区域背景（左侧）
    final redAreaPaint = Paint()
      ..color = Colors.red.withOpacity(0.08)
      ..style = PaintingStyle.fill;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, midX, size.height),
      redAreaPaint,
    );

    // 绘制蓝方区域背景（右侧）
    final blueAreaPaint = Paint()
      ..color = Colors.blue.withOpacity(0.08)
      ..style = PaintingStyle.fill;
    canvas.drawRect(
      Rect.fromLTWH(midX, 0, midX, size.height),
      blueAreaPaint,
    );

    // 绘制中线（加粗虚线）
    final centerLinePaint = Paint()
      ..color = Colors.black.withOpacity(0.5)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    // 虚线效果
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

    // 绘制边界线
    final borderPaint = Paint()
      ..color = Colors.black.withOpacity(0.3)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    
    // 左边界
    canvas.drawLine(Offset(0, 0), Offset(0, size.height), borderPaint);
    // 右边界
    canvas.drawLine(Offset(size.width, 0), Offset(size.width, size.height), borderPaint);
    // 上边界
    canvas.drawLine(Offset(0, 0), Offset(size.width, 0), borderPaint);
    // 下边界
    canvas.drawLine(Offset(0, size.height), Offset(size.width, size.height), borderPaint);

    // 绘制标签（带背景）
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    // 红方标签
    textPainter.text = TextSpan(
      text: '🔴 红方区域（玩家）',
      style: const TextStyle(
        color: Colors.red,
        fontSize: 18,
        fontWeight: FontWeight.bold,
        shadows: [
          Shadow(
            offset: Offset(1, 1),
            blurRadius: 3,
            color: Colors.white,
          ),
        ],
      ),
    );
    textPainter.layout();
    
    // 绘制标签背景
    final redLabelBg = Paint()
      ..color = Colors.white.withOpacity(0.8)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          midX / 2 - textPainter.width / 2 - 8,
          15,
          textPainter.width + 16,
          textPainter.height + 8,
        ),
        const Radius.circular(8),
      ),
      redLabelBg,
    );
    textPainter.paint(canvas, Offset(midX / 2 - textPainter.width / 2, 20));

    // 蓝方标签
    textPainter.text = TextSpan(
      text: '🔵 蓝方区域（敌人）',
      style: const TextStyle(
        color: Colors.blue,
        fontSize: 18,
        fontWeight: FontWeight.bold,
        shadows: [
          Shadow(
            offset: Offset(1, 1),
            blurRadius: 3,
            color: Colors.white,
          ),
        ],
      ),
    );
    textPainter.layout();
    
    // 绘制标签背景
    final blueLabelBg = Paint()
      ..color = Colors.white.withOpacity(0.8)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          midX + midX / 2 - textPainter.width / 2 - 8,
          15,
          textPainter.width + 16,
          textPainter.height + 8,
        ),
        const Radius.circular(8),
      ),
      blueLabelBg,
    );
    textPainter.paint(canvas, Offset(midX + midX / 2 - textPainter.width / 2, 20));

    // 绘制底部说明
    textPainter.text = const TextSpan(
      text: '提示：玩家和敌人会在各自区域生成',
      style: TextStyle(
        color: Colors.black54,
        fontSize: 14,
        fontStyle: FontStyle.italic,
      ),
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        size.width / 2 - textPainter.width / 2,
        size.height - 30,
      ),
    );
  }

  void _drawObstacle(Canvas canvas, Obstacle obstacle) {
    final rect = Rect.fromLTWH(obstacle.x, obstacle.y, obstacle.width, obstacle.height);
    
    final isBrickWall = obstacle.type == ObstacleType.brickWall || 
                        obstacle.type == ObstacleType.woodWall;
    
    final paint = Paint()
      ..color = isBrickWall ? Colors.red.shade700 : Colors.grey
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = isBrickWall ? Colors.red.shade900 : Colors.grey.shade900
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawRect(rect, paint);
    canvas.drawRect(rect, borderPaint);

    // 绘制图标
    final icon = isBrickWall ? '🧱' : '🪨';
    final textPainter = TextPainter(
      text: TextSpan(
        text: icon,
        style: const TextStyle(fontSize: 24),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        rect.center.dx - textPainter.width / 2,
        rect.center.dy - textPainter.height / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(MapCanvasPainter oldDelegate) {
    return obstacles != oldDelegate.obstacles ||
        dragStart != oldDelegate.dragStart ||
        dragEnd != oldDelegate.dragEnd ||
        selectedType != oldDelegate.selectedType ||
        isPlacingMode != oldDelegate.isPlacingMode;
  }
}
