import 'dart:async';
import 'dart:developer' as developer;
import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';

import '../game/team.dart';
import 'websocket_client.dart';

/// 游戏网络管理器，负责处理多人游戏的网络通信
class GameNetworkManager {
  static GameNetworkManager? _instance;
  static GameNetworkManager get instance =>
      _instance ??= GameNetworkManager._();

  GameNetworkManager._();

  final WebSocketClient _client = WebSocketClient();

  // 暴露client供游戏使用
  WebSocketClient get client => _client;

  // 游戏状态
  String? _currentRoomId;
  String? _currentPlayerId;
  Team? _currentTeam;
  bool _isInGame = false;
  String? _pendingRoomId; // 等待加入的房间ID
  String? _creatorId; // 房主ID（如果是房主）

  // 状态通知器
  final ValueNotifier<NetworkGameState> _gameStateNotifier = ValueNotifier(
    NetworkGameState.disconnected,
  );
  final ValueNotifier<RoomInfo?> _roomInfoNotifier = ValueNotifier(null);
  final ValueNotifier<List<NetworkPlayer>> _playersNotifier = ValueNotifier([]);

  // 访问器
  ValueNotifier<NetworkGameState> get gameStateNotifier => _gameStateNotifier;
  ValueNotifier<RoomInfo?> get roomInfoNotifier => _roomInfoNotifier;
  ValueNotifier<List<NetworkPlayer>> get playersNotifier => _playersNotifier;

  bool get isConnected => _client.isConnected;
  bool get isInGame => _isInGame;
  String? get currentPlayerId => _currentPlayerId;
  Team? get currentTeam => _currentTeam;
  String? get currentRoomId => _currentRoomId;
  bool get isRoomCreator =>
      _creatorId != null && _creatorId == _currentPlayerId;

  /// 连接到游戏服务器
  Future<bool> connectToServer(String serverUrl) async {
    try {
      _gameStateNotifier.value = NetworkGameState.connecting;

      // 注册消息处理器
      _registerMessageHandlers();

      final success = await _client.connect(serverUrl);
      if (success) {
        _gameStateNotifier.value = NetworkGameState.connected;
        developer.log('成功连接到游戏服务器');
        return true;
      } else {
        _gameStateNotifier.value = NetworkGameState.disconnected;
        developer.log('连接游戏服务器失败');
        return false;
      }
    } catch (e) {
      _gameStateNotifier.value = NetworkGameState.disconnected;
      developer.log('连接服务器异常: $e');
      return false;
    }
  }

  /// 断开服务器连接
  Future<void> disconnect() async {
    await _client.disconnect();
    _resetState();
    _gameStateNotifier.value = NetworkGameState.disconnected;
  }

  /// 自动重连
  Future<void> reconnect() async {
    if (_client.isConnected) return;

    _gameStateNotifier.value = NetworkGameState.connecting;

    // 尝试重连
    final success = await _client.reconnect();
    if (success) {
      // 重连成功后，如果之前在房间中，尝试重新加入
      if (_currentRoomId != null && _currentPlayerId != null) {
        developer.log('重连成功，重新加入房间: $_currentRoomId');
        // 重新发送加入房间消息
        _client.sendMessage({
          'type': MessageType.joinRoom,
          'room_id': _currentRoomId,
          'player_id': _currentPlayerId,
        });
        _gameStateNotifier.value = NetworkGameState.joiningRoom;
      } else {
        developer.log('重连成功');
        _gameStateNotifier.value = NetworkGameState.connected;
      }
    } else {
      developer.log('重连失败');
      _gameStateNotifier.value = NetworkGameState.disconnected;
    }
  }

  /// 加入房间
  void joinRoom(String roomId, String playerName) {
    if (!_client.isConnected) {
      developer.log('未连接到服务器，无法加入房间');
      return;
    }

    _pendingRoomId = roomId;
    _client.sendMessage({
      'type': MessageType.joinRoom,
      'room_id': roomId,
      'name': playerName,
    });
    _gameStateNotifier.value = NetworkGameState.joiningRoom;
  }

