import 'dart:convert';
import 'package:flutter/services.dart';

/// 服务器配置管理器
class ServerConfigManager {
  static ServerConfigManager? _instance;
  static ServerConfigManager get instance =>
      _instance ??= ServerConfigManager._();

  ServerConfigManager._();

  ServerConfig? _config;
  bool _isInitialized = false;

  /// 初始化配置
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      final jsonString = await rootBundle.loadString(
        'assets/config/server_config.json',
      );
      final jsonMap = json.decode(jsonString) as Map<String, dynamic>;
      _config = ServerConfig.fromJson(jsonMap);
      _isInitialized = true;
    } catch (e) {
      // 如果读取失败，使用默认配置
      _config = ServerConfig(
        serverUrl: 'ws://localhost:8080/ws',
        fallbackServers: ['ws://localhost:8080/ws'],
      );
      _isInitialized = true;
    }
  }

  /// 获取主服务器URL
  String get serverUrl {
    if (!_isInitialized) {
      throw StateError('ServerConfigManager 尚未初始化，请先调用 initialize()');
    }
    return _config!.serverUrl;
  }

  /// 获取备用服务器列表
  List<String> get fallbackServers {
    if (!_isInitialized) {
      throw StateError('ServerConfigManager 尚未初始化，请先调用 initialize()');
    }
    return _config!.fallbackServers;
  }

  /// 获取所有可用的服务器URL（主服务器 + 备用服务器）
  List<String> get allServerUrls {
    if (!_isInitialized) {
      throw StateError('ServerConfigManager 尚未初始化，请先调用 initialize()');
    }
    return [_config!.serverUrl, ..._config!.fallbackServers];
  }

  /// 检查是否已初始化
  bool get isInitialized => _isInitialized;

  /// 重置状态（用于测试）
  void reset() {
    _config = null;
    _isInitialized = false;
  }
}

/// 服务器配置数据类
class ServerConfig {
  final String serverUrl;
  final List<String> fallbackServers;

  const ServerConfig({required this.serverUrl, required this.fallbackServers});

  factory ServerConfig.fromJson(Map<String, dynamic> json) {
    return ServerConfig(
      serverUrl: json['serverUrl'] as String,
      fallbackServers: List<String>.from(json['fallbackServers'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {'serverUrl': serverUrl, 'fallbackServers': fallbackServers};
  }
}
