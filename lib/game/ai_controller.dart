import 'dart:math';
import 'package:flame/components.dart';
import 'ball_component.dart';
import 'field_config.dart';
import 'player_component.dart';
import 'team.dart';

/// AI控制器，管理AI玩家的行为
class AIController extends Component {
  AIController({
    required this.player,
    required this.gameSize,
    this.difficultyLevel = 1.0, // 难度级别 0.5-2.0
  }) {
    _random = Random();
    _setupBehaviorTimers();
  }

  final PlayerComponent player;
  final Vector2 gameSize;
  final double difficultyLevel;

  late Random _random;
  Vector2 _targetPosition = Vector2.zero();
  double _movementSpeed = 80.0;
  double _lastThinkTime = 0.0;
  double _thinkInterval = 2.0; // AI思考间隔

  // 行为状态
  bool _isMoving = false;
  double _aggressiveness = 0.7; // 攻击性

  @override
  void onMount() {
    super.onMount();
    _setupInitialPosition();
  }

  void _setupInitialPosition() {
    // 设置AI玩家的初始目标位置
    _targetPosition = _generateRandomPositionInTeamZone();
  }

  void _setupBehaviorTimers() {
    // 根据难度调整AI行为参数
    _movementSpeed = 60.0 + (difficultyLevel * 40.0);
    _thinkInterval = 3.0 - (difficultyLevel * 1.0);
    _aggressiveness = 0.5 + (difficultyLevel * 0.3);
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (player.isEliminated) return;

    _lastThinkTime += dt;

    // AI定期重新评估情况
    if (_lastThinkTime >= _thinkInterval) {
      _think();
      _lastThinkTime = 0.0;
    }

    // 执行移动
    _executeMovement(dt);
  }

  /// AI思考过程
  void _think() {
    // 1. 评估威胁（incoming balls）
    final incomingBalls = _getIncomingBalls();

    if (incomingBalls.isNotEmpty) {
      // 有威胁时，优先躲避
      _planEvasiveAction(incomingBalls);
    } else {
      // 安全时，考虑攻击或移动到更好的位置
      if (_random.nextDouble() < _aggressiveness) {
        _planAttackAction();
      } else {
        _planPositionalMovement();
      }
    }
  }

  /// 获取朝向此玩家的球
  List<BallComponent> _getIncomingBalls() {
    final balls = <BallComponent>[];
    final game = findGame();
    if (game == null) return balls;

    for (final ball in game.children.whereType<BallComponent>()) {
      if (ball.team == player.team) continue; // 忽略己方球

      // 简单检测：球是否大致朝向玩家方向移动
      final toBall = ball.position - player.position;
      final ballVelocity = ball.velocity;

      // 如果球在朝玩家方向移动，且距离较近
      if (toBall.dot(ballVelocity) < 0 && toBall.length < 150) {
        balls.add(ball);
      }
    }

    return balls;
  }

  /// 计划躲避动作
  void _planEvasiveAction(List<BallComponent> threats) {
    // 找到威胁最大的球
    BallComponent? mostDangerous;
    double minDistance = double.infinity;

    for (final ball in threats) {
      final distance = (ball.position - player.position).length;
      if (distance < minDistance) {
        minDistance = distance;
        mostDangerous = ball;
      }
    }

    if (mostDangerous != null) {
      // 计算垂直于球移动方向的躲避位置
      final ballVelocity = mostDangerous.velocity.normalized();
      final perpendicular = Vector2(-ballVelocity.y, ballVelocity.x);

      // 随机选择左右方向
      if (_random.nextBool()) {
        perpendicular.negate();
      }

      _targetPosition = player.position + perpendicular * 80.0;
      _clampToValidPosition();
      _isMoving = true;
    }
  }