  /// 选择队伍
  void selectTeam(Team team) {
    if (_currentPlayerId == null || _currentRoomId == null) {
      developer.log('⚽ 玩家ID或房间ID为空，无法选择队伍');
      developer.log('⚽ 玩家ID: $_currentPlayerId, 房间ID: $_currentRoomId');
      return;
    }

    final teamString = team == Team.red ? 'red' : 'blue';
    developer.log('⚽ 选择队伍: $teamString');

    // 先更新本地状态，即使WebSocket暂时断开
    final oldTeam = _currentTeam;
    _currentTeam = team;
    developer.log('⚽ 队伍已更新: $oldTeam → $_currentTeam');

    // 如果WebSocket连接正常，发送消息给服务器
    if (_client.isConnected) {
      developer.log('⚽ WebSocket已连接，发送队伍选择消息');
      _client.sendMessage({
        'type': MessageType.selectTeam,
        'room_id': _currentRoomId,
        'player_id': _currentPlayerId,
        'team': teamString,
      });
    } else {
      developer.log('⚽ WebSocket暂时断开，队伍选择将在重连后同步');
      // 可以在这里缓存消息，等重连后发送
    }

    // 触发UI更新 - 更新玩家列表以反映队伍变化
    if (_roomInfoNotifier.value != null && _currentPlayerId != null) {
      developer.log('⚽ 触发UI刷新以显示队伍变化');

      // 更新当前玩家在玩家列表中的队伍信息
      final currentPlayers = List<NetworkPlayer>.from(_playersNotifier.value);
      final playerIndex = currentPlayers.indexWhere(
        (p) => p.id == _currentPlayerId,
      );

      if (playerIndex >= 0) {
        // 更新现有玩家的队伍
        final oldPlayer = currentPlayers[playerIndex];
        final updatedPlayer = NetworkPlayer(
          id: oldPlayer.id,
          name: oldPlayer.name,
          team: teamString,
          isAI: oldPlayer.isAI,
          position: oldPlayer.position,
          velocity: oldPlayer.velocity,
          direction: oldPlayer.direction,
          isAlive: oldPlayer.isAlive,
          connected: oldPlayer.connected,
          radius: oldPlayer.radius,
        );
        currentPlayers[playerIndex] = updatedPlayer;
        developer.log('⚽ 更新现有玩家队伍: ${oldPlayer.team} → $teamString');
      } else {
        // 从当前玩家列表中获取玩家信息，如果没有则使用默认名字
        String playerName = 'You';
        final existingPlayer = currentPlayers.firstWhere(
          (p) => p.id == _currentPlayerId,
          orElse: () => NetworkPlayer(
            id: '',
            name: '',
            team: '',
            isAI: false,
            position: Vector2.zero(),
            velocity: Vector2.zero(),
            direction: Vector2.zero(),
            isAlive: true,
            connected: true,
            radius: 0,
          ),
        );
        if (existingPlayer.id.isNotEmpty) {
          playerName = existingPlayer.name;
          developer.log('⚽ 从玩家列表获取玩家名字: $playerName');
        }

        // 创建新的玩家条目（如果还不存在）
        final newPlayer = NetworkPlayer(
          id: _currentPlayerId!,
          name: playerName,
          team: teamString,
          isAI: false,
          position: Vector2.zero(),
          velocity: Vector2.zero(),
          direction: Vector2(1, 0),
          isAlive: true,
          connected: true,
          radius: 15.0,
        );
        currentPlayers.add(newPlayer);
        developer.log('⚽ 添加新玩家到列表: $teamString, 名字: $playerName');
      }

      _playersNotifier.value = currentPlayers;
      developer.log('⚽ 玩家列表已更新，总数: ${currentPlayers.length}');

      // 统计队伍人数
      final redCount = currentPlayers.where((p) => p.team == 'red').length;
      final blueCount = currentPlayers.where((p) => p.team == 'blue').length;
      developer.log('⚽ 队伍统计: 红队$redCount人，蓝队$blueCount人');

      // 同时触发房间信息通知
      _roomInfoNotifier.value = _roomInfoNotifier.value;
    }
  }

