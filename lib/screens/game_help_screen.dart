import 'package:flutter/material.dart';
import '../gen_l10n/app_localizations.dart';

/// 游戏帮助说明界面
class GameHelpScreen extends StatelessWidget {
  const GameHelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.9),
      appBar: AppBar(
        title: Text(l10n.gameHelp),
        backgroundColor: Colors.black.withOpacity(0.8),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 游戏目标
            _buildSection(
              context,
              icon: Icons.flag,
              title: l10n.gameObjective,
              content: l10n.gameObjectiveDesc,
              color: Colors.orange,
            ),
            const SizedBox(height: 24),

            // 基本操作
            _buildSection(
              context,
              icon: Icons.gamepad,
              title: l10n.basicControls,
              content: l10n.basicControlsDesc,
              color: Colors.blue,
            ),
            const SizedBox(height: 24),

            // 道具说明
            _buildSection(
              context,
              icon: Icons.stars,
              title: l10n.powerUps,
              content: '',
              color: Colors.purple,
            ),
            const SizedBox(height: 12),
            _buildPowerUpItem(
              context,
              emoji: '💚',
              name: l10n.healthPotion,
              description: l10n.healthPotionDesc,
            ),
            const SizedBox(height: 12),
            _buildPowerUpItem(
              context,
              emoji: '⚡',
              name: l10n.speedBoostItem,
              description: l10n.speedBoostItemDesc,
            ),
            const SizedBox(height: 12),
            _buildPowerUpItem(
              context,
              emoji: '🎯',
              name: l10n.attackSpeedItem,
              description: l10n.attackSpeedItemDesc,
            ),
            const SizedBox(height: 24),

            // 游戏提示
            _buildSection(
              context,
              icon: Icons.lightbulb,
              title: l10n.gameTips,
              content: l10n.gameTipsDesc,
              color: Colors.green,
            ),
            const SizedBox(height: 24),

            // 障碍物说明
            _buildSection(
              context,
              icon: Icons.block,
              title: l10n.obstaclesTitle,
              content: l10n.obstaclesDesc,
              color: Colors.brown,
            ),
            const SizedBox(height: 32),

            // 返回按钮
            Center(
              child: ElevatedButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.check),
                label: Text(l10n.gotIt),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  textStyle: const TextStyle(fontSize: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String content,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          if (content.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              content,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPowerUpItem(
    BuildContext context, {
    required String emoji,
    required String name,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            emoji,
            style: const TextStyle(fontSize: 32),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

