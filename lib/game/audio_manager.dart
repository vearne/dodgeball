import 'package:flame_audio/flame_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 音频管理器，负责处理背景音乐和音效
class AudioManager {
  static AudioManager? _instance;
  static AudioManager get instance => _instance ??= AudioManager._();

  AudioManager._();

  // 音频状态
  bool _isMusicEnabled = true;
  bool _isSoundEnabled = true;
  double _musicVolume = 0.5;
  double _soundVolume = 0.7;

  // 音频文件路径
  static const String _backgroundMusicPath = 'background_music.mp3';
  static const String _hitSoundPath = 'hit_sound.mp3';
  static const String _throwSoundPath = 'throw_sound.mp3';
  static const String _victorySoundPath = 'victory_sound.mp3';

  /// 初始化音频管理器
  Future<void> initialize() async {
    await _loadSettings();
    await _preloadAudio();
  }

  /// 加载用户设置
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _isMusicEnabled = prefs.getBool('music_enabled') ?? true;
    _isSoundEnabled = prefs.getBool('sound_enabled') ?? true;
    _musicVolume = prefs.getDouble('music_volume') ?? 0.5;
    _soundVolume = prefs.getDouble('sound_volume') ?? 0.7;
  }

  /// 保存用户设置
  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('music_enabled', _isMusicEnabled);
    await prefs.setBool('sound_enabled', _isSoundEnabled);
    await prefs.setDouble('music_volume', _musicVolume);
    await prefs.setDouble('sound_volume', _soundVolume);
  }

  /// 预加载音频文件
  Future<void> _preloadAudio() async {
    try {
      // 预加载音频文件
      await FlameAudio.audioCache.load(_backgroundMusicPath);
      await FlameAudio.audioCache.load(_hitSoundPath);
      await FlameAudio.audioCache.load(_throwSoundPath);
      await FlameAudio.audioCache.load(_victorySoundPath);
    } catch (e) {
      print('音频预加载失败: $e');
    }
  }

  /// 播放背景音乐
  Future<void> playBackgroundMusic() async {
    if (!_isMusicEnabled) return;

    try {
      await FlameAudio.bgm.play(
        _backgroundMusicPath,
        volume: _musicVolume,
      );
    } catch (e) {
      print('播放背景音乐失败: $e');
    }
  }

  /// 停止背景音乐
  Future<void> stopBackgroundMusic() async {
    try {
      await FlameAudio.bgm.stop();
    } catch (e) {
      print('停止背景音乐失败: $e');
    }
  }

  /// 播放击中音效
  Future<void> playHitSound() async {
    if (!_isSoundEnabled) return;

    try {
      await FlameAudio.play(
        _hitSoundPath,
        volume: _soundVolume,
      );
    } catch (e) {
      print('播放击中音效失败: $e');
    }
  }

  /// 播放投掷音效
  Future<void> playThrowSound() async {
    if (!_isSoundEnabled) return;

    try {
      await FlameAudio.play(
        _throwSoundPath,
        volume: _soundVolume,
      );
    } catch (e) {
      print('播放投掷音效失败: $e');
    }
  }

  /// 播放胜利音效
  Future<void> playVictorySound() async {
    if (!_isSoundEnabled) return;

    try {
      await FlameAudio.play(
        _victorySoundPath,
        volume: _soundVolume,
      );
    } catch (e) {
      print('播放胜利音效失败: $e');
    }
  }

  /// 设置音乐开关
  Future<void> setMusicEnabled(bool enabled) async {
    _isMusicEnabled = enabled;
    await _saveSettings();
    
    if (enabled) {
      await playBackgroundMusic();
    } else {
      await stopBackgroundMusic();
    }
  }

  /// 设置音效开关
  Future<void> setSoundEnabled(bool enabled) async {
    _isSoundEnabled = enabled;
    await _saveSettings();
  }

  /// 设置音乐音量
  Future<void> setMusicVolume(double volume) async {
    _musicVolume = volume.clamp(0.0, 1.0);
    await _saveSettings();
  }

  /// 设置音效音量
  Future<void> setSoundVolume(double volume) async {
    _soundVolume = volume.clamp(0.0, 1.0);
    await _saveSettings();
  }

  /// 获取音乐开关状态
  bool get isMusicEnabled => _isMusicEnabled;

  /// 获取音效开关状态
  bool get isSoundEnabled => _isSoundEnabled;

  /// 获取音乐音量
  double get musicVolume => _musicVolume;

  /// 获取音效音量
  double get soundVolume => _soundVolume;

  /// 释放资源
  Future<void> dispose() async {
    await stopBackgroundMusic();
  }
}
