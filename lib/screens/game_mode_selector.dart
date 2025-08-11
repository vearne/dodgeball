import 'package:flutter/material.dart';
import '../game/game_mode.dart';
import 'game_screen.dart';

class GameModeSelectorScreen extends StatelessWidget {
  const GameModeSelectorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('选择游戏模式'),
        centerTitle: true,
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade50, Colors.blue.shade100],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 游戏标题
                Container(
                  margin: const EdgeInsets.only(bottom: 50),
                  child: Column(
                    children: [
                      Icon(
                        Icons.sports_volleyball,
                        size: 80,
                        color: Colors.blue.shade700,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        '躲避球大战',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade800,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '选择您的游戏模式',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),

                // 游戏模式选择卡片
                Column(
                  children: [
                    // 单人模式卡片
                    _GameModeCard(
                      title: '单人模式',
                      subtitle: '与AI对战',
                      description: '除了您之外\n所有玩家都由电脑控制',
                      icon: Icons.person,
                      color: Colors.green,
                      onTap: () => _startGame(context, GameMode.singlePlayer),
                    ),

                    const SizedBox(height: 20),

                    // 多人模式卡片
                    _GameModeCard(
                      title: '多人模式',
                      subtitle: '玩家手动控制',
                      description: '所有玩家都可以手动控制\n与朋友一起游戏',
                      icon: Icons.group,
                      color: Colors.orange,
                      onTap: () => _startGame(context, GameMode.multiPlayer),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _startGame(BuildContext context, GameMode mode) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => GameScreen(gameMode: mode)));
  }
}

class _GameModeCard extends StatelessWidget {
  const _GameModeCard({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final String description;
  final IconData icon;
  final MaterialColor color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [color.shade100, color.shade200],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 图标
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: color.shade500,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 40, color: Colors.white),
              ),

              const SizedBox(height: 20),

              // 标题
              Text(
                title,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color.shade800,
                ),
              ),

              const SizedBox(height: 8),

              // 副标题
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: color.shade600,
                ),
              ),

              const SizedBox(height: 16),

              // 描述
              Text(
                description,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: color.shade700,
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 20),

              // 开始按钮
              ElevatedButton(
                onPressed: onTap,
                style: ElevatedButton.styleFrom(
                  backgroundColor: color.shade500,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: const Text(
                  '开始游戏',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
