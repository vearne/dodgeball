import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import '../gen_l10n/app_localizations.dart';
import '../game/mission_dodgeball_game.dart';
import '../game/mission_map.dart';
import '../game/player_state.dart';
import '../game/audio_manager.dart';
import '../game/level_completion_stats.dart';
import '../game/game_mode.dart';

/// Mission模式游戏界面
class MissionGameScreen extends StatefulWidget {
  final MissionMap missionMap;
  final double aiIntelligenceLevel;
  final int maxHealth;
  final List<MissionMap> allMaps;
  final int currentMapIndex;
  final PlayerState? playerState; // 玩家状态（用于关卡间传递）
  final int playerCount; // 玩家数量（1或2）

  const MissionGameScreen({
    super.key,
    required this.missionMap,
    this.aiIntelligenceLevel = 1.0,
    this.maxHealth = 3,
    this.allMaps = const [],
    this.currentMapIndex = 0,
    this.playerState,
    this.playerCount = 1,
  });

  @override
  State<MissionGameScreen> createState() => _MissionGameScreenState();
}

class _MissionGameScreenState extends State<MissionGameScreen> {
  late MissionDodgeballGame game;

  @override
  void initState() {
    super.initState();
    game = MissionDodgeballGame(
      missionMap: widget.missionMap,
      aiIntelligenceLevel: widget.aiIntelligenceLevel,
      maxHealth: widget.maxHealth,
      playerState: widget.playerState,
      onMissionComplete: _onMissionComplete,
      onMissionFailed: _onMissionFailed,
      playerCount: widget.playerCount,
    );
  }

  /// 关卡完成回调
  void _onMissionComplete() {
    // 获取当前玩家状态
    final currentPlayerState = game.getCurrentPlayerState();

    // 创建关卡完成统计数据
    final levelStats = LevelCompletionStats(
      elapsedTimeInSeconds: game.elapsedTimeInSeconds,
      playerKillCounts: game.playerKillCounts,
    );

    // 检查是否还有下一关
    final nextIndex = widget.currentMapIndex + 1;
    if (nextIndex < widget.allMaps.length) {
      // 有下一关，自动进入
      _showNextLevelDialog(nextIndex, currentPlayerState, levelStats);
    } else {
      // 没有下一关，显示全部通关
      _showAllLevelsCompleteDialog(levelStats);
    }
  }

  /// 任务失败回调 - 返回首页
  void _onMissionFailed() {
    if (!mounted) return;

    // 返回到关卡选择页面
    Navigator.of(context).pop();
  }

  /// 显示进入下一关对话框（带自动跳转）
  void _showNextLevelDialog(
    int nextIndex,
    PlayerState? playerState,
    LevelCompletionStats levelStats,
  ) {
    final nextMap = widget.allMaps[nextIndex];
    final l10n = AppLocalizations.of(context)!;

    // 构建玩家状态信息
    String playerStatusInfo = '';
    if (playerState != null) {
      playerStatusInfo =
          '\n\n${l10n.currentStatus}\n'
          '${l10n.health(playerState.currentHealth)}\n';

      if (playerState.hasSpeedBoost) {
        playerStatusInfo +=
            '${l10n.speedBoost(playerState.speedBoostRemainingTime.toStringAsFixed(1))}\n';
      }
      if (playerState.hasAttackSpeedBoost) {
        playerStatusInfo +=
            '${l10n.attackSpeedBoost(playerState.attackSpeedBoostRemainingTime.toStringAsFixed(1))}\n';
      }
    }

    // 显示对话框
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _NextLevelDialog(
        currentMapName: widget.missionMap.name,
        nextMap: nextMap,
        playerStatusInfo: playerStatusInfo,
        levelStats: levelStats,
        onContinue: () {
          Navigator.of(context).pop(); // 关闭对话框
          _enterNextLevel(nextIndex, playerState, nextMap);
        },
        onBackToSelection: () {
          Navigator.of(context).pop(); // 关闭对话框
          Navigator.of(context).pop(); // 返回关卡选择
        },
      ),
    );

