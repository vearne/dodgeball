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
}
