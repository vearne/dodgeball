import 'dart:developer' as developer;

import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

/// 负责生成并持久化客户端唯一的 player_id
class PlayerIdentity {
  PlayerIdentity._();

  static final PlayerIdentity instance = PlayerIdentity._();

  static const String _prefsKey = 'player_id';
  String? _playerId;

  /// 确保已生成并加载本地唯一 player_id
  Future<void> ensureInitialized() async {
    if (_playerId != null) return;
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(_prefsKey);
    if (existing != null && existing.isNotEmpty) {
      _playerId = existing;
      developer.log('加载已存在的 player_id: $_playerId');
      return;
    }

    // 生成新的 UUID v4
    final newId = const Uuid().v4();
    await prefs.setString(_prefsKey, newId);
    _playerId = newId;
    developer.log('生成新的 player_id: $_playerId');
  }

  /// 获取已初始化的 player_id
  String get id {
    final id = _playerId;
    if (id == null || id.isEmpty) {
      throw StateError('PlayerIdentity 未初始化，请先调用 ensureInitialized()');
    }
    return id;
  }
}