  /// 开始游戏
  void startGame() {
    if (!_client.isConnected ||
        _currentPlayerId == null ||
        _currentRoomId == null) {
      developer.log('未在房间中，无法开始游戏');
      return;
    }

    _client.sendMessage({
      'type': MessageType.startGame,
      'room_id': _currentRoomId,
    });
  }

  /// 发送游戏输入
  void sendInput({
    required Vector2 move,
    required bool throwBall,
    required Vector2 aim,
  }) {
    if (!_client.isConnected ||
        _currentPlayerId == null ||
        _currentRoomId == null ||
        !_isInGame) {
      return;
    }

    _client.sendMessage({
      'type': MessageType.input,
      'room_id': _currentRoomId,
      'player_id': _currentPlayerId,
      'move': {'x': move.x, 'y': move.y},
      'throw': throwBall,
      'aim': {'x': aim.x, 'y': aim.y},
    });
  }

  /// 注册消息处理器
  void _registerMessageHandlers() {
    _client.registerHandler(MessageType.connected, _handleConnected); // 处理连接成功
    _client.registerHandler(MessageType.roomState, _handleRoomState);
    _client.registerHandler(MessageType.playerJoined, _handlePlayerJoined);
    _client.registerHandler(MessageType.playerLeft, _handlePlayerLeft);
    _client.registerHandler(MessageType.gameStarted, _handleGameStarted);
    _client.registerHandler(MessageType.gameEnded, _handleGameEnded);
    _client.registerHandler(MessageType.error, _handleError);
  }

  /// 处理连接成功消息
  void _handleConnected(Map<String, dynamic> message) {
    developer.log('WebSocket连接成功');

    // 只有在断开连接或连接中状态时才设置为已连接
    // 不要覆盖更高级的状态（如 inRoom, inGame）
    final currentState = _gameStateNotifier.value;
    if (currentState == NetworkGameState.disconnected ||
        currentState == NetworkGameState.connecting) {
      developer.log('🔄 WebSocket连接成功，更新状态为 connected');
      _gameStateNotifier.value = NetworkGameState.connected;
    } else {
      developer.log('🔄 WebSocket连接成功，保持当前状态: $currentState');
    }
  }

  /// 处理房间状态更新
  void _handleRoomState(Map<String, dynamic> message) {
    try {
      final roomData = message['room'] as Map<String, dynamic>;

      // 更新房间信息
      _currentRoomId = roomData['id'];
      final roomInfo = RoomInfo.fromJson(roomData);
      _roomInfoNotifier.value = roomInfo;

      // 更新玩家列表
      final playersData = roomData['players'] as Map<String, dynamic>? ?? {};
      final players = playersData.values
          .cast<Map<String, dynamic>>()
          .map((playerData) => NetworkPlayer.fromJson(playerData))
          .toList();
      _playersNotifier.value = players;

      // 更新游戏状态
      if (roomData['is_started'] == true) {
        if (!_isInGame) {
          _isInGame = true;
          _gameStateNotifier.value = NetworkGameState.inGame;
        }
      } else {
        if (_isInGame) {
          _isInGame = false;
          _gameStateNotifier.value = NetworkGameState.inRoom;
        }
      }

      // 如果还没有玩家ID，尝试从房间中找到自己
      if (_currentPlayerId == null) {
        // 这里需要根据实际的协议来确定如何识别当前玩家
        // 暂时使用第一个连接的玩家作为当前玩家
        final connectedPlayers = players.where((p) => p.connected).toList();
        if (connectedPlayers.isNotEmpty) {
          _currentPlayerId = connectedPlayers.first.id;
          _gameStateNotifier.value = NetworkGameState.inRoom;
        }
      } else {
        // 如果已有玩家ID，确保状态正确
        if (!_isInGame) {
          _gameStateNotifier.value = NetworkGameState.inRoom;
        }
      }

      // 通知游戏有新的房间状态数据
      _notifyGameStateUpdate(message);
    } catch (e) {
      developer.log('处理房间状态失败: $e');
    }
  }

