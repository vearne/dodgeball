// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Dodgeball Battle';

  @override
  String get missionMode => 'Mission Mode';

  @override
  String get missionModeSelectLevel => 'Mission Mode - Select Level';

  @override
  String get playerCount => 'Player Count:';

  @override
  String get onePlayer => '1 Player';

  @override
  String get twoPlayers => '2 Players';

  @override
  String get mapEditor => 'Map Editor';

  @override
  String get noMaps => 'No Maps Available';

  @override
  String get createMap => 'Create Map';

  @override
  String enemyCount(int count) {
    return 'Enemies: $count';
  }

  @override
  String obstacles(int count) {
    return 'Obstacles: $count';
  }

  @override
  String get edit => 'Edit';

  @override
  String get delete => 'Delete';

  @override
  String get start => 'Start';

  @override
  String get missionOnlyFromFirst => 'Mission mode can only start from level 1';

  @override
  String get confirmDelete => 'Confirm Delete';

  @override
  String confirmDeleteMap(String name) {
    return 'Are you sure you want to delete map \"$name\"?';
  }

  @override
  String get cancel => 'Cancel';

  @override
  String get deleteAction => 'Delete';

  @override
  String get mapDeleted => 'Map deleted';

  @override
  String deleteFailed(String error) {
    return 'Delete failed: $error';
  }

  @override
  String get builtinMapCannotDelete => 'Built-in maps cannot be deleted';

  @override
  String killCount(int current, int total) {
    return 'Kills: $current / $total';
  }

  @override
  String cooldownTime(String seconds) {
    return 'Cooldown: ${seconds}s';
  }

  @override
  String get player1 => 'Player 1';

  @override
  String get player2 => 'Player 2';

  @override
  String get gamePaused => 'Game Paused';

  @override
  String map(String name) {
    return 'Map: $name';
  }

  @override
  String target(int count) {
    return 'Target: Eliminate $count enemies';
  }

  @override
  String get continueGame => 'Continue';

  @override
  String get exitGame => 'Exit Game';

  @override
  String get victory => 'Victory!';

  @override
  String get defeat => 'Defeat!';

  @override
  String get levelComplete => '🎉 Level Complete!';

  @override
  String levelCompleteMessage(String name) {
    return 'Congratulations on completing $name!';
  }

  @override
  String preparingNextLevel(String name) {
    return 'Preparing for $name';
  }

  @override
  String get currentStatus => 'Current Status:';

  @override
  String health(int health) {
    return '💚 Health: $health';
  }

  @override
  String speedBoost(String time) {
    return '⚡ Speed Boost: ${time}s';
  }

  @override
  String attackSpeedBoost(String time) {
    return '🎯 Attack Speed Boost: ${time}s';
  }

  @override
  String get statusCarryOver =>
      '💡 Your health and power-up effects will carry over to the next level!';

  @override
  String get backToSelection => 'Back to Selection';

  @override
  String get continueNow => 'Continue Now';

  @override
  String get allLevelsComplete => '🏆 All Levels Complete!';

  @override
  String get allLevelsCompleteMessage =>
      'Congratulations! You\'ve completed all levels!';

  @override
  String lastLevel(String name) {
    return 'Last Level: $name';
  }

  @override
  String get back => 'Back';

  @override
  String get missionDescription =>
      '• Eliminate all enemies to complete the level\n• Automatically proceed to the next level after completion\n• Set health and AI difficulty before starting the challenge';

  @override
  String maxHealth(int health) {
    return 'Max Health: $health';
  }

  @override
  String get aiDifficulty => 'AI Difficulty';

  @override
  String get easy => 'Easy';

  @override
  String get normal => 'Normal';

  @override
  String get hard => 'Hard';

  @override
  String get expert => 'Expert';

  @override
  String get master => 'Master';

  @override
  String get startGame => 'Start Game';

  @override
  String get gameHelp => 'Game Help';

  @override
  String get gameObjective => 'Game Objective';

  @override
  String get gameObjectiveDesc =>
      'Eliminate all enemies on the field to complete the level! Hit enemies with the ball to knock them out, but be careful not to get hit. After completing a level, you\'ll automatically proceed to the next one, and your health and power-up effects will carry over.';

  @override
  String get basicControls => 'Basic Controls';

  @override
  String get basicControlsDesc =>
      '• Movement: Use arrow keys, WASD, virtual joystick, or gamepad to move\n• Throw: Auto-aims at nearest enemy, press Space, J key, or gamepad button to throw\n• Cooldown: Wait 10 seconds after throwing before you can throw again\n• Two Players: Player 2 uses arrow keys to move and L key to throw';

  @override
  String get powerUps => 'Power-Ups';

  @override
  String get healthPotion => 'Health Potion';

  @override
  String get healthPotionDesc =>
      'Restores 1 health point. When you get hit, you lose health. Use health potions to stay in the fight.';

  @override
  String get speedBoostItem => 'Speed Boost';

  @override
  String get speedBoostItemDesc =>
      'Increases movement speed for 30 seconds. Pick up to dodge enemy attacks more easily and chase down enemies faster.';

  @override
  String get attackSpeedItem => 'Attack Speed Boost';

  @override
  String get attackSpeedItemDesc =>
      'Reduces throw cooldown for 30 seconds. Pick up to throw balls more frequently and increase your combat efficiency.';

  @override
  String get gameTips => 'Game Tips';

  @override
  String get gameTipsDesc =>
      '• Use obstacles to dodge enemy attacks\n• Power-up effects stack and carry over to next level\n• Keep moving when you can\'t throw\n• Prioritize the most threatening enemies\n• Two-player cooperation makes difficult levels easier';

  @override
  String get obstaclesTitle => 'Obstacles';

  @override
  String get obstaclesDesc =>
      'Stones and walls on the field block ball trajectories. Use obstacles wisely to dodge enemy attacks, but remember they also block your own throws.';

  @override
  String get gotIt => 'Got It';
}
