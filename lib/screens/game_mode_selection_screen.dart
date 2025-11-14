import 'package:flutter/material.dart';
import '../game/game_mode.dart';
import 'room_list_screen.dart';
import 'game_screen.dart';
import 'server_info_screen.dart';
import 'mission_selection_screen.dart';

/// 游戏模式选择界面
class GameModeSelectionScreen extends StatefulWidget {
  const GameModeSelectionScreen({super.key});

  @override
  State<GameModeSelectionScreen> createState() =>
      _GameModeSelectionScreenState();
}

class _GameModeSelectionScreenState extends State<GameModeSelectionScreen> {
  GameplayMode _selectedGameplayMode = GameplayMode.elimination;
  int _maxHealth = 3;
  TimeLimitOption _timeLimit = TimeLimitOption.threeMinutes;
  PlayMode _selectedPlayMode = PlayMode.single;
  double _aiIntelligenceLevel = 1.0; // AI智能水平 0.5-2.0

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('躲避球游戏'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 游戏模式选择
            _buildGameModeSelection(),
            const SizedBox(height: 24),

            // 游戏参数设置
            _buildGameSettings(),
            const SizedBox(height: 24),

            // 游戏类型选择
            _buildPlayModeSelection(),
            const SizedBox(height: 24),

            // 服务器配置信息按钮（仅在多人模式时显示）
            if (_selectedPlayMode == PlayMode.multiplayer) ...[
              _buildServerInfoButton(),
              const SizedBox(height: 24),
            ],

            // 开始游戏按钮
            _buildStartGameButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildGameModeSelection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '游戏模式',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...GameplayMode.values.map(
              (mode) => RadioListTile<GameplayMode>(
                title: Text(mode.displayName),
                subtitle: Text(mode.description),
                value: mode,
                groupValue: _selectedGameplayMode,
                onChanged: (value) {
                  setState(() {
                    _selectedGameplayMode = value!;
                  });
                },
              ),
            ),
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

            if (_selectedGameplayMode == GameplayMode.elimination) ...[
              const Text(
                '生命值',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
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
            ],

            if (_selectedGameplayMode == GameplayMode.timeLimit) ...[
              const Text(
                '时间限制',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              ...TimeLimitOption.values.map(
                (option) => RadioListTile<TimeLimitOption>(
                  title: Text(option.displayName),
                  value: option,
                  groupValue: _timeLimit,
                  onChanged: (value) {
                    setState(() {
                      _timeLimit = value!;
                    });
                  },
                ),
              ),
            ],

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

            // 说明文字
            if (_selectedPlayMode == PlayMode.single) ...[
              const SizedBox(height: 8),
              const Text(
                '注意：此设置影响单人模式中的AI玩家行为',
                style: TextStyle(fontSize: 11, color: Colors.orange),
                textAlign: TextAlign.center,
              ),
            ] else ...[
              const SizedBox(height: 8),
              const Text(
                '注意：此设置将在创建房间时应用于多人游戏',
                style: TextStyle(fontSize: 11, color: Colors.blue),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPlayModeSelection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '游戏类型',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            RadioListTile<PlayMode>(
              title: const Text('单人模式（与AI对战）'),
              subtitle: const Text('与电脑AI进行对战'),
              value: PlayMode.single,
              groupValue: _selectedPlayMode,
              onChanged: (value) {
                setState(() {
                  _selectedPlayMode = value!;
                });
              },
            ),
            RadioListTile<PlayMode>(
              title: const Text('多人联机模式'),
              subtitle: const Text('与其他玩家在线对战'),
              value: PlayMode.multiplayer,
              groupValue: _selectedPlayMode,
              onChanged: (value) {
                setState(() {
                  _selectedPlayMode = value!;
                });
              },
            ),
            RadioListTile<PlayMode>(
              title: const Text('Mission模式（关卡挑战）'),
              subtitle: const Text('消灭敌人，完成关卡挑战'),
              value: PlayMode.mission,
              groupValue: _selectedPlayMode,
              onChanged: (value) {
                setState(() {
                  _selectedPlayMode = value!;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServerInfoButton() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '服务器配置',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              '服务器配置已从配置文件自动读取，无需手动设置',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const ServerInfoScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.info_outline),
              label: const Text('查看服务器配置信息'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.blue,
                side: const BorderSide(color: Colors.blue),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStartGameButton() {
    String buttonText;
    switch (_selectedPlayMode) {
      case PlayMode.single:
        buttonText = '开始单人游戏';
        break;
      case PlayMode.multiplayer:
        buttonText = '进入多人大厅';
        break;
      case PlayMode.mission:
        buttonText = '选择关卡';
        break;
    }

    return ElevatedButton(
      onPressed: _startGame,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
      child: Text(buttonText),
    );
  }

  void _startGame() {
    if (_selectedPlayMode == PlayMode.mission) {
      // Mission模式 - 进入关卡选择
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => MissionSelectionScreen(
            aiIntelligenceLevel: _aiIntelligenceLevel,
          ),
        ),
      );
      return;
    }

    final gameMode = GameMode(
      gameplayMode: _selectedGameplayMode,
      maxHealth: _selectedGameplayMode == GameplayMode.elimination
          ? _maxHealth
          : null,
      timeLimit: _selectedGameplayMode == GameplayMode.timeLimit
          ? _timeLimit
          : null,
    );

    if (_selectedPlayMode == PlayMode.single) {
      // 单人模式
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => GameScreen(
            gameMode: GameModeType.singlePlayer,
            gameplayMode: gameMode.gameplayMode,
            maxHealth: gameMode.maxHealth,
            timeLimit: gameMode.timeLimit,
            aiIntelligenceLevel: _aiIntelligenceLevel,
          ),
        ),
      );
    } else {
      // 多人模式 - 进入房间列表
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => RoomListScreen(
            gameMode: gameMode,
            aiIntelligenceLevel: _aiIntelligenceLevel,
          ),
        ),
      );
    }
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

/// 游戏类型
enum PlayMode {
  single('单人模式'),
  multiplayer('多人模式'),
  mission('Mission模式');

  const PlayMode(this.displayName);
  final String displayName;
}
