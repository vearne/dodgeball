import 'dart:math';
import 'dart:developer' as developer;

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../network/game_network_manager.dart';
import 'ball_component.dart';
import 'dodgeball_game.dart';
import 'field_background.dart';
import 'field_config.dart';
import 'game_mode.dart';
import 'mobile_controller.dart';
import 'multiplayer_dodgeball_game_ext.dart';
import 'player_component.dart';
import 'team.dart';

/// 多人模式的躲避球游戏
/// 基于网络同步，客户端主要负责显示和输入，权威状态由服务器维护
class MultiplayerDodgeballGame extends DodgeballGame {
  MultiplayerDodgeballGame({
    required this.networkManager,
    super.randomSeed,
    super.gameMode = GameMode.multiPlayer,
    super.gameplayMode,
    super.maxHealth,
    super.timeLimit,
  });

  final GameNetworkManager networkManager;

  // 网络同步相关
  bool _isNetworkSynced = false;
  final Map<String, PlayerComponent> _networkPlayers = {};
  final Map<String, BallComponent> _networkBalls = {};

  // 输入处理
  Vector2 _currentMoveInput = Vector2.zero();
  bool _throwRequested = false;
  Vector2 _aimDirection = Vector2.zero();

  // 本地玩家
  PlayerComponent? _localPlayer;
  String? get _localPlayerId => networkManager.currentPlayerId;
  Team? get _localTeam => networkManager.currentTeam;

  @override
  Future<void> onLoad() async {
    // 不调用父类的onLoad，我们要完全自定义加载过程
    await super.onLoad();

    // 不直接调用父类onLoad，手动初始化必要组件
    // 初始化音频管理器在父类中处理

    // 添加场地背景
    add(FieldBackground(gameSize: size));

    // 添加外围边界墙壁（显示用，物理由服务器处理）
    addBoundaryWalls();

    // 监听网络状态更新
    networkManager.roomInfoNotifier.addListener(_onRoomStateUpdate);
    networkManager.playersNotifier.addListener(_onPlayersUpdate);

    // 设置游戏状态更新回调
    networkManager.setGameStateUpdateCallback(_handleRoomStateMessage);

    // 播放背景音乐在父类中处理

    // 如果是移动设备，添加移动控制器
    if (MobileController.isMobileDevice) {
      addMobileController();
    }

    developer.log('多人游戏初始化完成');
  }

  @override
  void onRemove() {
    networkManager.roomInfoNotifier.removeListener(_onRoomStateUpdate);
    networkManager.playersNotifier.removeListener(_onPlayersUpdate);
    super.onRemove();
  }

  /// 处理服务器发送的房间状态消息
  void _handleRoomStateMessage(Map<String, dynamic> message) {
    try {
      final roomData = message['room'] as Map<String, dynamic>?;
      if (roomData == null) return;

      // 同步球的状态
      final ballsData = roomData['balls'] as Map<String, dynamic>? ?? {};
      _synchronizeBalls(ballsData);
    } catch (e) {
      developer.log('处理房间状态消息失败: $e');
    }
  }

  /// 同步球的状态
  void _synchronizeBalls(Map<String, dynamic> ballsData) {
    final currentBallIds = _networkBalls.keys.toSet();
    final newBallIds = ballsData.keys.toSet();

    // 移除不存在的球
    for (final ballId in currentBallIds) {
      if (!newBallIds.contains(ballId)) {
        final ball = _networkBalls[ballId];
        if (ball != null) {
          ball.removeFromParent();
          _networkBalls.remove(ballId);
        }
      }
    }

    // 添加或更新球
    for (final entry in ballsData.entries) {
      final ballData = entry.value as Map<String, dynamic>;
      final ballId = entry.key;

      if (!_networkBalls.containsKey(ballId)) {
        // 创建新球
        _createNetworkBall(ballId, ballData);
      } else {
        // 更新现有球
        _updateNetworkBall(ballId, ballData);
      }
    }
  }