  // 游戏状态更新回调
  Function(Map<String, dynamic>)? _gameStateUpdateCallback;

  /// 设置游戏状态更新回调
  void setGameStateUpdateCallback(Function(Map<String, dynamic>) callback) {
    _gameStateUpdateCallback = callback;
  }

  /// 通知游戏状态更新
  void _notifyGameStateUpdate(Map<String, dynamic> message) {
    _gameStateUpdateCallback?.call(message);
  }

  /// 处理玩家加入
  void _handlePlayerJoined(Map<String, dynamic> message) {
    developer.log('🎭 玩家加入: $message');

    // 如果这是当前玩家加入的消息，保存玩家ID
    final playerId = message['player_id'] as String?;
    final roomId = message['room_id'] as String?;

    developer.log('🎭 当前玩家ID: $_currentPlayerId, 消息中玩家ID: $playerId');

    // 如果还没有玩家ID，或者这是当前玩家的加入消息，设置状态
    if (playerId != null) {
      if (_currentPlayerId == null) {
        developer.log('🎭 设置玩家ID: $playerId');
        _currentPlayerId = playerId;
      }

      // 如果这是当前玩家的加入消息，更新状态为在房间中
      if (_currentPlayerId == playerId) {
        developer.log('🎯 确认当前玩家加入，更新状态为 inRoom');
        _gameStateNotifier.value = NetworkGameState.inRoom;
        developer.log('🔔 触发游戏状态通知: inRoom');
      } else {
        developer.log('🎭 这不是当前玩家的加入消息');
      }
    }

    if (roomId != null && _currentRoomId == null) {
      _currentRoomId = roomId;
      developer.log('当前房间ID设置为: $_currentRoomId');
    }

    // 更新房间状态
    final roomData = message['room'] as Map<String, dynamic>?;
    if (roomData != null) {
      final roomInfo = RoomInfo.fromJson(roomData);
      _roomInfoNotifier.value = roomInfo;

      // 更新玩家列表
      final playersData = roomData['players'] as Map<String, dynamic>? ?? {};
      final players = playersData.values
          .cast<Map<String, dynamic>>()
          .map((playerData) => NetworkPlayer.fromJson(playerData))
          .toList();
      _playersNotifier.value = players;
    }
  }

  /// 处理玩家离开
  void _handlePlayerLeft(Map<String, dynamic> message) {
    developer.log('玩家离开: $message');
    // 这个事件通常会伴随房间状态更新，所以不需要特别处理
  }

  /// 处理游戏开始
  void _handleGameStarted(Map<String, dynamic> message) {
    developer.log('游戏开始: $message');
    _isInGame = true;
    _gameStateNotifier.value = NetworkGameState.inGame;
  }

  /// 处理游戏结束
  void _handleGameEnded(Map<String, dynamic> message) {
    developer.log('游戏结束: $message');
    _isInGame = false;
    _gameStateNotifier.value = NetworkGameState.inRoom;
  }

  /// 处理错误消息
  void _handleError(Map<String, dynamic> message) {
    final error = message['error'] ?? '未知错误';
    developer.log('服务器错误: $error');
    // 可以通过另一个通知器来传递错误信息给UI
  }

  /// 设置房主ID（当创建房间时）
  void setCreatorId(String creatorId) {
    _creatorId = creatorId;
    _currentPlayerId = creatorId;
  }

  /// 设置当前房间ID
  void setCurrentRoomId(String roomId) {
    _currentRoomId = roomId;
  }

