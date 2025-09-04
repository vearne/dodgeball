import 'package:flutter/material.dart';
import 'game/audio_manager.dart';
import 'screens/game_mode_selection_screen.dart';
import 'network/player_identity.dart';
import 'network/server_config_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化音频管理器
  await AudioManager.instance.initialize();

  // 初始化服务器配置管理器
  await ServerConfigManager.instance.initialize();

  // 生成并加载唯一的 player_id
  await PlayerIdentity.instance.ensureInitialized();

  runApp(const Dodgeball());
}

class Dodgeball extends StatelessWidget {
  const Dodgeball({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '躲避球大战',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const GameModeSelectionScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
