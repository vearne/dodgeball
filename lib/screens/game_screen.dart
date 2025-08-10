import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import '../game/dodgeball_game.dart';
import '../game/game_mode.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key, required this.gameMode});

  final GameMode gameMode;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late DodgeballGame game;

  @override
  void initState() {
    super.initState();
    game = DodgeballGame(gameMode: widget.gameMode);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_getGameModeTitle()),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: _showControlsHelp,
            tooltip: '控制说明',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _restartGame,
            tooltip: '重新开始',
          ),
        ],
      ),
      body: Stack(
        children: [
          // 游戏区域
          GameWidget(game: game),

          // 顶部冷却与得分条（缩短宽度避免遮挡）
          Positioned(
            top: 10,
            left: 100,
            right: 100,
            child: ValueListenableBuilder<double>(
              valueListenable: game.humanCooldownRemainingNotifier,
              builder: (context, remaining, _) {
                final total = 10.0; // 与 PlayerComponent.throwCooldown 保持一致
                final progress = (total - remaining) / total;
                final clamped = progress.clamp(0.0, 1.0);
                final isReady = remaining <= 0.001;
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // 冷却图标和文本
                    Icon(
                      isReady ? Icons.bolt : Icons.hourglass_empty,
                      color: isReady ? Colors.greenAccent : Colors.amber,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isReady ? '可投掷' : '冷却：${remaining.toStringAsFixed(1)}s',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        shadows: [Shadow(color: Colors.black, blurRadius: 2)],
                      ),
                    ),
                    const SizedBox(width: 10),
                    // 进度条（缩短长度）
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: clamped,
                          minHeight: 8,
                          backgroundColor: Colors.black26,
                          valueColor: AlwaysStoppedAnimation(
                            isReady ? Colors.greenAccent : Colors.amber,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    // 分数显示
                    ValueListenableBuilder<int>(
                      valueListenable: game.humanScoreNotifier,
                      builder: (context, score, __) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.emoji_events,
                                size: 16,
                                color: Colors.yellow,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '分数: $score',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                );
              },
            ),
          ),

          // 游戏模式指示器
          Positioned(
            top: 10,
            left: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(_getGameModeIcon(), color: Colors.white, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    _getGameModeTitle(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 控制说明
          Positioned(
            bottom: 10,
            left: 10,
            right: 10,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _getControlInstructions(),
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                  if (widget.gameMode == GameMode.singlePlayer) ...[
                    const SizedBox(height: 4),
                    const Text(
                      '提示：红队第一个玩家是您，其他玩家由AI控制',
                      style: TextStyle(
                        color: Colors.yellow,
                        fontSize: 10,
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getGameModeTitle() {
    switch (widget.gameMode) {
      case GameMode.singlePlayer:
        return '单人模式';
      case GameMode.multiPlayer:
        return '多人模式';
    }
  }

  IconData _getGameModeIcon() {
    switch (widget.gameMode) {
      case GameMode.singlePlayer:
        return Icons.person;
      case GameMode.multiPlayer:
        return Icons.group;
    }
  }

  String _getControlInstructions() {
    switch (widget.gameMode) {
      case GameMode.singlePlayer:
        return '控制说明：\n'
            'WASD移动 • 方向键瞄准 • 空格投球\n'
            '点击屏幕也可投球 • AI玩家自动行动';
      case GameMode.multiPlayer:
        return '控制说明：\n'
            '玩家1：WASD移动 • 方向键瞄准 • 空格投球\n'
            '玩家2：IJKL移动 • 数字键瞄准 • 0键投球\n'
            '也可点击屏幕投球';
    }
  }

  void _restartGame() {
    setState(() {
      game = DodgeballGame(gameMode: widget.gameMode);
    });
  }

  void _showControlsHelp() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('控制说明'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.gameMode == GameMode.singlePlayer) ...[
                  const Text(
                    '单人模式',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  _buildControlSection('键盘控制', [
                    'WASD键 - 移动玩家',
                    '方向键 - 瞄准方向',
                    '空格键 - 投掷球',
                  ]),
                  const SizedBox(height: 10),

                  const SizedBox(height: 10),
                  _buildControlSection('触屏控制', [
                    '点击屏幕 - 投掷球到点击位置',
                    '双击屏幕 - AI队友投球',
                  ]),
                  const SizedBox(height: 10),
                  const Text(
                    '注意：除了您（红队第一个玩家）外，其他玩家都由AI控制',
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      color: Colors.orange,
                    ),
                  ),
                ] else ...[
                  const Text(
                    '多人模式',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  _buildControlSection('玩家1控制', [
                    'WASD键 - 移动',
                    '方向键 - 瞄准方向',
                    '空格键 - 投掷球',
                  ]),
                  const SizedBox(height: 10),
                  _buildControlSection('玩家2控制', [
                    'IJKL键 - 移动',
                    '数字键8456 - 瞄准方向',
                    '数字键0 - 投掷球',
                  ]),
                  const SizedBox(height: 10),

                  const SizedBox(height: 10),
                  _buildControlSection('触屏控制', ['点击屏幕 - 红队投球', '双击屏幕 - 蓝队投球']),
                ],
                const SizedBox(height: 15),
                const Text(
                  '游戏目标',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 5),
                const Text(
                  '用球击中对方队员将其淘汰，保护自己的队员不被击中。球会在墙壁上反弹，利用反弹击中敌人！',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('知道了'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildControlSection(String title, List<String> controls) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 5),
        ...controls.map(
          (control) => Padding(
            padding: const EdgeInsets.only(left: 10, bottom: 2),
            child: Text('• $control'),
          ),
        ),
      ],
    );
  }
}
