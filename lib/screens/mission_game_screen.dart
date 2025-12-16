import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import '../game/mission_dodgeball_game.dart';
import '../game/mission_map.dart';
import '../game/player_state.dart';

/// Mission模式游戏界面
class MissionGameScreen extends StatefulWidget {
  final MissionMap missionMap;
  final double aiIntelligenceLevel;
  final int maxHealth;
  final List<MissionMap> allMaps;
  final int currentMapIndex;
  final PlayerState? playerState; // 玩家状态（用于关卡间传递）

  const MissionGameScreen({
    super.key,
    required this.missionMap,
    this.aiIntelligenceLevel = 1.0,
    this.maxHealth = 3,
    this.allMaps = const [],
    this.currentMapIndex = 0,
    this.playerState,
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
    );
  }

  /// 关卡完成回调
  void _onMissionComplete() {
    // 获取当前玩家状态
    final currentPlayerState = game.getCurrentPlayerState();

    // 检查是否还有下一关
    final nextIndex = widget.currentMapIndex + 1;
    if (nextIndex < widget.allMaps.length) {
      // 有下一关，自动进入
      _showNextLevelDialog(nextIndex, currentPlayerState);
    } else {
      // 没有下一关，显示全部通关
      _showAllLevelsCompleteDialog();
    }
  }

  /// 任务失败回调 - 返回首页
  void _onMissionFailed() {
    if (!mounted) return;
    
    // 返回到关卡选择页面
    Navigator.of(context).pop();
  }

  /// 显示进入下一关对话框（带自动跳转）
  void _showNextLevelDialog(int nextIndex, PlayerState? playerState) {
    final nextMap = widget.allMaps[nextIndex];

    // 构建玩家状态信息
    String playerStatusInfo = '';
    if (playerState != null) {
      playerStatusInfo =
          '\n\n当前状态：\n'
          '💚 生命值：${playerState.currentHealth}\n';

      if (playerState.hasSpeedBoost) {
        playerStatusInfo +=
            '⚡ 速度提升：${playerState.speedBoostRemainingTime.toStringAsFixed(1)}秒\n';
      }
      if (playerState.hasAttackSpeedBoost) {
        playerStatusInfo +=
            '🎯 攻速提升：${playerState.attackSpeedBoostRemainingTime.toStringAsFixed(1)}秒\n';
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
        ),
      ),
    );
    // 注意：背景音乐会在新关卡的onLoad中自动重新播放
  }

  /// 显示全部关卡完成对话框
  void _showAllLevelsCompleteDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('🏆 全部通关！'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('恭喜你完成了所有关卡！'),
            const SizedBox(height: 16),
            Text('最后关卡：${widget.missionMap.name}'),
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
            child: const Text('返回'),
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
            // 游戏主体
            Center(
              child: AspectRatio(
                aspectRatio: 1280 / 720,
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black, width: 2),
                  ),
                  child: GameWidget.controlled(gameFactory: () => game),
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

            // 冷却时间进度条
            Positioned(
              top: 70,
              left: 100,
              right: 100,
              child: SafeArea(child: _buildCooldownBar()),
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
                    '击杀: $killCount / ${widget.missionMap.enemyCount}',
                    style: const TextStyle(color: Colors.white, fontSize: 16),
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

  Widget _buildCooldownBar() {
    return ValueListenableBuilder<double>(
      valueListenable: game.humanCooldownRemainingNotifier,
      builder: (context, cooldown, child) {
        final progress = cooldown > 0 ? cooldown / 10.0 : 0.0;
        return Column(
          children: [
            LinearProgressIndicator(
              value: 1.0 - progress,
              backgroundColor: Colors.grey[300],
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
              minHeight: 8,
            ),
            const SizedBox(height: 4),
            if (cooldown > 0)
              Text(
                '冷却时间: ${cooldown.toStringAsFixed(1)}秒',
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
        );
      },
    );
  }

  void _showPauseMenu() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('游戏暂停'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('地图: ${widget.missionMap.name}'),
            const SizedBox(height: 8),
            Text('目标: 消灭 ${widget.missionMap.enemyCount} 个敌人'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('继续游戏'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // 关闭对话框
              Navigator.of(context).pop(); // 返回上一页
            },
            child: const Text('退出游戏'),
          ),
        ],
      ),
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
  final VoidCallback onContinue;
  final VoidCallback onBackToSelection;

  const _NextLevelDialog({
    required this.currentMapName,
    required this.nextMap,
    required this.playerStatusInfo,
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
    return AlertDialog(
      title: const Text('🎉 关卡完成！'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('恭喜完成 ${widget.currentMapName}！'),
          const SizedBox(height: 16),
          Row(
            children: [
              Text('准备进入 ${widget.nextMap.name}'),
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
            const Text(
              '💡 你的生命值和道具效果将保留到下一关！',
              style: TextStyle(
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
          child: const Text('返回选关'),
        ),
        ElevatedButton(
          onPressed: widget.onContinue,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
          ),
          child: const Text('立即继续'),
        ),
      ],
    );
  }
}
