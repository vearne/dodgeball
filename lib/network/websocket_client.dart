import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;

/// WebSocket客户端，用于与游戏服务器通信
class WebSocketClient {
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  bool _isConnected = false;
  String? _currentUrl;

  // 消息处理器
  final Map<String, Function(Map<String, dynamic>)> _messageHandlers = {};

  // 连接状态流控制器
  final StreamController<bool> _connectionController =
      StreamController<bool>.broadcast();
  Stream<bool> get connectionState => _connectionController.stream;

  bool get isConnected => _isConnected;

  /// 连接到WebSocket服务器
  Future<bool> connect(String url) async {
    try {
      _currentUrl = url;
      _channel = WebSocketChannel.connect(Uri.parse(url));

      // 监听消息
      _subscription = _channel!.stream.listen(
        _onMessage,
        onError: _onError,
        onDone: _onDone,
      );

      _isConnected = true;
      _connectionController.add(true);
      developer.log('WebSocket连接成功: $url');
      return true;
    } catch (e) {
      developer.log('WebSocket连接失败: $e');
      _isConnected = false;
      _connectionController.add(false);
      return false;
    }
  }

  /// 断开连接
  Future<void> disconnect() async {
    _isConnected = false;
    _connectionController.add(false);

    await _subscription?.cancel();
    await _channel?.sink.close(status.goingAway);

    _subscription = null;
    _channel = null;
    _currentUrl = null;

    developer.log('WebSocket连接已断开');
  }

  /// 发送消息
  void sendMessage(Map<String, dynamic> message) {
    if (!_isConnected || _channel == null) {
      developer.log('WebSocket未连接，无法发送消息: $message');
      return;
    }

    try {
      final jsonString = jsonEncode(message);
      _channel!.sink.add(jsonString);
      developer.log('发送消息: $jsonString');
    } catch (e) {
      developer.log('发送消息失败: $e');
    }
  }

  /// 注册消息处理器
  void registerHandler(
    String messageType,
    Function(Map<String, dynamic>) handler,
  ) {
    _messageHandlers[messageType] = handler;
  }

  /// 移除消息处理器
  void unregisterHandler(String messageType) {
    _messageHandlers.remove(messageType);
  }

  /// 处理接收到的消息
  void _onMessage(dynamic data) {
    try {
      final Map<String, dynamic> message = jsonDecode(data);
      final String? type = message['type'];

      developer.log('收到消息: $data');

      if (type != null && _messageHandlers.containsKey(type)) {
        _messageHandlers[type]!(message);
      } else {
        developer.log('未处理的消息类型: $type');
      }
    } catch (e) {
      developer.log('消息解析失败: $e');
    }
  }

  /// 处理连接错误
  void _onError(error) {
    developer.log('WebSocket错误: $error');
    _isConnected = false;
    _connectionController.add(false);
  }

  /// 处理连接关闭
  void _onDone() {
    developer.log('WebSocket连接关闭');
    _isConnected = false;
    _connectionController.add(false);

    // 可以在这里添加自动重连逻辑
    _scheduleReconnect();
  }

  /// 安排重连
  void _scheduleReconnect() {
    if (_currentUrl == null) return;

    // 3秒后尝试重连
    Future.delayed(const Duration(seconds: 3), () {
      if (!_isConnected && _currentUrl != null) {
        developer.log('尝试自动重连...');
        reconnect();
      }
    });
  }

  /// 尝试重连
  Future<bool> reconnect() async {
    if (_currentUrl == null) return false;

    await disconnect();
    await Future.delayed(const Duration(seconds: 1));
    return await connect(_currentUrl!);
  }

  /// 清理资源
  void dispose() {
    disconnect();
    _connectionController.close();
    _messageHandlers.clear();
  }
}

/// WebSocket消息类型
class MessageType {
  static const String joinRoom = 'join_room';
  static const String selectTeam = 'select_team';
  static const String startGame = 'start_game';
  static const String input = 'input';
  static const String roomState = 'room_state';
  static const String connected = 'connected'; // 连接成功消息
  static const String playerJoined = 'player_joined';
  static const String playerLeft = 'player_left';
  static const String gameStarted = 'game_started';
  static const String gameEnded = 'game_ended';
  static const String error = 'error';
}

/// 游戏输入消息
class GameInputMessage {
  final String playerId;
  final SimpleVector2 move;
  final bool throwBall;
  final SimpleVector2 aim;

  GameInputMessage({
    required this.playerId,
    required this.move,
    required this.throwBall,
    required this.aim,
  });

  Map<String, dynamic> toJson() {
    return {
      'type': MessageType.input,
      'player_id': playerId,
      'move': {'x': move.x, 'y': move.y},
      'throw': throwBall,
      'aim': {'x': aim.x, 'y': aim.y},
    };
  }
}

/// 简单的Vector2类（如果没有导入Flame的Vector2）
class SimpleVector2 {
  final double x;
  final double y;

  const SimpleVector2(this.x, this.y);

  SimpleVector2.zero() : x = 0, y = 0;

  Map<String, dynamic> toJson() => {'x': x, 'y': y};

  static SimpleVector2 fromJson(Map<String, dynamic> json) {
    return SimpleVector2(
      (json['x'] as num).toDouble(),
      (json['y'] as num).toDouble(),
    );
  }
}
