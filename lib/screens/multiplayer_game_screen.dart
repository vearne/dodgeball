import 'package:flutter/material.dart';
import 'package:flame/game.dart';

import '../game/game_mode.dart';
import '../game/multiplayer_dodgeball_game.dart';
import '../game/audio_manager.dart';
import '../network/game_network_manager.dart';
import 'multiplayer_lobby_screen.dart';

/// 多人游戏界面
class MultiplayerGameScreen extends StatefulWidget {
  final GameplayMode gameplayMode;
  final int? maxHealth;
  final TimeLimitOption? timeLimit;

  const MultiplayerGameScreen({
    super.key,
    required this.gameplayMode,
    this.maxHealth,
    this.timeLimit,
  });

  @override
  State<MultiplayerGameScreen> createState() => _MultiplayerGameScreenState();
}

class _MultiplayerGameScreenState extends State<MultiplayerGameScreen> {
  final GameNetworkManager _networkManager = GameNetworkManager.instance;
  late MultiplayerDodgeballGame _game;
  bool _gameInitialized = false;

  @override
  void initState() {
    super.initState();

    _initializeGame();

    // 监听网络状态
    _networkManager.gameStateNotifier.addListener(_onGameStateChanged);
  }

  @override
  void dispose() {
    _networkManager.gameStateNotifier.removeListener(_onGameStateChanged);
    super.dispose();
  }

  void _initializeGame() {
    _game = MultiplayerDodgeballGame(
      gameMode: GameModeType.multiPlayer,
      gameplayMode: widget.gameplayMode,
      maxHealth: widget.maxHealth,
      timeLimit: widget.timeLimit,
      networkManager: _networkManager,
    );

    setState(() {
      _gameInitialized = true;
    });
  }

  void _onGameStateChanged() {
    final state = _networkManager.gameStateNotifier.value;

    // 如果网络连接断开或离开游戏，返回大厅
    if (state == NetworkGameState.disconnected ||
        state == NetworkGameState.inRoom) {
      _returnToLobby();
    }
  }

  void _returnToLobby() {
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => MultiplayerLobbyScreen(
            gameplayMode: widget.gameplayMode,
            maxHealth: widget.maxHealth,
            timeLimit: widget.timeLimit,
          ),
        ),
      );
    }
  }

  void _showPauseMenu() {
    // 暂停游戏引擎
    _game.pauseEngine();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('游戏暂停'),
        content: const Text('确定要离开游戏吗？'),
        actions: [
          TextButton(
            onPressed: () {
              // 恢复游戏引擎
              _game.resumeEngine();
              Navigator.of(context).pop();
            },
            child: const Text('继续游戏'),
          ),
          TextButton(
            onPressed: () {
              // 退出游戏时停止背景音乐
              AudioManager.instance.stopBackgroundMusic();
              Navigator.of(context).pop();
              _networkManager.disconnect();
            },
            child: const Text('离开游戏'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_gameInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

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
            // 游戏主体 - 使用FittedBox确保1280x720分辨率固定，不受窗口缩放影响
            Center(
              child: FittedBox(
                fit: BoxFit.contain,
                child: SizedBox(
                  width: 1280,
                  height: 720,
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.black, width: 2),
                    ),
                    child: GameWidget.controlled(gameFactory: () => _game),
                  ),
                ),
              ),
            ),

            // 顶部状态栏
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(child: _buildTopStatusBar()),
            ),

            // 冷却时间进度条和得分显示
            Positioned(
              top: 70,
              left: 100,
              right: 100,
              child: SafeArea(child: _buildCooldownAndScoreBar()),
            ),

            // 网络状态指示器
            Positioned(
              top: 60,
              right: 16,
              child: SafeArea(child: _buildNetworkStatus()),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建顶部状态栏
  Widget _buildTopStatusBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 返回按钮
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: _showPauseMenu,
            tooltip: '暂停游戏',
          ),

          // 游戏信息
          Expanded(
            child: ValueListenableBuilder<RoomInfo?>(
              valueListenable: _networkManager.roomInfoNotifier,
              builder: (context, roomInfo, child) {
                if (roomInfo == null) return const SizedBox.shrink();

                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '红队: ${roomInfo.redCount}',
                      style: const TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 20),
                    const Text(
                      'VS',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 20),
                    Text(
                      '蓝队: ${roomInfo.blueCount}',
                      style: const TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          // 设置按钮
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: _showPauseMenu,
            tooltip: '设置',
          ),
        ],
      ),
    );
  }

  /// 构建冷却时间进度条和得分显示
  Widget _buildCooldownAndScoreBar() {
    return ValueListenableBuilder<double>(
      valueListenable: _game.humanCooldownRemainingNotifier,
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
              valueListenable: _game.humanScoreNotifier,
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
    );
  }

  /// 构建网络状态指示器
  Widget _buildNetworkStatus() {
    return ValueListenableBuilder<NetworkGameState>(
      valueListenable: _networkManager.gameStateNotifier,
      builder: (context, state, child) {
        Color statusColor;
        IconData statusIcon;
        String tooltip;

        switch (state) {
          case NetworkGameState.disconnected:
            statusColor = Colors.red;
            statusIcon = Icons.wifi_off;
            tooltip = '网络断开';
            break;
          case NetworkGameState.connecting:
            statusColor = Colors.orange;
            statusIcon = Icons.wifi;
            tooltip = '连接中';
            break;
          case NetworkGameState.inGame:
            statusColor = Colors.green;
            statusIcon = Icons.wifi;
            tooltip = '网络正常';
            break;
          default:
            statusColor = Colors.grey;
            statusIcon = Icons.wifi;
            tooltip = '未知状态';
            break;
        }

        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.7),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Tooltip(
            message: tooltip,
            child: Icon(statusIcon, color: statusColor, size: 20),
          ),
        );
      },
    );
  }
}
