import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'gen_l10n/app_localizations.dart';
import 'game/audio_manager.dart';
import 'screens/game_mode_selection_screen.dart';

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
      title: 'Dodgeball Battle',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', ''), // English
        Locale('zh', ''), // Chinese
      ],
      home: const GameModeSelectionScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
