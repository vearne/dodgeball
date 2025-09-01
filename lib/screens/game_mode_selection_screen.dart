import 'package:flutter/material.dart';
import '../game/game_mode.dart';
import 'room_list_screen.dart';
import 'game_screen.dart';

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

  final TextEditingController _serverUrlController = TextEditingController(
    text: 'ws://localhost:8080/ws',
  );

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

            // 多人游戏服务器设置
            if (_selectedPlayMode == PlayMode.multiplayer) ...[
              _buildServerSettings(),
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
          ],
        ),
      ),
    );
  }

  Widget _buildServerSettings() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '服务器设置',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _serverUrlController,
              decoration: const InputDecoration(
                labelText: '服务器地址',
                hintText: 'ws://localhost:8080/ws',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.cloud),
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
      child: Text(_selectedPlayMode == PlayMode.single ? '开始单人游戏' : '进入多人大厅'),
    );
  }

  void _startGame() {
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
          ),
        ),
      );
    } else {
      // 多人模式 - 进入房间列表
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => RoomListScreen(
            gameMode: gameMode,
            serverUrl: _serverUrlController.text.trim(),
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _serverUrlController.dispose();
    super.dispose();
  }
}

/// 游戏类型
enum PlayMode {
  single('单人模式'),
  multiplayer('多人模式');

  const PlayMode(this.displayName);
  final String displayName;
}
