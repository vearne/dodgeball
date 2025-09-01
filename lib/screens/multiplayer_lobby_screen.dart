import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:developer' as developer;

import '../game/game_mode.dart';
import '../game/team.dart';
import '../network/game_network_manager.dart';
import 'multiplayer_game_screen.dart';

/// 多人游戏大厅界面
class MultiplayerLobbyScreen extends StatefulWidget {
  final GameplayMode gameplayMode;
  final int? maxHealth;
  final TimeLimitOption? timeLimit;
  final String? serverUrl;
  final String? roomId;
  final String? playerId; // 如果是房主，会有这个ID
  final String? playerName; // 如果是房主，会有这个昵称
  final Map<String, dynamic>? roomData; // 如果是房主，会有这个房间数据

  const MultiplayerLobbyScreen({
    super.key,
    required this.gameplayMode,
    this.maxHealth,
    this.timeLimit,
    this.serverUrl,
    this.roomId,
    this.playerId,
    this.playerName,
    this.roomData,
  });

  @override
  State<MultiplayerLobbyScreen> createState() => _MultiplayerLobbyScreenState();
}

class _MultiplayerLobbyScreenState extends State<MultiplayerLobbyScreen> {
  final GameNetworkManager _networkManager = GameNetworkManager.instance;
  final TextEditingController _serverUrlController = TextEditingController();
  final TextEditingController _playerNameController = TextEditingController();

  NetworkGameState _gameState = NetworkGameState.disconnected;
  RoomInfo? _roomInfo;
  List<NetworkPlayer> _players = [];
  String? _connectionError;

  @override
  void initState() {
    super.initState();

    // 设置服务器地址
    _serverUrlController.text = widget.serverUrl ?? 'ws://localhost:8080/ws';

    // 如果有房主昵称，使用它，否则生成默认昵称
    if (widget.playerName != null) {
      _playerNameController.text = widget.playerName!;
    } else {
      _playerNameController.text =
          '玩家${DateTime.now().millisecondsSinceEpoch % 1000}';
    }

    // 监听网络状态变化
    _networkManager.gameStateNotifier.addListener(_onGameStateChanged);
    _networkManager.roomInfoNotifier.addListener(_onRoomInfoChanged);
    _networkManager.playersNotifier.addListener(_onPlayersChanged);

    _gameState = _networkManager.gameStateNotifier.value;

    // 如果是房主（有playerId），自动连接并加入房间
    if (widget.playerId != null && widget.roomId != null) {
      _autoConnectAsCreator();
    }
  }

  @override
  void dispose() {
    _networkManager.gameStateNotifier.removeListener(_onGameStateChanged);
    _networkManager.roomInfoNotifier.removeListener(_onRoomInfoChanged);
    _networkManager.playersNotifier.removeListener(_onPlayersChanged);
    _serverUrlController.dispose();
    _playerNameController.dispose();
    super.dispose();
  }

  void _onGameStateChanged() {
    if (mounted) {
      setState(() {
        final oldState = _gameState;
        _gameState = _networkManager.gameStateNotifier.value;

        developer.log('🔄 游戏状态变化: $oldState → $_gameState');

        // 如果进入游戏状态，跳转到游戏界面
        if (_gameState == NetworkGameState.inGame) {
          _navigateToGame();
        }
      });
    }
  }

  void _onRoomInfoChanged() {
    if (mounted) {
      setState(() {
        final oldRoomInfo = _roomInfo;
        _roomInfo = _networkManager.roomInfoNotifier.value;

        if (oldRoomInfo == null && _roomInfo != null) {
          developer.log('🏠 房间信息首次设置: ${_roomInfo!.id}');
        } else if (_roomInfo != null) {
          developer.log('🏠 房间信息更新: ${_roomInfo!.id}');
        }
      });
    }
  }

  void _onPlayersChanged() {
    if (mounted) {
      setState(() {
        _players = _networkManager.playersNotifier.value;
      });
    }
  }

  /// 连接到服务器
  Future<void> _connectToServer() async {
    if (_serverUrlController.text.isEmpty) {
      _showError('请输入服务器地址');
      return;
    }

    setState(() {
      _connectionError = null;
    });

    final success = await _networkManager.connectToServer(
      _serverUrlController.text.trim(),
    );
    if (!success) {
      _showError('连接服务器失败，请检查服务器地址和网络连接');
    }
  }

