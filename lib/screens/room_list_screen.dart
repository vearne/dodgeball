import 'package:flutter/material.dart';
import 'dart:developer' as developer;
import 'package:dodgeball/game/game_mode.dart';
import 'package:dodgeball/network/http_client.dart';
import 'multiplayer_lobby_screen.dart';

/// 房间列表界面
class RoomListScreen extends StatefulWidget {
  final GameMode gameMode;
  final String serverUrl;
  final double aiIntelligenceLevel;

  const RoomListScreen({
    super.key,
    required this.gameMode,
    required this.serverUrl,
    this.aiIntelligenceLevel = 1.0,
  });

  @override
  State<RoomListScreen> createState() => _RoomListScreenState();
}

class _RoomListScreenState extends State<RoomListScreen> {
  final GameHttpClient _httpClient = GameHttpClient.instance;

  List<HttpRoomInfo> _rooms = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _httpClient.setBaseUrl(widget.serverUrl);
    _loadRoomList();
  }

  /// 加载房间列表
  Future<void> _loadRoomList() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final rooms = await _httpClient.getRoomList();
      setState(() {
        _rooms = rooms;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  /// 创建新房间
  Future<void> _createRoom() async {
    // 显示输入昵称对话框
    final playerName = await _showPlayerNameDialog();
    if (playerName == null || playerName.isEmpty) return;

    try {
      setState(() => _isLoading = true);

      final result = await _httpClient.createRoomWithGameSettings(
        playerName,
        widget.gameMode,
        widget.aiIntelligenceLevel,
      );

      developer.log('创建房间结果：房间ID=${result.roomId}, 房主ID=${result.playerId}');
      developer.log('房间数据：${result.roomData}');

      // 创建房间后直接进入房间
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => MultiplayerLobbyScreen(
              gameplayMode: widget.gameMode.gameplayMode,
              maxHealth: widget.gameMode.maxHealth,
              timeLimit: widget.gameMode.timeLimit,
              serverUrl: widget.serverUrl,
              roomId: result.roomId,
              playerId: result.playerId, // 传递房主ID
              playerName: playerName, // 传递玩家昵称
              roomData: result.roomData, // 传递房间数据
            ),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _error = '创建房间失败: $e';
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('创建房间失败: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  /// 显示玩家昵称输入对话框
  Future<String?> _showPlayerNameDialog() async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('输入玩家昵称'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: '请输入您的昵称',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
          onSubmitted: (value) => Navigator.of(context).pop(value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  /// 加入房间
  Future<void> _joinRoom(HttpRoomInfo room) async {
    if (room.isFull) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('房间已满'), backgroundColor: Colors.orange),
      );
      return;
    }

    if (room.isStarted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('游戏已开始'), backgroundColor: Colors.orange),
      );
      return;
    }

    // 直接进入房间大厅
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => MultiplayerLobbyScreen(
          gameplayMode: widget.gameMode.gameplayMode,
          maxHealth: widget.gameMode.maxHealth,
          timeLimit: widget.gameMode.timeLimit,
          serverUrl: widget.serverUrl,
          roomId: room.id,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.gameMode.displayName} - 房间列表'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadRoomList,
            tooltip: '刷新',
          ),
        ],
      ),
      body: Column(
        children: [
          // 创建房间按钮
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: _isLoading ? null : _createRoom,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text(
                '创建新房间',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),

          // 房间列表
          Expanded(child: _buildRoomList()),
        ],
      ),
    );
  }

  Widget _buildRoomList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              '加载失败',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red[300],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: TextStyle(color: Colors.red[300]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _loadRoomList, child: const Text('重试')),
          ],
        ),
      );
    }

    if (_rooms.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.meeting_room_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              '暂无房间',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text('点击上方按钮创建第一个房间吧！', style: TextStyle(color: Colors.grey[600])),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadRoomList,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _rooms.length,
        itemBuilder: (context, index) {
          final room = _rooms[index];
          return _buildRoomCard(room);
        },
      ),
    );
  }

  Widget _buildRoomCard(HttpRoomInfo room) {
    final canJoin = !room.isFull && !room.isStarted;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: canJoin ? () => _joinRoom(room) : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // 房间ID
                  Expanded(
                    child: Text(
                      '房间 ${room.id.substring(0, 8)}...',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  // 状态标签
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(room),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      room.statusText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  // 队伍信息
                  Expanded(
                    child: Row(
                      children: [
                        _buildTeamInfo('红队', room.redCount, Colors.red),
                        const SizedBox(width: 16),
                        _buildTeamInfo('蓝队', room.blueCount, Colors.blue),
                      ],
                    ),
                  ),

                  // 总人数
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${room.playerCount}/${room.maxPlayers}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),

              if (!canJoin) ...[
                const SizedBox(height: 8),
                Text(
                  room.isFull ? '房间已满，无法加入' : '游戏进行中，无法加入',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTeamInfo(String teamName, int count, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text('$teamName: $count', style: const TextStyle(fontSize: 14)),
      ],
    );
  }

  Color _getStatusColor(HttpRoomInfo room) {
    if (room.isStarted) return Colors.orange;
    if (room.isFull) return Colors.red;
    return Colors.green;
  }
}
