import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 键盘配置类，管理玩家的按键绑定
class KeyboardConfig {
  final int playerId;
  LogicalKeyboardKey up;
  LogicalKeyboardKey down;
  LogicalKeyboardKey left;
  LogicalKeyboardKey right;
  LogicalKeyboardKey throwKey;

  KeyboardConfig({
    required this.playerId,
    required this.up,
    required this.down,
    required this.left,
    required this.right,
    required this.throwKey,
  });

  /// 获取默认配置
  static KeyboardConfig getDefault(int playerId) {
    if (playerId == 0) {
      // 玩家1：WASD + 空格
      return KeyboardConfig(
        playerId: playerId,
        up: LogicalKeyboardKey.keyW,
        down: LogicalKeyboardKey.keyS,
        left: LogicalKeyboardKey.keyA,
        right: LogicalKeyboardKey.keyD,
        throwKey: LogicalKeyboardKey.space,
      );
    } else {
      // 玩家2：IJKL + 数字0
      return KeyboardConfig(
        playerId: playerId,
        up: LogicalKeyboardKey.keyI,
        down: LogicalKeyboardKey.keyK,
        left: LogicalKeyboardKey.keyJ,
        right: LogicalKeyboardKey.keyL,
        throwKey: LogicalKeyboardKey.digit0,
      );
    }
  }

  /// 从SharedPreferences加载配置
  static Future<KeyboardConfig> load(int playerId) async {
    final prefs = await SharedPreferences.getInstance();
    final defaultConfig = getDefault(playerId);
    
    final upKeyId = prefs.getInt('keyboard_config_${playerId}_up');
    final downKeyId = prefs.getInt('keyboard_config_${playerId}_down');
    final leftKeyId = prefs.getInt('keyboard_config_${playerId}_left');
    final rightKeyId = prefs.getInt('keyboard_config_${playerId}_right');
    final throwKeyId = prefs.getInt('keyboard_config_${playerId}_throw');

    // 从keyId恢复LogicalKeyboardKey
    // 注意：Flutter没有直接的findKeyByKeyId方法，我们需要通过遍历所有键来查找
    // 为了简化，我们只检查keyId是否匹配默认配置的keyId
    return KeyboardConfig(
      playerId: playerId,
      up: upKeyId != null && upKeyId == defaultConfig.up.keyId
          ? defaultConfig.up
          : (upKeyId != null ? _findKeyById(upKeyId) ?? defaultConfig.up : defaultConfig.up),
      down: downKeyId != null && downKeyId == defaultConfig.down.keyId
          ? defaultConfig.down
          : (downKeyId != null ? _findKeyById(downKeyId) ?? defaultConfig.down : defaultConfig.down),
      left: leftKeyId != null && leftKeyId == defaultConfig.left.keyId
          ? defaultConfig.left
          : (leftKeyId != null ? _findKeyById(leftKeyId) ?? defaultConfig.left : defaultConfig.left),
      right: rightKeyId != null && rightKeyId == defaultConfig.right.keyId
          ? defaultConfig.right
          : (rightKeyId != null ? _findKeyById(rightKeyId) ?? defaultConfig.right : defaultConfig.right),
      throwKey: throwKeyId != null && throwKeyId == defaultConfig.throwKey.keyId
          ? defaultConfig.throwKey
          : (throwKeyId != null ? _findKeyById(throwKeyId) ?? defaultConfig.throwKey : defaultConfig.throwKey),
    );
  }

  /// 通过keyId查找LogicalKeyboardKey（辅助方法）
  /// 注意：这是一个简化的实现，实际使用中可能需要更完整的键映射
  static LogicalKeyboardKey? _findKeyById(int keyId) {
    // 尝试常见的键
    final commonKeys = [
      LogicalKeyboardKey.keyW,
      LogicalKeyboardKey.keyS,
      LogicalKeyboardKey.keyA,
      LogicalKeyboardKey.keyD,
      LogicalKeyboardKey.keyI,
      LogicalKeyboardKey.keyK,
      LogicalKeyboardKey.keyJ,
      LogicalKeyboardKey.keyL,
      LogicalKeyboardKey.space,
      LogicalKeyboardKey.digit0,
      LogicalKeyboardKey.arrowUp,
      LogicalKeyboardKey.arrowDown,
      LogicalKeyboardKey.arrowLeft,
      LogicalKeyboardKey.arrowRight,
    ];
    
    for (final key in commonKeys) {
      if (key.keyId == keyId) {
        return key;
      }
    }
    
    return null;
  }

  /// 保存配置到SharedPreferences
  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('keyboard_config_${playerId}_up', up.keyId);
    await prefs.setInt('keyboard_config_${playerId}_down', down.keyId);
    await prefs.setInt('keyboard_config_${playerId}_left', left.keyId);
    await prefs.setInt('keyboard_config_${playerId}_right', right.keyId);
    await prefs.setInt('keyboard_config_${playerId}_throw', throwKey.keyId);
  }

  /// 重置为默认配置
  Future<void> reset() async {
    final defaultConfig = getDefault(playerId);
    up = defaultConfig.up;
    down = defaultConfig.down;
    left = defaultConfig.left;
    right = defaultConfig.right;
    throwKey = defaultConfig.throwKey;
    await save();
  }

  /// 获取按键名称（用于显示）
  String getKeyName(LogicalKeyboardKey key) {
    // 尝试获取键的调试名称
    final debugName = key.debugName;
    if (debugName != null) {
      // 简化一些常见的键名
      if (debugName.startsWith('Key ')) {
        return debugName.substring(4);
      }
      if (debugName.startsWith('Digit ')) {
        return debugName.substring(6);
      }
      if (debugName == 'Space') {
        return '空格';
      }
      if (debugName == 'Arrow Up') {
        return '↑';
      }
      if (debugName == 'Arrow Down') {
        return '↓';
      }
      if (debugName == 'Arrow Left') {
        return '←';
      }
      if (debugName == 'Arrow Right') {
        return '→';
      }
      return debugName;
    }
    return '未知';
  }
}