  /// 房主自动连接并加入房间
  Future<void> _autoConnectAsCreator() async {
    try {
      // 设置房主ID到网络管理器
      _networkManager.setCreatorId(widget.playerId!);

      // 设置房间ID
      _networkManager.setCurrentRoomId(widget.roomId!);

      // 自动连接到服务器
      final success = await _networkManager.connectToServer(
        _serverUrlController.text.trim(),
      );

      if (success) {
        // 房主创建房间后，通过WebSocket正式加入房间，但不显示加入中状态
        final playerName = _playerNameController.text.trim();
        developer.log('房主自动连接：房间ID=${widget.roomId}, 玩家名=${playerName}');
        developer.log('房间数据: ${widget.roomData}');

        _networkManager.joinRoomAsCreator(
          widget.roomId!,
          playerName,
          initialRoomData: widget.roomData,
        );

        // 请求房间状态更新（确保与服务器同步）
        _networkManager.requestRoomState();
      } else {
        _showError('连接服务器失败，请检查服务器地址和网络连接');
      }
    } catch (e) {
      _showError('自动连接失败: $e');
    }
  }

  /// 加入房间
  void _joinRoom() {
    if (_playerNameController.text.isEmpty) {
      _showError('请输入玩家昵称');
      return;
    }

    final roomId = widget.roomId ?? 'default_room';
    _networkManager.joinRoom(roomId, _playerNameController.text.trim());
  }

  /// 选择队伍
  void _selectTeam(Team team) {
    developer.log('🎯 UI: 选择队伍 ${team == Team.red ? "红队" : "蓝队"}');
    _networkManager.selectTeam(team);

    // 触发UI刷新以显示队伍变化
    setState(() {
      // UI状态将通过 _networkManager.currentTeam 更新
    });
  }

  /// 开始游戏
  void _startGame() {
    _networkManager.startGame();
  }

  /// 断开连接
  void _disconnect() {
    _networkManager.disconnect();
  }

