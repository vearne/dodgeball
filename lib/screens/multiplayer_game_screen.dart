import 'package:flutter/material.dart';
import 'package:flame/game.dart';

import '../game/game_mode.dart';
import '../game/multiplayer_dodgeball_game.dart';
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
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('游戏暂停'),
        content: const Text('确定要离开游戏吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('继续游戏'),
          ),
          TextButton(
            onPressed: () {
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
            // 游戏主体 - 使用FittedBox确保1280x720分辨率正确缩放
            Center(
              child: AspectRatio(
                aspectRatio: 1280 / 720, // 保持16:9的宽高比
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black, width: 2),
                  ),
                  child: GameWidget.controlled(gameFactory: () => _game),
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
