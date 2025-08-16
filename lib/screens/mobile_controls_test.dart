import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import '../game/dodgeball_game.dart';
import '../game/game_mode.dart';

/// 移动设备控制器测试界面
class MobileControlsTestScreen extends StatelessWidget {
  const MobileControlsTestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('移动设备控制器测试'),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
      ),
      body: GameWidget<DodgeballGame>(
        game: DodgeballGame(gameMode: GameMode.singlePlayer),
        overlayBuilderMap: {
          'mobile_controls': (context, game) =>
              _buildControlsOverlay(context, game),
        },
        initialActiveOverlays: const ['mobile_controls'],
      ),
    );
  }

  Widget _buildControlsOverlay(BuildContext context, DodgeballGame game) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // 控制说明
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Column(
              children: [
                Text(
                  '移动设备控制说明',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text('• 左下角：虚拟摇杆控制移动', style: TextStyle(color: Colors.white)),
                Text('• 右下角：发射按钮投掷球', style: TextStyle(color: Colors.white)),
                Text('• 箭头方向即为投掷方向', style: TextStyle(color: Colors.white)),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 返回按钮
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[600],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
            ),
            child: const Text('返回'),
          ),
        ],
      ),
    );
  }
}
