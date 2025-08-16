enum GameMode {
  singlePlayer,  // 单人模式：其他玩家由AI控制
  multiPlayer,   // 多人模式：玩家手动控制
}

enum PlayerControllerType {
  human,
  ai,
}

enum GameState {
  playing,     // 游戏进行中
  redWins,     // 红队获胜
  blueWins,    // 蓝队获胜
  paused,      // 游戏暂停
  timeUp,      // 限时赛时间到
}

// 新增：游戏玩法模式
enum GameplayMode {
  elimination,  // 淘汰赛：被击中即淘汰
  timeLimit,    // 限时赛：被击中得分，时间到统计分数
}

// 新增：限时赛时间选项
enum TimeLimitOption {
  oneMinute(60),    // 1分钟
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
