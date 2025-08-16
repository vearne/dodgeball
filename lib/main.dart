import 'package:flutter/material.dart';
import 'game/audio_manager.dart';
import 'screens/game_mode_selector.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化音频管理器
  await AudioManager.instance.initialize();

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
      home: const GameModeSelectorScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
