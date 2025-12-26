// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => '躲避球大战';

  @override
  String get missionMode => 'Mission模式';

  @override
  String get missionModeSelectLevel => 'Mission模式 - 选择关卡';

  @override
  String get playerCount => '玩家数量:';

  @override
  String get onePlayer => '1人';

  @override
  String get twoPlayers => '2人';

  @override
  String get mapEditor => '地图编辑器';

  @override
  String get noMaps => '暂无关卡';

  @override
  String get createMap => '创建关卡';

  @override
  String enemyCount(int count) {
    return '敌人数量: $count';
  }

  @override
  String obstacles(int count) {
    return '障碍物: $count';
  }

  @override
  String get edit => '编辑';

  @override
  String get delete => '删除';

  @override
  String get start => '开始';

  @override
  String get missionOnlyFromFirst => '关卡模式只允许从第1关开始';

  @override
  String get confirmDelete => '确认删除';

  @override
  String confirmDeleteMap(String name) {
    return '确定要删除地图 \"$name\" 吗？';
  }

  @override
  String get cancel => '取消';

  @override
  String get deleteAction => '删除';

  @override
  String get mapDeleted => '地图已删除';

  @override
  String deleteFailed(String error) {
    return '删除失败: $error';
  }

  @override
  String get builtinMapCannotDelete => '内置地图不能删除';

  @override
  String killCount(int current, int total) {
    return '击杀: $current / $total';
  }

  @override
  String cooldownTime(String seconds) {
    return '冷却时间: $seconds秒';
  }

  @override
  String get player1 => '玩家1';

  @override
  String get player2 => '玩家2';

  @override
  String get gamePaused => '游戏暂停';

  @override
  String map(String name) {
    return '地图: $name';
  }

  @override
  String target(int count) {
    return '目标: 消灭 $count 个敌人';
  }

  @override
  String get continueGame => '继续游戏';

  @override
  String get exitGame => '退出游戏';

  @override
  String get victory => '胜利！';

  @override
  String get defeat => '失败！';

  @override
  String get levelComplete => '🎉 关卡完成！';

  @override
  String levelCompleteMessage(String name) {
    return '恭喜完成 $name！';
  }

  @override
  String preparingNextLevel(String name) {
    return '准备进入 $name';
  }

  @override
  String get currentStatus => '当前状态：';

  @override
  String health(int health) {
    return '💚 生命值：$health';
  }

  @override
  String speedBoost(String time) {
    return '⚡ 速度提升：$time秒';
  }

  @override
  String attackSpeedBoost(String time) {
    return '🎯 攻速提升：$time秒';
  }

  @override
  String get statusCarryOver => '💡 你的生命值和道具效果将保留到下一关！';

  @override
  String get backToSelection => '返回选关';

  @override
  String get continueNow => '立即继续';

  @override
  String get allLevelsComplete => '🏆 全部通关！';

  @override
  String get allLevelsCompleteMessage => '恭喜你完成了所有关卡！';

  @override
  String lastLevel(String name) {
    return '最后关卡：$name';
  }

  @override
  String get back => '返回';

  @override
  String get missionDescription => '• 消灭所有敌人完成关卡\n• 通过关卡后自动进入下一关\n• 设置好生命值和AI难度后开始挑战';

  @override
  String maxHealth(int health) {
    return '最大生命值: $health';
  }

  @override
  String get aiDifficulty => 'AI难度';

  @override
  String get easy => '简单';

  @override
  String get normal => '普通';

  @override
  String get hard => '困难';

  @override
  String get expert => '专家';

  @override
  String get master => '大师';

  @override
  String get startGame => '开始游戏';
}