  /// 创建网络球
  void _createNetworkBall(String ballId, Map<String, dynamic> ballData) {
    try {
      final positionData =
          ballData['position'] as Map<String, dynamic>? ?? {'x': 0, 'y': 0};
      final velocityData =
          ballData['velocity'] as Map<String, dynamic>? ?? {'x': 0, 'y': 0};
      final active = ballData['active'] as bool? ?? false;

      if (!active) return; // 不显示非活跃的球

      final ball = BallComponent(
        team: Team.red, // 服务器端没有队伍信息，暂时设为红队
        ownerPlayerId: 0, // 服务器端的球没有明确的拥有者
        position: Vector2(
          (positionData['x'] as num?)?.toDouble() ?? 0,
          (positionData['y'] as num?)?.toDouble() ?? 0,
        ),
        initialVelocity: Vector2(
          (velocityData['x'] as num?)?.toDouble() ?? 0,
          (velocityData['y'] as num?)?.toDouble() ?? 0,
        ),
        bounceCount: 5, // 默认弹跳次数
        onHitPlayer: (ball, player) {
          // 在多人模式下，击中逻辑由服务器处理
        },
      );

      add(ball);
      _networkBalls[ballId] = ball;
    } catch (e) {
      developer.log('创建网络球失败: $e');
    }
  }

