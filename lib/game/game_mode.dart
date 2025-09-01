enum GameModeType {
  singlePlayer, // 单人模式：其他玩家由AI控制
  multiPlayer, // 多人模式：玩家手动控制
}

enum PlayerControllerType { human, ai }

enum GameState {
  playing, // 游戏进行中
  redWins, // 红队获胜
  blueWins, // 蓝队获胜
  paused, // 游戏暂停
  timeUp, // 限时赛时间到
}

// 新增：游戏玩法模式
enum GameplayMode {
  elimination('淘汰赛', '击中对手来淘汰他们'), // 淘汰赛：被击中即淘汰
  timeLimit('限时赛', '在时间内获得更多分数') // 限时赛：被击中得分，时间到统计分数
  ;

  const GameplayMode(this.displayName, this.description);
  final String displayName;
  final String description;
}

// 新增：限时赛时间选项
enum TimeLimitOption {
  oneMinute(60), // 1分钟
  threeMinutes(180); // 3分钟

  const TimeLimitOption(this.seconds);
  final int seconds;

  String get displayName {
    switch (this) {
      case TimeLimitOption.oneMinute:
        return '1分钟';
      case TimeLimitOption.threeMinutes:
        return '3分钟';
    }
  }
}

/// 游戏模式配置类
class GameMode {
  final GameplayMode gameplayMode;
  final int? maxHealth; // 淘汰赛模式的最大生命值
  final TimeLimitOption? timeLimit; // 限时赛模式的时间限制

  const GameMode({required this.gameplayMode, this.maxHealth, this.timeLimit});

  String get displayName {
    switch (gameplayMode) {
      case GameplayMode.elimination:
        return '淘汰赛 ($maxHealth条命)';
      case GameplayMode.timeLimit:
        return '限时赛 (${timeLimit?.displayName})';
    }
  }

  String get description {
    switch (gameplayMode) {
      case GameplayMode.elimination:
        return '击中对手来淘汰他们，生命值为0时被淘汰';
      case GameplayMode.timeLimit:
        return '在限定时间内获得更多分数';
    }
  }
}
