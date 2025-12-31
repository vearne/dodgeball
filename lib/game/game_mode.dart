// 玩家控制类型
enum PlayerControllerType { human, ai }

// 游戏状态
enum GameState {
  playing, // 游戏进行中
  redWins, // 红队获胜
  blueWins, // 蓝队获胜
  paused, // 游戏暂停
}