  /// 更新网络球
  void _updateNetworkBall(String ballId, Map<String, dynamic> ballData) {
    try {
      final ball = _networkBalls[ballId];
      if (ball == null) return;

      final positionData =
          ballData['position'] as Map<String, dynamic>? ?? {'x': 0, 'y': 0};
      final active = ballData['active'] as bool? ?? false;

      if (!active) {
        // 球变为非活跃状态，移除
        ball.removeFromParent();
        _networkBalls.remove(ballId);
        return;
      }

      // 更新位置
      final targetPosition = Vector2(
        (positionData['x'] as num?)?.toDouble() ?? 0,
        (positionData['y'] as num?)?.toDouble() ?? 0,
      );

      // 使用插值平滑移动
      final lerpedX =
          ball.position.x + (targetPosition.x - ball.position.x) * 0.5;
      final lerpedY =
          ball.position.y + (targetPosition.y - ball.position.y) * 0.5;
      ball.position = Vector2(lerpedX, lerpedY);
    } catch (e) {
      developer.log('更新网络球失败: $e');
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    // 发送本地玩家输入到服务器
    _sendPlayerInput();

    // 如果是多人模式，禁用本地的物理模拟和胜利检测
    // 这些都由服务器处理
  }

  /// 发送玩家输入到服务器
  void _sendPlayerInput() {
    if (_localPlayerId == null || !networkManager.isInGame) {
      return;
    }

    // 发送移动和投掷输入
    networkManager.sendInput(
      move: _currentMoveInput,
      throwBall: _throwRequested,
      aim: _aimDirection,
    );

    // 重置投掷请求
    _throwRequested = false;
  }

  /// 处理房间状态更新
  void _onRoomStateUpdate() {
    final roomInfo = networkManager.roomInfoNotifier.value;
    if (roomInfo == null) return;

    // 更新队伍统计显示
    _updateTeamCountDisplay();
  }

  /// 处理玩家列表更新
  void _onPlayersUpdate() {
    final players = networkManager.playersNotifier.value;
    _synchronizePlayers(players);
  }

  /// 同步玩家状态
  void _synchronizePlayers(List<NetworkPlayer> networkPlayers) {
    final currentPlayerIds = _networkPlayers.keys.toSet();
    final newPlayerIds = networkPlayers.map((p) => p.id).toSet();

    // 移除不存在的玩家
    for (final playerId in currentPlayerIds) {
      if (!newPlayerIds.contains(playerId)) {
        final player = _networkPlayers[playerId];
        if (player != null) {
          player.removeFromParent();
          _networkPlayers.remove(playerId);

          // 从队伍列表中移除
          redPlayers.remove(player);
          bluePlayers.remove(player);
        }
      }
    }

    // 添加或更新玩家
    for (final networkPlayer in networkPlayers) {
      if (!_networkPlayers.containsKey(networkPlayer.id)) {
        // 创建新玩家
        _createNetworkPlayer(networkPlayer);
      } else {
        // 更新现有玩家
        _updateNetworkPlayer(networkPlayer);
      }
    }

    _isNetworkSynced = true;
  }

  /// 创建网络玩家
  void _createNetworkPlayer(NetworkPlayer networkPlayer) {
    final isLocalPlayer = networkPlayer.id == _localPlayerId;

    final player = PlayerComponent(
      team: networkPlayer.teamEnum,
      playerId: int.tryParse(networkPlayer.id) ?? 0,
      position: Vector2(networkPlayer.position.x, networkPlayer.position.y),
      controllerType: isLocalPlayer
          ? PlayerControllerType.human
          : PlayerControllerType.ai,
      radius: networkPlayer.radius,
    );

    // 设置生命值（如果是淘汰赛模式）
    if (maxHealth != null && gameplayMode == GameplayMode.elimination) {
      player.setMaxHealth(maxHealth!);
    }

    // 添加到游戏
    add(player);
    _networkPlayers[networkPlayer.id] = player;

    // 添加到队伍列表
    if (networkPlayer.teamEnum == Team.red) {
      redPlayers.add(player);
    } else {
      bluePlayers.add(player);
    }

    // 如果是本地玩家，保存引用
    if (isLocalPlayer) {
      _localPlayer = player;
    }

    developer.log('创建玩家: ${networkPlayer.name} (${networkPlayer.team})');
  }

  /// 更新网络玩家状态
  void _updateNetworkPlayer(NetworkPlayer networkPlayer) {
    final player = _networkPlayers[networkPlayer.id];
    if (player == null) return;

    // 更新位置（使用插值平滑移动）
    final targetPosition = Vector2(
      networkPlayer.position.x,
      networkPlayer.position.y,
    );
    if (!player.position.distanceTo(targetPosition).isInfinite) {
      // 简单的线性插值，可以改进为更复杂的预测算法
      final distance = player.position.distanceTo(targetPosition);
      if (distance > 5.0) {
        // 只有距离较大时才更新
        final lerpedX =
            player.position.x + (targetPosition.x - player.position.x) * 0.3;
        final lerpedY =
            player.position.y + (targetPosition.y - player.position.y) * 0.3;
        player.position = Vector2(lerpedX, lerpedY);
      }
    }

    // 更新存活状态
    if (!networkPlayer.isAlive && !player.isEliminated) {
      player.eliminate();
    }

    // 更新玩家方向（用于箭头碰撞检测）
    player.setDirection(networkPlayer.direction);
  }

  /// 处理移动设备移动输入
  void handleMobileMove(Vector2 direction) {
    _currentMoveInput = direction;
  }

  /// 处理移动设备投掷输入
  void handleMobileThrow() {
    if (_localPlayer != null && !_localPlayer!.isEliminated) {
      _throwRequested = true;
      // 简单的瞄准逻辑：朝向敌方区域中心
      final enemyAreaCenter = _localTeam == Team.red
          ? Vector2(size.x * 0.8, size.y * 0.5)
          : Vector2(size.x * 0.2, size.y * 0.5);
      _aimDirection = (enemyAreaCenter - _localPlayer!.position).normalized();
    }
  }

  @override
  KeyEventResult onKeyEvent(
    KeyEvent event,
    Set<LogicalKeyboardKey> keysPressed,
  ) {
    // 处理键盘输入
    if (_localPlayer == null || _localPlayer!.isEliminated) {
      return KeyEventResult.handled;
    }

    // 计算移动方向
    Vector2 moveDirection = Vector2.zero();

    if (keysPressed.contains(LogicalKeyboardKey.keyW) ||
        keysPressed.contains(LogicalKeyboardKey.arrowUp)) {
      moveDirection.y -= 1;
    }
    if (keysPressed.contains(LogicalKeyboardKey.keyS) ||
        keysPressed.contains(LogicalKeyboardKey.arrowDown)) {
      moveDirection.y += 1;
    }
    if (keysPressed.contains(LogicalKeyboardKey.keyA) ||
        keysPressed.contains(LogicalKeyboardKey.arrowLeft)) {
      moveDirection.x -= 1;
    }
    if (keysPressed.contains(LogicalKeyboardKey.keyD) ||
        keysPressed.contains(LogicalKeyboardKey.arrowRight)) {
      moveDirection.x += 1;
    }

    // 投掷
    if (keysPressed.contains(LogicalKeyboardKey.space)) {
      _throwRequested = true;
      // 简单的瞄准逻辑
      final enemyAreaCenter = _localTeam == Team.red
          ? Vector2(size.x * 0.8, size.y * 0.5)
          : Vector2(size.x * 0.2, size.y * 0.5);
      _aimDirection = (enemyAreaCenter - _localPlayer!.position).normalized();
    }

    _currentMoveInput = moveDirection.normalized();

    return KeyEventResult.handled;
  }

  // 禁用本地的点击投掷，改为键盘/移动设备控制
  @override
  void onTapDown(TapDownEvent event) {
    // 在多人模式下，点击用于瞄准投掷
    if (_localPlayer == null || _localPlayer!.isEliminated) return;

    _throwRequested = true;
    _aimDirection = (event.localPosition - _localPlayer!.position).normalized();
  }

  @override
  void onDoubleTapDown(DoubleTapDownEvent event) {
    // 双击也用于投掷
    if (_localPlayer == null || _localPlayer!.isEliminated) return;

    _throwRequested = true;
    _aimDirection = (event.localPosition - _localPlayer!.position).normalized();
  }

  // 禁用本地的物理和碰撞检测相关方法
  // 多人模式下由服务器处理物理

  // 多人模式下由服务器处理胜利条件

  // 多人模式下AI由服务器控制

  // 投掷请求已经通过网络发送

  /// 更新队伍统计显示
  @override
  void _updateTeamCountDisplay() {
    final roomInfo = networkManager.roomInfoNotifier.value;
    if (roomInfo == null) return;

    if (gameplayMode == GameplayMode.timeLimit) {
      // 限时赛模式：显示得分
      redTeamCountText?.text = '红队: ${roomInfo.redCount}分';
      blueTeamCountText?.text = '蓝队: ${roomInfo.blueCount}分';
    } else {
      // 淘汰赛模式：显示存活人数
      redTeamCountText?.text = '红队: ${roomInfo.redCount}';
      blueTeamCountText?.text = '蓝队: ${roomInfo.blueCount}';
    }
  }

  /// 生成队伍（多人模式下由网络同步创建玩家）
  Future<void> spawnTeams() async {
    // 在多人模式下，玩家由网络同步创建，这里只需要设置UI
    setupTeamCountDisplay();
  }

  /// 设置队伍统计显示
  void setupTeamCountDisplay() {
    // 红队统计
    redTeamCountText = TextComponent(
      text: '红队: 0',
      textRenderer: TextPaint(
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Color(0xFFE53935),
        ),
      ),
      position: Vector2(20, 20),
    );
    add(redTeamCountText!);

    // 蓝队统计
    blueTeamCountText = TextComponent(
      text: '蓝队: 0',
      textRenderer: TextPaint(
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Color(0xFF1E88E5),
        ),
      ),
      position: Vector2(size.x - 120, 20),
    );
    add(blueTeamCountText!);
  }

  /// 禁用本地的重新开始游戏
  void restartGame() {
    // 多人模式下重新开始由服务器控制
    developer.log('多人模式下无法本地重新开始游戏');
  }
}
