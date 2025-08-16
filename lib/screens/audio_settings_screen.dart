import 'package:flutter/material.dart';
import '../game/audio_manager.dart';

/// 音频设置界面
class AudioSettingsScreen extends StatefulWidget {
  const AudioSettingsScreen({super.key});

  @override
  State<AudioSettingsScreen> createState() => _AudioSettingsScreenState();
}

class _AudioSettingsScreenState extends State<AudioSettingsScreen> {
  final AudioManager _audioManager = AudioManager.instance;
  
  bool _isMusicEnabled = true;
  bool _isSoundEnabled = true;
  double _musicVolume = 0.5;
  double _soundVolume = 0.7;

  @override
  void initState() {
    super.initState();
    _loadCurrentSettings();
  }

  /// 加载当前设置
  void _loadCurrentSettings() {
    setState(() {
      _isMusicEnabled = _audioManager.isMusicEnabled;
      _isSoundEnabled = _audioManager.isSoundEnabled;
      _musicVolume = _audioManager.musicVolume;
      _soundVolume = _audioManager.soundVolume;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('音频设置'),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue[100]!,
              Colors.blue[50]!,
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              
              // 音乐设置
              _buildSettingCard(
                title: '背景音乐',
                icon: Icons.music_note,
                child: Column(
                  children: [
                    // 音乐开关
                    SwitchListTile(
                      title: const Text('启用背景音乐'),
                      subtitle: const Text('游戏开始后播放背景音乐'),
                      value: _isMusicEnabled,
                      onChanged: (value) async {
                        setState(() {
                          _isMusicEnabled = value;
                        });
                        await _audioManager.setMusicEnabled(value);
                      },
                      activeColor: Colors.blue[800],
                    ),
                    
                    // 音乐音量滑块
                    if (_isMusicEnabled) ...[
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Icon(Icons.volume_down, color: Colors.grey),
                          Expanded(
                            child: Slider(
                              value: _musicVolume,
                              min: 0.0,
                              max: 1.0,
                              divisions: 10,
                              label: '${(_musicVolume * 100).round()}%',
                              onChanged: (value) async {
                                setState(() {
                                  _musicVolume = value;
                                });
                                await _audioManager.setMusicVolume(value);
                              },
                              activeColor: Colors.blue[800],
                            ),
                          ),
                          const Icon(Icons.volume_up, color: Colors.grey),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              
              const SizedBox(height: 20),
              
              // 音效设置
              _buildSettingCard(
                title: '音效',
                icon: Icons.volume_up,
                child: Column(
                  children: [
                    // 音效开关
                    SwitchListTile(
                      title: const Text('启用音效'),
                      subtitle: const Text('击中、投掷等音效'),
                      value: _isSoundEnabled,
                      onChanged: (value) async {
                        setState(() {
                          _isSoundEnabled = value;
                        });
                        await _audioManager.setSoundEnabled(value);
                      },
                      activeColor: Colors.blue[800],
                    ),
                    
                    // 音效音量滑块
                    if (_isSoundEnabled) ...[
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Icon(Icons.volume_down, color: Colors.grey),
                          Expanded(
                            child: Slider(
                              value: _soundVolume,
                              min: 0.0,
                              max: 1.0,
                              divisions: 10,
                              label: '${(_soundVolume * 100).round()}%',
                              onChanged: (value) async {
                                setState(() {
                                  _soundVolume = value;
                                });
                                await _audioManager.setSoundVolume(value);
                              },
                              activeColor: Colors.blue[800],
                            ),
                          ),
                          const Icon(Icons.volume_up, color: Colors.grey),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              
              const SizedBox(height: 30),
              
              // 测试按钮
              Center(
                child: Column(
                  children: [
                    ElevatedButton.icon(
                      onPressed: _isSoundEnabled ? () => _audioManager.playHitSound() : null,
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('测试击中音效'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange[600],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      onPressed: _isSoundEnabled ? () => _audioManager.playThrowSound() : null,
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('测试投掷音效'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[600],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                    ),
                  ],
                ),
              ),
              
              const Spacer(),
              
              // 说明文字
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '音频说明：',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text('• 背景音乐：游戏进行时播放的背景音乐'),
                    Text('• 击中音效：球击中玩家时播放'),
                    Text('• 投掷音效：投掷球时播放'),
                    Text('• 胜利音效：游戏胜利时播放'),
                    SizedBox(height: 8),
                    Text(
                      '注意：首次使用需要下载音频文件，请确保网络连接正常。',
                      style: TextStyle(
                        color: Colors.orange,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建设置卡片
  Widget _buildSettingCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.blue[800], size: 24),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[800],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}
