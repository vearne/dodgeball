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

  // 初始化标志，防止重复初始化
  bool _isInitialized = false;

  // 防止音效在短时间内重复播放的标志
  bool _isPlayingHitSound = false;
  bool _isPlayingThrowSound = false;

  // 音频文件路径
  static const String _backgroundMusicPath = 'background_music.mp3';
  static const String _hitSoundPath = 'hit_sound.mp3';
  static const String _throwSoundPath = 'throw_sound.mp3';
  static const String _victorySoundPath = 'victory_sound.mp3';

  /// 初始化音频管理器
  Future<void> initialize() async {
    // 如果已经初始化过，直接返回
    if (_isInitialized) {
      return;
    }

    await _loadSettings();
    await _preloadAudio();
    _isInitialized = true;
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
    } catch (e) {}
  }

  /// 播放背景音乐
  void playBackgroundMusic() {
    if (!_isMusicEnabled) return;

    try {
      // 如果音乐已经在播放，不需要重复播放
      if (FlameAudio.bgm.isPlaying) {
        return;
      }

      // 不要 await，避免重复响应问题
      FlameAudio.bgm.play(_backgroundMusicPath, volume: _musicVolume);
    } catch (e) {}
  }

  /// 停止背景音乐
  void stopBackgroundMusic() {
    try {
      // 不要 await，避免重复响应问题
      FlameAudio.bgm.stop();
    } catch (e) {}
  }

  /// 播放击中音效
  void playHitSound() {
    if (!_isSoundEnabled || _isPlayingHitSound) return;

    try {
      _isPlayingHitSound = true;
      // 不要 await 音效播放，避免重复响应问题
      FlameAudio.play(_hitSoundPath, volume: _soundVolume);

      // 100ms 后重置标志，防止音效播放太频繁
      Future.delayed(const Duration(milliseconds: 100), () {
        _isPlayingHitSound = false;
      });
    } catch (e) {
      _isPlayingHitSound = false;
    }
  }

  /// 播放投掷音效
  void playThrowSound() {
    if (!_isSoundEnabled || _isPlayingThrowSound) return;

    try {
      _isPlayingThrowSound = true;
      // 不要 await 音效播放，避免重复响应问题
      FlameAudio.play(_throwSoundPath, volume: _soundVolume);

      // 100ms 后重置标志，防止音效播放太频繁
      Future.delayed(const Duration(milliseconds: 100), () {
        _isPlayingThrowSound = false;
      });
    } catch (e) {
      _isPlayingThrowSound = false;
    }
  }

  /// 播放胜利音效
  void playVictorySound() {
    if (!_isSoundEnabled) return;

    try {
      // 不要 await 音效播放，避免重复响应问题
      FlameAudio.play(_victorySoundPath, volume: _soundVolume);
    } catch (e) {}
  }

  /// 设置音乐开关
  Future<void> setMusicEnabled(bool enabled) async {
    _isMusicEnabled = enabled;
    await _saveSettings();

    if (enabled) {
      playBackgroundMusic();
    } else {
      stopBackgroundMusic();
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
  void dispose() {
    stopBackgroundMusic();
  }
}
