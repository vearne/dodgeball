/// 玩家状态数据类
/// 用于在关卡之间传递和保留玩家的生命值和道具效果
class PlayerState {
  final int currentHealth; // 当前生命值
  final bool hasSpeedBoost; // 是否有速度提升
  final bool hasAttackSpeedBoost; // 是否有攻速提升
  final double speedBoostRemainingTime; // 速度提升剩余时间（秒）
  final double attackSpeedBoostRemainingTime; // 攻速提升剩余时间（秒）

  const PlayerState({
    required this.currentHealth,
    this.hasSpeedBoost = false,
    this.hasAttackSpeedBoost = false,
    this.speedBoostRemainingTime = 0,
    this.attackSpeedBoostRemainingTime = 0,
  });

  /// 创建初始状态
  factory PlayerState.initial(int maxHealth) {
    return PlayerState(currentHealth: maxHealth);
  }

  /// 复制并修改某些字段
  PlayerState copyWith({
    int? currentHealth,
    bool? hasSpeedBoost,
    bool? hasAttackSpeedBoost,
    double? speedBoostRemainingTime,
    double? attackSpeedBoostRemainingTime,
  }) {
    return PlayerState(
      currentHealth: currentHealth ?? this.currentHealth,
      hasSpeedBoost: hasSpeedBoost ?? this.hasSpeedBoost,
      hasAttackSpeedBoost: hasAttackSpeedBoost ?? this.hasAttackSpeedBoost,
      speedBoostRemainingTime:
          speedBoostRemainingTime ?? this.speedBoostRemainingTime,
      attackSpeedBoostRemainingTime:
          attackSpeedBoostRemainingTime ?? this.attackSpeedBoostRemainingTime,
    );
  }

  @override
  String toString() {
    return 'PlayerState(health: $currentHealth, '
        'speedBoost: $hasSpeedBoost(${speedBoostRemainingTime.toStringAsFixed(1)}s), '
        'attackSpeedBoost: $hasAttackSpeedBoost(${attackSpeedBoostRemainingTime.toStringAsFixed(1)}s))';
  }
}
