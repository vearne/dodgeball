import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import '../game/mission_dodgeball_game.dart';
import '../game/mission_map.dart';

/// Mission模式游戏界面
class MissionGameScreen extends StatefulWidget {
  final MissionMap missionMap;
  final double aiIntelligenceLevel;

  const MissionGameScreen({
    super.key,
    required this.missionMap,
    this.aiIntelligenceLevel = 1.0,
  });

  @override
  State<MissionGameScreen> createState() => _MissionGameScreenState();
}

class _MissionGameScreenState extends State<MissionGameScreen> {
  late MissionDodgeballGame game;

  @override
  void initState() {
    super.initState();
    game = MissionDodgeballGame(
      missionMap: widget.missionMap,
      aiIntelligenceLevel: widget.aiIntelligenceLevel,
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (!didPop) {
          _showPauseMenu();
        }
      },
      child: Scaffold(
        body: Stack(
          children: [
            // 游戏主体
            Center(
              child: AspectRatio(
                aspectRatio: 1280 / 720,
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black, width: 2),
                  ),
                  child: GameWidget.controlled(gameFactory: () => game),
                ),
              ),
            ),

            // 顶部信息栏
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(child: _buildTopBar()),
            ),

            // 冷却时间进度条
            Positioned(
              top: 70,
              left: 100,
              right: 100,
              child: SafeArea(child: _buildCooldownBar()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.black.withOpacity(0.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 地图名称
          Text(
            widget.missionMap.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          // 击杀数
          ValueListenableBuilder<int>(
            valueListenable: game.killCountNotifier,
            builder: (context, killCount, child) {
              return Text(
                '击杀: $killCount / ${widget.missionMap.enemyCount}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              );
            },
          ),

          // 暂停按钮
          IconButton(
            icon: const Icon(Icons.pause, color: Colors.white),
            onPressed: _showPauseMenu,
          ),
        ],
      ),
    );
  }

  Widget _buildCooldownBar() {
    return ValueListenableBuilder<double>(
      valueListenable: game.humanCooldownRemainingNotifier,
      builder: (context, cooldown, child) {
        final progress = cooldown > 0 ? cooldown / 10.0 : 0.0;
        return Column(
          children: [
            LinearProgressIndicator(
              value: 1.0 - progress,
              backgroundColor: Colors.grey[300],
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
              minHeight: 8,
            ),
            const SizedBox(height: 4),
            if (cooldown > 0)
              Text(
                '冷却时间: ${cooldown.toStringAsFixed(1)}秒',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  shadows: [
                    Shadow(
                      blurRadius: 2.0,
                      color: Colors.black,
                      offset: Offset(1, 1),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }

  void _showPauseMenu() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('游戏暂停'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('地图: ${widget.missionMap.name}'),
            const SizedBox(height: 8),
            Text('目标: 消灭 ${widget.missionMap.enemyCount} 个敌人'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('继续游戏'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // 关闭对话框
              Navigator.of(context).pop(); // 返回上一页
            },
            child: const Text('退出游戏'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    game.onRemove();
    super.dispose();
  }
}