    // 3秒后自动进入下一关
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop(); // 关闭对话框
        _enterNextLevel(nextIndex, playerState, nextMap);
      }
    });
  }

  /// 进入下一关
  void _enterNextLevel(
    int nextIndex,
    PlayerState? playerState,
    MissionMap nextMap,
  ) {
    if (!mounted) return;

    // 替换当前页面为下一关，传递玩家状态
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => MissionGameScreen(
          missionMap: nextMap,
          aiIntelligenceLevel: widget.aiIntelligenceLevel,
          maxHealth: widget.maxHealth,
          allMaps: widget.allMaps,
          currentMapIndex: nextIndex,
          playerState: playerState, // 传递玩家状态
          playerCount: widget.playerCount, // 传递玩家数量
        ),
      ),
    );
    // 注意：背景音乐会在新关卡的onLoad中自动重新播放
  }

  /// 显示全部关卡完成对话框
  void _showAllLevelsCompleteDialog(LevelCompletionStats levelStats) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.allLevelsComplete),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(AppLocalizations.of(context)!.allLevelsCompleteMessage),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)!.lastLevel(widget.missionMap.name),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(); // 关闭对话框
              Navigator.of(context).pop(); // 返回关卡选择
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: Text(AppLocalizations.of(context)!.back),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (!didPop) {
          _showPauseMenu();
        }
      },
      child: Scaffold(
        body: Stack(
          children: [
            // 游戏主体 - 使用FittedBox确保1280x720分辨率固定，不受窗口缩放影响
            Center(
              child: FittedBox(
                fit: BoxFit.contain,
                child: SizedBox(
                  width: 1280,
                  height: 720,
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.black, width: 2),
                    ),
                    child: GameWidget.controlled(gameFactory: () => game),
                  ),
                ),
              ),
            ),

            // 顶部信息栏
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(child: _buildTopBar()),
            ),

            // 冷却时间进度条（支持多个玩家）
            Positioned(
              top: 70,
              left: 100,
              right: 100,
              child: SafeArea(
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 100),
                  // 使用 FutureBuilder 等待游戏加载完成
                  child: StreamBuilder(
                    stream: Stream.periodic(const Duration(milliseconds: 100)),
                    builder: (context, snapshot) => _buildCooldownBars(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.black.withOpacity(0.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 地图名称
          Text(
            widget.missionMap.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          // 中间信息：生命值和击杀数
          Row(
            children: [
              // 生命值显示
              ValueListenableBuilder<int>(
                valueListenable: game.playerHealthNotifier,
                builder: (context, health, child) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getHealthColor(health),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.favorite,
                          color: Colors.white,
                          size: 18,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$health',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),

              const SizedBox(width: 16),

              // 击杀数
              ValueListenableBuilder<int>(
                valueListenable: game.killCountNotifier,
                builder: (context, killCount, child) {
                  return Text(
                    AppLocalizations.of(
                      context,
                    )!.killCount(killCount, widget.missionMap.enemyCount),
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  );
                },
              ),

              const SizedBox(width: 16),

              // 游戏时间
              ValueListenableBuilder<double>(
                valueListenable: game.gameTimeNotifier,
                builder: (context, elapsedTime, child) {
                  final minutes = (elapsedTime / 60).floor();
                  final seconds = (elapsedTime % 60).floor();
                  final formattedTime =
                      '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
                  return Text(
                    formattedTime,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold,
                    ),
                  );
                },
              ),

              const SizedBox(width: 16),

              // 金币数量
              ValueListenableBuilder<int>(
                valueListenable: game.coinsNotifier,
                builder: (context, coins, child) {
                  return Row(
                    children: [
                      const Icon(
                        Icons.monetization_on,
                        color: Colors.yellow,
                        size: 20,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$coins',
                        style: const TextStyle(
                          color: Colors.yellow,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: () {
                          _showCoinExchangeDialog();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.yellow.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.yellow, width: 1),
                          ),
                          child: const Text(
                            '兑换',
                            style: TextStyle(
                              color: Colors.yellow,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),

          // 暂停按钮
          IconButton(
            icon: const Icon(Icons.pause, color: Colors.white),
            onPressed: _showPauseMenu,
          ),
        ],
      ),
    );
  }

  /// 根据生命值返回颜色
  Color _getHealthColor(int health) {
    if (health >= 4) {
      return Colors.green; // 高生命值 - 绿色
    } else if (health >= 2) {
      return Colors.orange; // 中等生命值 - 橙色
    } else {
      return Colors.red; // 低生命值 - 红色
    }
  }

  Widget _buildCooldownBars() {
    // 获取所有玩家的冷却时间通知器
    final cooldownNotifiers = game.playerCooldownNotifiers;
    final cooldownMaxNotifiers = game.playerCooldownMax;

    if (cooldownNotifiers.isEmpty) {
      // 如果没有通知器，返回一个占位符而不是空widget
      return Container(
        padding: const EdgeInsets.all(8),
        child: const Text(
          '等待玩家加载...',
          style: TextStyle(
            color: Colors.white,
            fontSize: 12,
            shadows: [
              Shadow(
                blurRadius: 2.0,
                color: Colors.black,
                offset: Offset(1, 1),
              ),
            ],
          ),
        ),
      );
    }

    final l10n = AppLocalizations.of(context)!;
    // 如果是单人游戏，显示单个进度条
    if (cooldownNotifiers.length == 1) {
      final notifier = cooldownNotifiers.values.first;
      final maxNotifier = cooldownMaxNotifiers.values.first;
      return _buildSingleCooldownBar(notifier, maxNotifier, l10n.player1, null);
    }

    // 如果是双人游戏，显示两个进度条
    return Column(
      children: [
        // 玩家1的冷却时间
        if (cooldownNotifiers.containsKey(0))
          _buildSingleCooldownBar(
            cooldownNotifiers[0]!,
            cooldownMaxNotifiers[0]!,
            l10n.player1,
            Colors.red.shade300,
          ),
        const SizedBox(height: 8),
        // 玩家2的冷却时间
        if (cooldownNotifiers.containsKey(1))
          _buildSingleCooldownBar(
            cooldownNotifiers[1]!,
            cooldownMaxNotifiers[1]!,
            l10n.player2,
            Colors.blue.shade300,
          ),
      ],
    );
  }

  Widget _buildSingleCooldownBar(
    ValueNotifier<double> notifier,
    ValueNotifier<double> maxNotifier,
    String playerLabel,
    Color? progressColor,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final displayLabel = playerLabel == '玩家1' ? l10n.player1 : l10n.player2;
    return ValueListenableBuilder<double>(
      valueListenable: notifier,
      builder: (context, cooldown, child) {
        final maxCooldown = maxNotifier.value;
        final progress = maxCooldown > 0 ? cooldown / maxCooldown : 0.0;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '$displayLabel:',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        blurRadius: 2.0,
                        color: Colors.black,
                        offset: Offset(1, 1),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 200, // 固定宽度200像素
                  child: LinearProgressIndicator(
                    value: 1.0 - progress,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      progressColor ?? Colors.blue,
                    ),
                    minHeight: 8,
                  ),
                ),
                const SizedBox(width: 8),
                if (cooldown > 0)
                  Text(
                    '${cooldown.toStringAsFixed(1)}s',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      shadows: [
                        Shadow(
                          blurRadius: 2.0,
                          color: Colors.black,
                          offset: Offset(1, 1),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        );
      },
    );
  }

  void _showPauseMenu() {
    // 暂停游戏引擎
    game.pauseEngine();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final l10n = AppLocalizations.of(context)!;
        return AlertDialog(
          title: Text(l10n.gamePaused),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.map(widget.missionMap.name)),
              const SizedBox(height: 8),
              Text(l10n.target(widget.missionMap.enemyCount)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                // 恢复游戏引擎
                game.resumeEngine();
                Navigator.of(context).pop();
              },
              child: Text(l10n.continueGame),
            ),
            TextButton(
              onPressed: () {
                // 退出游戏时停止背景音乐
                AudioManager.instance.stopBackgroundMusic();
                Navigator.of(context).pop(); // 关闭对话框
                Navigator.of(context).pop(); // 返回上一页
              },
              child: Text(l10n.exitGame),
            ),
          ],
        );
      },
    );
  }

  void _showCoinExchangeDialog() {
    // 暂停游戏引擎
    game.pauseEngine();

    final coins = game.coinsNotifier.value;
    final canExchange = coins >= 100;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        final l10n = AppLocalizations.of(context)!;
        return AlertDialog(
          title: const Text('金币兑换'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('当前金币：$coins'),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: canExchange
                      ? Colors.green.withOpacity(0.1)
                      : Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: canExchange ? Colors.green : Colors.grey,
                    width: 2,
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '100',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: canExchange ? Colors.yellow : Colors.grey,
                          ),
                        ),
                        const Icon(
                          Icons.monetization_on,
                          color: Colors.yellow,
                          size: 30,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text('兑换1条生命值', style: TextStyle(fontSize: 14)),
                  ],
                ),
              ),
              if (!canExchange) ...[
                const SizedBox(height: 12),
                const Text(
                  '金币不足，需要100个金币才能兑换',
                  style: TextStyle(color: Colors.red, fontSize: 12),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                game.resumeEngine();
                Navigator.of(context).pop();
              },
              child: const Text('关闭'),
            ),
            if (canExchange)
              ElevatedButton(
                onPressed: () {
                  // 执行兑换：减少100金币，增加1生命
                  game.coinsNotifier.value -= 100;

                  // 为所有玩家增加生命值
                  for (final player in game.playerTeam) {
                    if (player.controllerType == PlayerControllerType.human &&
                        !player.isEliminated) {
                      player.setCurrentHealth(player.currentHealth + 1);
                    }
                  }

                  game.resumeEngine();
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: const Text('兑换'),
              ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    // 只清理游戏资源，不停止背景音乐
    // 这样在关卡切换时音乐可以连续播放
    game.onRemove();
    super.dispose();
  }
}

/// 下一关对话框（带倒计时）
class _NextLevelDialog extends StatefulWidget {
  final String currentMapName;
  final MissionMap nextMap;
  final String playerStatusInfo;
  final LevelCompletionStats levelStats;
  final VoidCallback onContinue;
  final VoidCallback onBackToSelection;

  const _NextLevelDialog({
    required this.currentMapName,
    required this.nextMap,
    required this.playerStatusInfo,
    required this.levelStats,
    required this.onContinue,
    required this.onBackToSelection,
  });

  @override
  State<_NextLevelDialog> createState() => _NextLevelDialogState();
}

class _NextLevelDialogState extends State<_NextLevelDialog> {
  int _countdown = 3;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;

      setState(() {
        _countdown--;
      });

      return _countdown > 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    // 构建击杀统计信息
    String killStatsInfo = '';
    for (final entry in widget.levelStats.playerKillCounts.entries) {
      final playerLabel = entry.key == 0 ? l10n.player1 : l10n.player2;
      killStatsInfo += '${l10n.playerKills(playerLabel, entry.value)}\n';
    }

    return AlertDialog(
      title: Text(l10n.levelComplete),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.levelCompleteMessage(widget.currentMapName)),
          const SizedBox(height: 16),
          // 显示关卡用时
          Text(l10n.levelTime(widget.levelStats.formattedTime)),
          const SizedBox(height: 8),
          // 显示击杀统计
          if (killStatsInfo.isNotEmpty) ...[
            Text(
              killStatsInfo.trim(),
              style: const TextStyle(fontSize: 14, color: Colors.orange),
            ),
            const SizedBox(height: 12),
          ],
          Row(
            children: [
              Text(l10n.preparingNextLevel(widget.nextMap.name)),
              const SizedBox(width: 8),
              if (_countdown > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$_countdown',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
            ],
          ),
          if (widget.playerStatusInfo.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              widget.playerStatusInfo,
              style: const TextStyle(fontSize: 14, color: Colors.green),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.statusCarryOver,
              style: const TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: Colors.blue,
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: widget.onBackToSelection,
          child: Text(l10n.backToSelection),
        ),
        ElevatedButton(
          onPressed: widget.onContinue,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
          ),
          child: Text(l10n.continueNow),
        ),
      ],
    );
  }
}
