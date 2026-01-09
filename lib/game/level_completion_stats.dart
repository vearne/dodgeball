/// 关卡完成统计数据
class LevelCompletionStats {
  final double elapsedTimeInSeconds;
  final Map<int, int> playerKillCounts; // playerId -> kill count

  const LevelCompletionStats({
    required this.elapsedTimeInSeconds,
    required this.playerKillCounts,
  });

  /// 格式化时间为 MM:SS
  String get formattedTime {
    final minutes = (elapsedTimeInSeconds / 60).floor();
    final seconds = (elapsedTimeInSeconds % 60).floor();
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}
