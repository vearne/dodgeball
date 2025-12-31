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
  String get missionDescription =>
      '• 消灭所有敌人完成关卡\n• 通过关卡后自动进入下一关\n• 设置好生命值和AI难度后开始挑战';

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

  @override
  String get gameHelp => '游戏帮助';

  @override
  String get gameObjective => '游戏目标';

  @override
  String get gameObjectiveDesc =>
      '消灭场上所有敌人完成关卡！击中敌人可以将其淘汰，但要小心不要被敌人的球击中。完成关卡后会自动进入下一关，你的生命值和道具效果会保留。';

  @override
  String get basicControls => '基本操作';

  @override
  String get basicControlsDesc =>
      '• 移动：使用方向键、WASD键、虚拟摇杆或手柄移动角色\n• 投球：自动瞄准最近的敌人，按空格键、J键或手柄按钮投掷\n• 冷却时间：投球后需要等待10秒才能再次投球\n• 双人游戏：玩家2使用方向键移动，使用L键投球';

  @override
  String get powerUps => '道具说明';

  @override
  String get healthPotion => '生命药水';

  @override
  String get healthPotionDesc => '恢复1点生命值。当你被击中时会失去生命值，使用生命药水可以让你继续战斗。';

  @override
  String get speedBoostItem => '速度提升';

  @override
  String get speedBoostItemDesc => '提升移动速度30秒。拾取后可以更快地躲避敌人的攻击，也能更好地追击敌人。';

  @override
  String get attackSpeedItem => '攻速提升';

  @override
  String get attackSpeedItemDesc => '减少投球冷却时间30秒。拾取后可以更快地连续投球，大大提高战斗效率。';

  @override
  String get gameTips => '游戏提示';

  @override
  String get gameTipsDesc =>
      '• 利用障碍物躲避敌人的攻击\n• 道具效果可以叠加，并会保留到下一关\n• 注意冷却时间，在无法投球时要保持移动\n• 优先击杀威胁最大的敌人\n• 双人合作可以更容易地完成困难关卡';

  @override
  String get obstaclesTitle => '障碍物';

  @override
  String get obstaclesDesc =>
      '场上的石头和墙壁可以阻挡球的飞行。合理利用障碍物可以躲避敌人的攻击，但同时也会阻挡你的投球路径。';

  @override
  String get gotIt => '知道了';
}
