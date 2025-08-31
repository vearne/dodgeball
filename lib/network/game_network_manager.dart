import 'dart:async';
import 'dart:developer' as developer;
import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';

import '../game/game_mode.dart';
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
      if (_currentRoomId != null) {
        // 这里可以添加重新加入房间的逻辑
        developer.log('重连成功，但需要重新加入房间');
        _gameStateNotifier.value = NetworkGameState.connected;
      } else {
        _gameStateNotifier.value = NetworkGameState.connected;
      }
    } else {
      _gameStateNotifier.value = NetworkGameState.disconnected;
    }
  }

  /// 加入房间
  void joinRoom(String playerName) {
    if (!_client.isConnected) {
      developer.log('未连接到服务器，无法加入房间');
      return;
    }

    _client.sendMessage({'type': MessageType.joinRoom, 'name': playerName});
    _gameStateNotifier.value = NetworkGameState.joiningRoom;
  }

  /// 选择队伍
  void selectTeam(Team team) {
    if (!_client.isConnected || _currentPlayerId == null) {
      developer.log('未在房间中，无法选择队伍');
      return;
    }

    final teamString = team == Team.red ? 'red' : 'blue';
    _client.sendMessage({'type': MessageType.selectTeam, 'team': teamString});
    _currentTeam = team;
  }

  /// 开始游戏
  void startGame() {
    if (!_client.isConnected || _currentPlayerId == null) {
      developer.log('未在房间中，无法开始游戏');
      return;
    }

    _client.sendMessage({'type': MessageType.startGame});
  }

  /// 发送游戏输入
  void sendInput({
    required Vector2 move,
    required bool throwBall,
    required Vector2 aim,
  }) {
    if (!_client.isConnected || _currentPlayerId == null || !_isInGame) {
      return;
    }

    final inputMessage = GameInputMessage(
      playerId: _currentPlayerId!,
      move: SimpleVector2(move.x, move.y),
      throwBall: throwBall,
      aim: SimpleVector2(aim.x, aim.y),
    );

    _client.sendMessage(inputMessage.toJson());
  }

  /// 注册消息处理器
  void _registerMessageHandlers() {
    _client.registerHandler(MessageType.roomState, _handleRoomState);
    _client.registerHandler(MessageType.playerJoined, _handlePlayerJoined);
    _client.registerHandler(MessageType.playerLeft, _handlePlayerLeft);
    _client.registerHandler(MessageType.gameStarted, _handleGameStarted);
    _client.registerHandler(MessageType.gameEnded, _handleGameEnded);
    _client.registerHandler(MessageType.error, _handleError);
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
    developer.log('玩家加入: $message');
    // 这个事件通常会伴随房间状态更新，所以不需要特别处理
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

  /// 重置状态
  void _resetState() {
    _currentRoomId = null;
    _currentPlayerId = null;
    _currentTeam = null;
    _isInGame = false;
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