  /// 房主加入已创建的房间（不显示加入中状态）
  void joinRoomAsCreator(
    String roomId,
    String playerName, {
    Map<String, dynamic>? initialRoomData,
  }) {
    if (!_client.isConnected) {
      developer.log('未连接到服务器，无法加入房间');
      return;
    }

    _pendingRoomId = roomId;
    _client.sendMessage({
      'type': MessageType.joinRoom,
      'room_id': roomId,
      'name': playerName,
      'is_creator': true, // 标记这是房主
    });

    // 如果有初始房间数据，立即设置房间信息
    if (initialRoomData != null) {
      try {
        developer.log('=== 开始设置房主房间信息 ===');
        developer.log('房间数据类型: ${initialRoomData.runtimeType}');
        developer.log('房间数据内容: $initialRoomData');

        // 检查必要字段
        final requiredFields = [
          'id',
          'red_count',
          'blue_count',
          'is_started',
          'tick',
        ];
        for (final field in requiredFields) {
          if (!initialRoomData.containsKey(field)) {
            developer.log('警告: 缺少必要字段 $field');
          } else {
            developer.log('字段 $field: ${initialRoomData[field]}');
          }
        }

        final roomInfo = RoomInfo.fromJson(initialRoomData);
        _roomInfoNotifier.value = roomInfo;

        // 从房间数据中解析玩家列表
        final players = <NetworkPlayer>[];
        if (initialRoomData.containsKey('players') &&
            initialRoomData['players'] is Map) {
          final playersMap = initialRoomData['players'] as Map<String, dynamic>;
          for (final entry in playersMap.entries) {
            try {
              final playerData = entry.value as Map<String, dynamic>;
              final player = NetworkPlayer.fromJson(playerData);
              players.add(player);
              developer.log(
                '✅ 解析玩家: ${player.name} (${player.id}), 队伍: ${player.team}',
              );
            } catch (e) {
              developer.log('❌ 解析玩家失败: $e, 数据: ${entry.value}');
            }
          }
        }
        _playersNotifier.value = players;
        developer.log('👥 初始化玩家列表，共 ${players.length} 人');

        developer.log('✅ 房主房间信息设置成功: ${roomInfo.id}');
        developer.log(
          '房间状态: 红队${roomInfo.redCount}, 蓝队${roomInfo.blueCount}, 游戏${roomInfo.isStarted ? "已开始" : "未开始"}',
        );

        // 确保UI能接收到状态变化通知
        developer.log('🔔 触发房间信息通知');
      } catch (e, stackTrace) {
        developer.log('❌ 设置房主房间信息失败: $e');
        developer.log('堆栈跟踪: $stackTrace');
        developer.log('初始房间数据: $initialRoomData');
      }
    } else {
      developer.log('⚠️ 没有初始房间数据，等待服务器响应');
    }

    // 房主直接设置为在房间中，不显示加入中状态
    developer.log('🎯 设置房主游戏状态为 inRoom');
    _gameStateNotifier.value = NetworkGameState.inRoom;
    developer.log('🔔 触发游戏状态通知');
  }

  /// 设置游戏状态
  void setGameState(NetworkGameState state) {
    _gameStateNotifier.value = state;
  }

  /// 请求房间状态更新
  void requestRoomState() {
    if (!_client.isConnected || _currentRoomId == null) {
      developer.log('无法请求房间状态：未连接或房间ID为空');
      return;
    }

    _client.sendMessage({'type': 'get_room_state', 'room_id': _currentRoomId});
  }

  /// 重置状态
  void _resetState() {
    _currentRoomId = null;
    _currentPlayerId = null;
    _currentTeam = null;
    _isInGame = false;
    _pendingRoomId = null;
    _creatorId = null;
    _roomInfoNotifier.value = null;
    _playersNotifier.value = [];
  }

  /// 清理资源
  void dispose() {
    disconnect();
    _gameStateNotifier.dispose();
    _roomInfoNotifier.dispose();
    _playersNotifier.dispose();
    _client.dispose();
  }
}