  /// 计划攻击动作
  void _planAttackAction() {
    final game = findGame();
    if (game == null) return;

    // 查找敌方活着的玩家
    final enemies = <PlayerComponent>[];
    for (final p in game.children.whereType<PlayerComponent>()) {
      if (p.team != player.team && !p.isEliminated) {
        enemies.add(p);
      }
    }

    if (enemies.isNotEmpty) {
      // 选择最近的敌人作为目标
      PlayerComponent? target;
      double minDistance = double.infinity;

      for (final enemy in enemies) {
        final distance = (enemy.position - player.position).length;
        if (distance < minDistance) {
          minDistance = distance;
          target = enemy;
        }
      }

      if (target != null) {
        // 检查玩家的投球冷却时间
        if (player.canThrow) {
          // 请求投球（将通过游戏主逻辑处理）
          _requestThrow(target.position);
        }
      }
    }
  }

  /// 计划位置移动
  void _planPositionalMovement() {
    // 移动到团队区域内的随机位置
    _targetPosition = _generateRandomPositionInTeamZone();
    _isMoving = true;
  }

  /// 执行移动
  void _executeMovement(double dt) {
    if (!_isMoving) return;

    final distance = (_targetPosition - player.position).length;

    if (distance < 10.0) {
      // 到达目标位置
      _isMoving = false;
      return;
    }

    // 朝目标移动
    final direction = (_targetPosition - player.position).normalized();
    final movement = direction * _movementSpeed * dt;

    final newPosition = player.position + movement;

    // 确保不会移动出边界且不与其他玩家重叠
    if (_isValidPosition(newPosition) &&
        !_wouldOverlapWithOtherPlayers(newPosition)) {
      player.position = newPosition;

      // 更新玩家的朝向方向为移动方向
      player.setDirection(direction);
    } else {
      _isMoving = false;
    }
  }

  /// 生成团队区域内的随机位置
  Vector2 _generateRandomPositionInTeamZone() {
    final isRedTeam = player.team == Team.red;
    final area = isRedTeam
        ? FieldConfig.getRedTeamArea(gameSize)
        : FieldConfig.getBluTeamArea(gameSize);

    final margin = 20.0; // 距离边界的边距
    final x =
        area.left + margin + _random.nextDouble() * (area.width - margin * 2);
    final y =
        area.top + margin + _random.nextDouble() * (area.height - margin * 2);

    return Vector2(x, y);
  }

  /// 检查位置是否有效
  bool _isValidPosition(Vector2 position) {
    final isRedTeam = player.team == Team.red;

    if (isRedTeam) {
      return FieldConfig.isInRedTeamArea(position, gameSize);
    } else {
      return FieldConfig.isInBlueTeamArea(position, gameSize);
    }
  }

  /// 限制位置到有效范围
  void _clampToValidPosition() {
    final isRedTeam = player.team == Team.red;
    _targetPosition = FieldConfig.clampToTeamArea(
      _targetPosition,
      isRedTeam,
      gameSize,
    );
  }

  bool _wouldOverlapWithOtherPlayers(Vector2 newPosition) {
    final game = findGame();
    if (game == null) return false;

    // 检查与其他玩家的距离
    for (final other in game.children.whereType<PlayerComponent>()) {
      if (other == player || other.isEliminated) continue;

      final distance = newPosition.distanceTo(other.position);
      final minDistance = player.radius + other.radius + 2.0; // 额外2像素间隔

      if (distance < minDistance) {
        return true; // 会重叠
      }
    }

    return false; // 不会重叠
  }

  /// 请求投球
  void _requestThrow(Vector2 targetPosition) {
    final game = findGame();
    if (game != null && game is HasThrowRequest) {
      // 使用玩家的当前朝向方向作为投掷方向
      Vector2 throwDirection = player.currentDirection;
      if (throwDirection.length <= 0.1) {
        // 如果没有朝向方向，计算到目标的方向
        throwDirection = (targetPosition - player.position).normalized();
      }

      final throwDistance = 200.0;
      final actualTargetPosition =
          player.position + throwDirection * throwDistance;

      (game as HasThrowRequest).requestThrowFromAI(
        player,
        actualTargetPosition,
      );
    }
  }
}

/// 混入，用于游戏接收AI投球请求
mixin HasThrowRequest {
  void requestThrowFromAI(PlayerComponent thrower, Vector2 target);
}

/// 混入，用于游戏接收玩家投球请求
mixin HasPlayerThrowRequest {
  void requestThrowFromPlayer(PlayerComponent thrower, Vector2 target);
}
