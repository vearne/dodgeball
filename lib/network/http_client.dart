import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;

/// HTTP客户端，用于与游戏服务器的REST API通信
class GameHttpClient {
  static GameHttpClient? _instance;
  static GameHttpClient get instance => _instance ??= GameHttpClient._();

  GameHttpClient._();

  String? _baseUrl;

  /// 设置服务器基础URL
  void setBaseUrl(String baseUrl) {
    // 从WebSocket URL转换为HTTP URL
    if (baseUrl.startsWith('ws://')) {
      _baseUrl = baseUrl
          .replaceFirst('ws://', 'http://')
          .replaceFirst('/ws', '');
    } else if (baseUrl.startsWith('http://')) {
      _baseUrl = baseUrl.replaceFirst('/ws', '');
    } else {
      _baseUrl = 'http://$baseUrl';
    }
    developer.log('HTTP客户端基础URL设置为: $_baseUrl');
  }

  /// 获取房间列表
  Future<List<HttpRoomInfo>> getRoomList() async {
    if (_baseUrl == null) {
      throw Exception('服务器URL未设置');
    }

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/rooms'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final roomsData = data['rooms'] as List<dynamic>?;

        // 如果没有房间，返回空列表
        if (roomsData == null) {
          return [];
        }

        return roomsData
            .cast<Map<String, dynamic>>()
            .map((roomData) => HttpRoomInfo.fromJson(roomData))
            .toList();
      } else {
        throw Exception('获取房间列表失败: ${response.statusCode}');
      }
    } catch (e) {
      developer.log('获取房间列表失败: $e');
      rethrow;
    }
  }

  /// 创建新房间
  Future<CreateRoomResult> createRoom(String creatorName) async {
    if (_baseUrl == null) {
      throw Exception('服务器URL未设置');
    }

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/rooms'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'name': creatorName}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final roomData = data['room'] as Map<String, dynamic>;
        final roomId = roomData['id'] as String;
        final playerId = data['player_id'] as String;

        developer.log('房间创建成功，ID: $roomId, 房主ID: $playerId');
        return CreateRoomResult(
          roomId: roomId,
          playerId: playerId,
          roomData: roomData,
        );
      } else {
        throw Exception('创建房间失败: ${response.statusCode}');
      }
    } catch (e) {
      developer.log('创建房间失败: $e');
      rethrow;
    }
  }

  /// 通过HTTP加入房间（用于获取玩家ID，实际游戏通过WebSocket）
  Future<JoinRoomResult> joinRoomHttp(String roomId, String playerName) async {
    if (_baseUrl == null) {
      throw Exception('服务器URL未设置');
    }

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/rooms/$roomId/join'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'name': playerName}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final playerId = data['player_id'] as String;
        final roomData = data['room'] as Map<String, dynamic>;

        developer.log('HTTP加入房间成功，玩家ID: $playerId');
        return JoinRoomResult(
          playerId: playerId,
          roomId: roomId,
          roomData: roomData,
        );
      } else {
        final errorData = jsonDecode(response.body) as Map<String, dynamic>;
        final errorMsg = errorData['error'] as String? ?? '未知错误';
        throw Exception('加入房间失败: $errorMsg');
      }
    } catch (e) {
      developer.log('HTTP加入房间失败: $e');
      rethrow;
    }
  }
}

/// HTTP房间基本信息
class HttpRoomInfo {
  final String id;
  final int redCount;
  final int blueCount;
  final bool isStarted;
  final int playerCount;
  final int maxPlayers;
  final String creatorId; // 房主ID

  HttpRoomInfo({
    required this.id,
    required this.redCount,
    required this.blueCount,
    required this.isStarted,
    required this.playerCount,
    required this.maxPlayers,
    required this.creatorId,
  });

  factory HttpRoomInfo.fromJson(Map<String, dynamic> json) {
    return HttpRoomInfo(
      id: json['id'] ?? '',
      redCount: json['red_count'] ?? 0,
      blueCount: json['blue_count'] ?? 0,
      isStarted: json['is_started'] ?? false,
      playerCount: json['player_count'] ?? 0,
      maxPlayers: json['max_players'] ?? 12,
      creatorId: json['creator_id'] ?? '',
    );
  }

  /// 房间是否满员
  bool get isFull => playerCount >= maxPlayers;

  /// 房间状态描述
  String get statusText {
    if (isStarted) return '游戏中';
    if (isFull) return '已满';
    return '等待中';
  }
}

/// 加入房间结果
class JoinRoomResult {
  final String playerId;
  final String roomId;
  final Map<String, dynamic> roomData;

  JoinRoomResult({
    required this.playerId,
    required this.roomId,
    required this.roomData,
  });
}

/// 创建房间结果
class CreateRoomResult {
  final String roomId;
  final String playerId;
  final Map<String, dynamic> roomData;

  CreateRoomResult({
    required this.roomId,
    required this.playerId,
    required this.roomData,
  });
}