/// 网络游戏状态
enum NetworkGameState {
  disconnected, // 未连接
  connecting, // 连接中
  connected, // 已连接但未在房间
  joiningRoom, // 加入房间中
  inRoom, // 在房间中
  inGame, // 游戏中
}

/// 房间信息
class RoomInfo {
  final String id;
  final int redCount;
  final int blueCount;
  final bool isStarted;
  final int tick;

  RoomInfo({
    required this.id,
    required this.redCount,
    required this.blueCount,
    required this.isStarted,
    required this.tick,
  });

  factory RoomInfo.fromJson(Map<String, dynamic> json) {
    return RoomInfo(
      id: json['id'] ?? '',
      redCount: json['red_count'] ?? 0,
      blueCount: json['blue_count'] ?? 0,
      isStarted: json['is_started'] ?? false,
      tick: json['tick'] ?? 0,
    );
  }
}

/// 网络玩家信息
class NetworkPlayer {
  final String id;
  final String name;
  final String team;
  final bool isAI;
  final Vector2 position;
  final Vector2 velocity;
  final bool isAlive;
  final bool connected;
  final double radius;
  final Vector2 direction; // 新增：玩家朝向方向

  NetworkPlayer({
    required this.id,
    required this.name,
    required this.team,
    required this.isAI,
    required this.position,
    required this.velocity,
    required this.isAlive,
    required this.connected,
    required this.radius,
    required this.direction, // 新增：玩家朝向方向
  });

  factory NetworkPlayer.fromJson(Map<String, dynamic> json) {
    final positionData =
        json['position'] as Map<String, dynamic>? ?? {'x': 0, 'y': 0};
    final velocityData =
        json['velocity'] as Map<String, dynamic>? ?? {'x': 0, 'y': 0};
    final directionData =
        json['direction'] as Map<String, dynamic>? ?? {'x': 1, 'y': 0}; // 默认朝右

    return NetworkPlayer(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      team: json['team'] ?? 'red',
      isAI: json['is_ai'] ?? false,
      position: Vector2(
        (positionData['x'] as num?)?.toDouble() ?? 0,
        (positionData['y'] as num?)?.toDouble() ?? 0,
      ),
      velocity: Vector2(
        (velocityData['x'] as num?)?.toDouble() ?? 0,
        (velocityData['y'] as num?)?.toDouble() ?? 0,
      ),
      direction: Vector2(
        (directionData['x'] as num?)?.toDouble() ?? 1,
        (directionData['y'] as num?)?.toDouble() ?? 0,
      ),
      isAlive: json['is_alive'] ?? true,
      connected: json['connected'] ?? false,
      radius: (json['radius'] as num?)?.toDouble() ?? 15.0,
    );
  }

  Team get teamEnum => team == 'red' ? Team.red : Team.blue;
}

/// 网络球信息
class NetworkBall {
  final String id;
  final Vector2 position;
  final Vector2 velocity;
  final bool active;
  final double radius;

  NetworkBall({
    required this.id,
    required this.position,
    required this.velocity,
    required this.active,
    required this.radius,
  });

  factory NetworkBall.fromJson(Map<String, dynamic> json) {
    final positionData =
        json['position'] as Map<String, dynamic>? ?? {'x': 0, 'y': 0};
    final velocityData =
        json['velocity'] as Map<String, dynamic>? ?? {'x': 0, 'y': 0};

    return NetworkBall(
      id: json['id'] ?? '',
      position: Vector2(
        (positionData['x'] as num?)?.toDouble() ?? 0,
        (positionData['y'] as num?)?.toDouble() ?? 0,
      ),
      velocity: Vector2(
        (velocityData['x'] as num?)?.toDouble() ?? 0,
        (velocityData['y'] as num?)?.toDouble() ?? 0,
      ),
      active: json['active'] ?? false,
      radius: (json['radius'] as num?)?.toDouble() ?? 8.0,
    );
  }
}