  /// 显示错误信息
  void _showError(String message) {
    setState(() {
      _connectionError = message;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  /// 跳转到游戏界面
  void _navigateToGame() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => MultiplayerGameScreen(
          gameplayMode: widget.gameplayMode,
          maxHealth: widget.maxHealth,
          timeLimit: widget.timeLimit,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('多人游戏大厅 - ${_getGameModeTitle()}'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        actions: [
          if (_gameState != NetworkGameState.disconnected)
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: _disconnect,
              tooltip: '断开连接',
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
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                // 连接状态指示器
                _buildConnectionStatus(),
                const SizedBox(height: 20),

                // 根据状态显示不同内容
                Expanded(child: _buildContent()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 获取游戏模式标题
  String _getGameModeTitle() {
    switch (widget.gameplayMode) {
      case GameplayMode.elimination:
        return '淘汰赛';
      case GameplayMode.timeLimit:
        return '限时赛';
    }
  }

  /// 构建连接状态指示器
  Widget _buildConnectionStatus() {
    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (_gameState) {
      case NetworkGameState.disconnected:
        statusColor = Colors.red;
        statusText = '未连接';
        statusIcon = Icons.wifi_off;
        break;
      case NetworkGameState.connecting:
        statusColor = Colors.orange;
        statusText = '连接中...';
        statusIcon = Icons.wifi;
        break;
      case NetworkGameState.connected:
        statusColor = Colors.green;
        statusText = '已连接';
        statusIcon = Icons.wifi;
        break;
      case NetworkGameState.joiningRoom:
        statusColor = Colors.blue;
        statusText = '加入房间中...';
        statusIcon = Icons.group_add;
        break;
      case NetworkGameState.inRoom:
        statusColor = Colors.green;
        statusText = '在房间中';
        statusIcon = Icons.group;
        break;
      case NetworkGameState.inGame:
        statusColor = Colors.purple;
        statusText = '游戏中';
        statusIcon = Icons.sports_volleyball;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        border: Border.all(color: statusColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(statusIcon, color: statusColor),
          const SizedBox(width: 12),
          Text(
            statusText,
            style: TextStyle(
              color: statusColor,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建主要内容
  Widget _buildContent() {
    developer.log('🎨 构建内容，当前状态: $_gameState');

    switch (_gameState) {
      case NetworkGameState.disconnected:
      case NetworkGameState.connecting:
        developer.log('🎨 显示连接表单');
        return _buildConnectionForm();
      case NetworkGameState.connected:
        developer.log('🎨 显示加入房间表单');
        return _buildJoinRoomForm();
      case NetworkGameState.joiningRoom:
        developer.log('🎨 显示加入房间中...');
        return _buildLoadingWidget('加入房间中...');
      case NetworkGameState.inRoom:
        developer.log(
          '🎨 显示房间大厅，房间信息: ${_roomInfo != null ? _roomInfo!.id : "null"}',
        );
        return _buildRoomLobby();
      case NetworkGameState.inGame:
        developer.log('🎨 显示准备进入游戏...');
        return _buildLoadingWidget('准备进入游戏...');
    }
  }

  /// 构建连接表单
  Widget _buildConnectionForm() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Card(
          elevation: 8,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                const Icon(Icons.cloud_queue, size: 64, color: Colors.blue),
                const SizedBox(height: 20),
                const Text(
                  '连接游戏服务器',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),

                // 服务器地址输入
                TextField(
                  controller: _serverUrlController,
                  decoration: const InputDecoration(
                    labelText: '服务器地址',
                    hintText: 'ws://localhost:8080/ws',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.dns),
                  ),
                  enabled: _gameState != NetworkGameState.connecting,
                ),
                const SizedBox(height: 20),

                // 连接按钮
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _gameState == NetworkGameState.connecting
                        ? null
                        : _connectToServer,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _gameState == NetworkGameState.connecting
                        ? const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              ),
                              SizedBox(width: 12),
                              Text('连接中...'),
                            ],
                          )
                        : const Text('连接服务器'),
                  ),
                ),

                // 错误信息
                if (_connectionError != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      border: Border.all(color: Colors.red.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error, color: Colors.red.shade700),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _connectionError!,
                            style: TextStyle(color: Colors.red.shade700),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// 构建加入房间表单
  Widget _buildJoinRoomForm() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Card(
          elevation: 8,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                const Icon(Icons.meeting_room, size: 64, color: Colors.green),
                const SizedBox(height: 20),
                const Text(
                  '加入游戏房间',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),

                // 玩家昵称输入
                TextField(
                  controller: _playerNameController,
                  decoration: const InputDecoration(
                    labelText: '玩家昵称',
                    hintText: '请输入您的昵称',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                  maxLength: 20,
                  inputFormatters: [
                    FilteringTextInputFormatter.deny(RegExp(r'[<>"/\\]')),
                  ],
                ),
                const SizedBox(height: 20),

                // 加入房间按钮
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _joinRoom,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('加入房间'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// 构建房间大厅
  Widget _buildRoomLobby() {
    if (_roomInfo == null) {
      return _buildLoadingWidget('加载房间信息...');
    }

    final redPlayers = _players.where((p) => p.team == 'red').toList();
    final bluePlayers = _players.where((p) => p.team == 'blue').toList();

    return SingleChildScrollView(
      child: Column(
        children: [
          // 房间信息
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '房间ID: ${_roomInfo!.id.substring(0, 8)}...',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '游戏状态: ${_roomInfo!.isStarted ? "进行中" : "等待中"}',
                        style: TextStyle(
                          color: _roomInfo!.isStarted
                              ? Colors.green
                              : Colors.orange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('游戏模式: ${_getGameModeTitle()}'),
                  if (widget.gameplayMode == GameplayMode.elimination &&
                      widget.maxHealth != null)
                    Text('最大生命值: ${widget.maxHealth}'),
                  if (widget.gameplayMode == GameplayMode.timeLimit &&
                      widget.timeLimit != null)
                    Text('游戏时间: ${widget.timeLimit!.displayName}'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 队伍选择和玩家列表
          Row(
            children: [
              // 红队
              Expanded(child: _buildTeamCard(Team.red, redPlayers)),
              const SizedBox(width: 16),
              // 蓝队
              Expanded(child: _buildTeamCard(Team.blue, bluePlayers)),
            ],
          ),
          const SizedBox(height: 20),

          // 开始游戏按钮
          if (!_roomInfo!.isStarted)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _startGame,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  '开始游戏',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// 构建队伍卡片
  Widget _buildTeamCard(Team team, List<NetworkPlayer> players) {
    final isRed = team == Team.red;
    final teamColor = isRed ? Colors.red : Colors.blue;
    final teamName = isRed ? '红队' : '蓝队';
    final currentPlayerTeam = _networkManager.currentTeam;
    final isCurrentTeam = currentPlayerTeam == team;

    return Card(
      color: teamColor.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // 队伍标题
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  teamName,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: teamColor,
                  ),
                ),
                Text(
                  '${players.length}/6',
                  style: TextStyle(fontSize: 16, color: teamColor),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 加入队伍按钮
            if (currentPlayerTeam == null || !isCurrentTeam)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: players.length < 6
                      ? () => _selectTeam(team)
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: teamColor,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(players.length < 6 ? '加入$teamName' : '队伍已满'),
                ),
              ),

            if (isCurrentTeam) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: teamColor.shade200,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '已加入$teamName',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: teamColor.shade700,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],

            const SizedBox(height: 12),

            // 玩家列表
            ...players.map(
              (player) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Icon(
                      player.isAI ? Icons.smart_toy : Icons.person,
                      size: 16,
                      color: teamColor,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        player.name,
                        style: TextStyle(
                          color: teamColor.shade700,
                          fontWeight:
                              player.id == _networkManager.currentPlayerId
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                    if (!player.connected)
                      Icon(
                        Icons.wifi_off,
                        size: 16,
                        color: Colors.grey.shade600,
                      ),
                  ],
                ),
              ),
            ),

            // 添加AI玩家占位符
            if (players.length < 6) ...[
              for (int i = players.length; i < 6; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      Icon(
                        Icons.smart_toy,
                        size: 16,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'AI玩家',
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  /// 构建加载指示器
  Widget _buildLoadingWidget(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 20),
          Text(message, style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }
}
