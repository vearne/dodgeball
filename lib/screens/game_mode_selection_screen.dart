import 'package:flutter/material.dart';
import 'mission_selection_screen.dart';
import 'input_settings_screen.dart';
import 'game_help_screen.dart';
import 'audio_settings_screen.dart';

/// 游戏模式选择界面
class GameModeSelectionScreen extends StatefulWidget {
  const GameModeSelectionScreen({super.key});

  @override
  State<GameModeSelectionScreen> createState() =>
      _GameModeSelectionScreenState();
}

class _GameModeSelectionScreenState extends State<GameModeSelectionScreen> {
  int _maxHealth = 3;
  double _aiIntelligenceLevel = 1.0; // AI智能水平 0.5-2.0

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('躲避球游戏'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            tooltip: '游戏帮助',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const GameHelpScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.volume_up),
            tooltip: '音频设置',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const AudioSettingsScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: '输入设置',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const InputSettingsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 游戏说明
            Card(
              color: Colors.blue[50],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue[700]),
                        const SizedBox(width: 8),
                        Text(
                          'Mission模式',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '• 消灭所有敌人完成关卡\n'
                      '• 通过关卡后自动进入下一关\n'
                      '• 设置好生命值和AI难度后开始挑战',
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 游戏参数设置
            _buildGameSettings(),
            const SizedBox(height: 24),

            // 开始游戏按钮
            _buildStartGameButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildGameSettings() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '游戏设置',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // 生命值设置
            const Text(
              '初始生命值',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Slider(
              value: _maxHealth.toDouble(),
              min: 1,
              max: 5,
              divisions: 4,
              label: '$_maxHealth 条命',
              onChanged: (value) {
                setState(() {
                  _maxHealth = value.round();
                });
              },
            ),
            Center(
              child: Text(
                '当前生命值：$_maxHealth',
                style: TextStyle(fontSize: 14, color: Colors.grey[700]),
              ),
            ),

            // AI智能水平设置
            const SizedBox(height: 16),
            const Text(
              'AI智能水平',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('简单', style: TextStyle(fontSize: 12)),
                Expanded(
                  child: Slider(
                    value: _aiIntelligenceLevel,
                    min: 0.5,
                    max: 2.0,
                    divisions: 6,
                    label: _getAIIntelligenceLabel(_aiIntelligenceLevel),
                    onChanged: (value) {
                      setState(() {
                        _aiIntelligenceLevel = value;
                      });
                    },
                  ),
                ),
                const Text('困难', style: TextStyle(fontSize: 12)),
              ],
            ),
            Center(
              child: Text(
                _getAIIntelligenceDescription(_aiIntelligenceLevel),
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStartGameButton() {
    return ElevatedButton(
      onPressed: _startGame,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
      child: const Text('开始游戏'),
    );
  }

  void _startGame() {
    // 默认进入Mission模式 - 关卡选择
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MissionSelectionScreen(
          aiIntelligenceLevel: _aiIntelligenceLevel,
          maxHealth: _maxHealth,
        ),
      ),
    );
  }

  /// 获取AI智能水平标签
  String _getAIIntelligenceLabel(double level) {
    if (level <= 0.7) return '简单';
    if (level <= 1.0) return '普通';
    if (level <= 1.3) return '困难';
    if (level <= 1.7) return '专家';
    return '大师';
  }

  /// 获取AI智能水平描述
  String _getAIIntelligenceDescription(double level) {
    if (level <= 0.7) return 'AI反应较慢，躲避间隔较长';
    if (level <= 1.0) return 'AI反应适中，平衡的游戏体验';
    if (level <= 1.3) return 'AI反应较快，躲避间隔较短';
    if (level <= 1.7) return 'AI反应很快，具有挑战性';
    return 'AI反应极快，最高难度挑战';
  }

  @override
  void dispose() {
    super.dispose();
  }
}
