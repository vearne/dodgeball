import 'package:flutter/material.dart';
import '../game/game_mode.dart';
import 'game_screen.dart';
import 'audio_settings_screen.dart';
import 'multiplayer_lobby_screen.dart';

class GameModeSelectorScreen extends StatelessWidget {
  const GameModeSelectorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('选择游戏模式'),
        centerTitle: true,
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        actions: [
          // 音频设置按钮
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const AudioSettingsScreen(),
                ),
              );
            },
            tooltip: '音频设置',
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade50, Colors.blue.shade100],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 游戏标题
                Container(
                  margin: const EdgeInsets.only(bottom: 50),
                  child: Column(
                    children: [
                      Icon(
                        Icons.sports_volleyball,
                        size: 80,
                        color: Colors.blue.shade700,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        '躲避球大战',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade800,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '选择您的游戏模式',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),

                // 游戏模式选择卡片
                Column(
                  children: [
                    // 淘汰赛模式卡片
                    _GameModeCard(
                      title: '淘汰赛',
                      subtitle: '经典模式',
                      description: '被球击中即淘汰\n最后存活的队伍获胜',
                      icon: Icons.sports_volleyball,
                      color: Colors.red,
                      onTap: () => _showEliminationSettings(context),
                    ),
                    const SizedBox(height: 20),
                    // 限时赛模式卡片
                    _GameModeCard(
                      title: '限时赛',
                      subtitle: '得分模式',
                      description: '被击中得分\n时间到统计分数',
                      icon: Icons.timer,
                      color: Colors.green,
                      onTap: () => _showTimeLimitSettings(context),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showEliminationSettings(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const _EliminationSettingsDialog(),
    );
  }

  void _showTimeLimitSettings(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const _TimeLimitSettingsDialog(),
    );
  }
}

// 淘汰赛设置对话框
class _EliminationSettingsDialog extends StatefulWidget {
  const _EliminationSettingsDialog();

  @override
  State<_EliminationSettingsDialog> createState() =>
      _EliminationSettingsDialogState();
}

class _EliminationSettingsDialogState
    extends State<_EliminationSettingsDialog> {
  int _selectedMaxHealth = 3;
  GameModeType _selectedGameMode = GameModeType.singlePlayer;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('淘汰赛设置'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 生命值设置
          const Text('设置玩家生命值：'),
          const SizedBox(height: 10),
          DropdownButtonFormField<int>(
            value: _selectedMaxHealth,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: '最大生命值',
            ),
            items: [1, 2, 3, 4, 5].map((health) {
              return DropdownMenuItem(value: health, child: Text('$health 次'));
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedMaxHealth = value!;
              });
            },
          ),
          const SizedBox(height: 20),

          // 游戏模式选择
          const Text('选择游戏模式：'),
          const SizedBox(height: 10),
          DropdownButtonFormField<GameModeType>(
            value: _selectedGameMode,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: '游戏模式',
            ),
            items: [
              DropdownMenuItem(
                value: GameModeType.singlePlayer,
                child: const Text('单人模式（与AI对战）'),
              ),
              DropdownMenuItem(
                value: GameModeType.multiPlayer,
                child: const Text('多人联机模式'),
              ),
            ],
            onChanged: (value) {
              setState(() {
                _selectedGameMode = value!;
              });
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
            if (_selectedGameMode == GameModeType.multiPlayer) {
              // 多人模式：跳转到多人大厅
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => MultiplayerLobbyScreen(
                    gameplayMode: GameplayMode.elimination,
                    maxHealth: _selectedMaxHealth,
                  ),
                ),
              );
            } else {
              // 单人模式：直接开始游戏
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => GameScreen(
                    gameMode: _selectedGameMode,
                    gameplayMode: GameplayMode.elimination,
                    maxHealth: _selectedMaxHealth,
                  ),
                ),
              );
            }
          },
          child: const Text('开始游戏'),
        ),
      ],
    );
  }
}

// 限时赛设置对话框
class _TimeLimitSettingsDialog extends StatefulWidget {
  const _TimeLimitSettingsDialog();

  @override
  State<_TimeLimitSettingsDialog> createState() =>
      _TimeLimitSettingsDialogState();
}

class _TimeLimitSettingsDialogState extends State<_TimeLimitSettingsDialog> {
  TimeLimitOption _selectedTimeLimit = TimeLimitOption.oneMinute;
  GameModeType _selectedGameMode = GameModeType.singlePlayer;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('限时赛设置'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 时间设置
          const Text('选择游戏时间：'),
          const SizedBox(height: 10),
          DropdownButtonFormField<TimeLimitOption>(
            value: _selectedTimeLimit,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: '游戏时间',
            ),
            items: TimeLimitOption.values.map((timeLimit) {
              return DropdownMenuItem(
                value: timeLimit,
                child: Text(timeLimit.displayName),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedTimeLimit = value!;
              });
            },
          ),
          const SizedBox(height: 20),

          // 游戏模式选择
          const Text('选择游戏模式：'),
          const SizedBox(height: 10),
          DropdownButtonFormField<GameModeType>(
            value: _selectedGameMode,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: '游戏模式',
            ),
            items: [
              DropdownMenuItem(
                value: GameModeType.singlePlayer,
                child: const Text('单人模式（与AI对战）'),
              ),
              DropdownMenuItem(
                value: GameModeType.multiPlayer,
                child: const Text('多人联机模式'),
              ),
            ],
            onChanged: (value) {
              setState(() {
                _selectedGameMode = value!;
              });
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
            if (_selectedGameMode == GameModeType.multiPlayer) {
              // 多人模式：跳转到多人大厅
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => MultiplayerLobbyScreen(
                    gameplayMode: GameplayMode.timeLimit,
                    timeLimit: _selectedTimeLimit,
                  ),
                ),
              );
            } else {
              // 单人模式：直接开始游戏
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => GameScreen(
                    gameMode: _selectedGameMode,
                    gameplayMode: GameplayMode.timeLimit,
                    timeLimit: _selectedTimeLimit,
                  ),
                ),
              );
            }
          },
          child: const Text('开始游戏'),
        ),
      ],
    );
  }
}

class _GameModeCard extends StatelessWidget {
  const _GameModeCard({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final String description;
  final IconData icon;
  final MaterialColor color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [color.shade100, color.shade200],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 图标
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: color.shade500,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 40, color: Colors.white),
              ),

              const SizedBox(height: 20),

              // 标题
              Text(
                title,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color.shade800,
                ),
              ),

              const SizedBox(height: 8),

              // 副标题
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: color.shade600,
                ),
              ),

              const SizedBox(height: 16),

              // 描述
              Text(
                description,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: color.shade700,
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 20),

              // 开始按钮
              ElevatedButton(
                onPressed: onTap,
                style: ElevatedButton.styleFrom(
                  backgroundColor: color.shade500,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: const Text(
                  '开始游戏',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
