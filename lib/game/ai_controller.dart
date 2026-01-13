import 'dart:math';
import 'dart:ui';
import 'package:flame/components.dart';
import 'ball_component.dart';
import 'field_config.dart';
import 'obstacle_component.dart';
import 'player_component.dart';
import 'power_up_component.dart';
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
  double _movementSpeed = 60.0;
  double _lastThinkTime = 0.0;
  double _thinkInterval = 2.0; // AI思考间隔

  // 行为状态
  bool _isMoving = false;
  double _aggressiveness = 0.7; // 攻击性
  double _powerUpSeekingProbability = 0.4; // 寻找道具的概率
  double _powerUpDetectionRange = 200.0; // 道具检测范围

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
    _movementSpeed = 40.0 + (difficultyLevel * 20.0);
    _thinkInterval = 1.5 - (difficultyLevel * 0.5); // AI思考间隔更短，反应更快
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
      // 安全时，先检查是否有道具可以收集
      final nearbyPowerUps = _getNearbyPowerUps();

      if (nearbyPowerUps.isNotEmpty &&
          _random.nextDouble() < _powerUpSeekingProbability) {
        // 有道具且概率命中，去收集最近的道具
        PowerUpComponent? closestPowerUp;
        double minDistance = double.infinity;

        for (final powerUp in nearbyPowerUps) {
          final distance = (powerUp.position - player.center).length;
          if (distance < minDistance) {
            minDistance = distance;
            closestPowerUp = powerUp;
          }
        }

        if (closestPowerUp != null) {
          _planPowerUpCollection(closestPowerUp);
        }
      } else {
        // 没有道具或不想收集，考虑攻击或移动到更好的位置
        if (_random.nextDouble() < _aggressiveness) {
          _planAttackAction();
        } else {
          _planPositionalMovement();
        }
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
      final toBall = ball.position - player.center;
      final ballVelocity = ball.velocity;

      // 如果球在朝玩家方向移动，且距离较近
      if (toBall.dot(ballVelocity) < 0 && toBall.length < 250) {
        // 增加威胁检测距离
        balls.add(ball);
      }
    }

    return balls;
  }

  /// 获取附近的道具
  List<PowerUpComponent> _getNearbyPowerUps() {
    final powerUps = <PowerUpComponent>[];
    final game = findGame();
    if (game == null) return powerUps;

    for (final powerUp in game.children.whereType<PowerUpComponent>()) {
      final distance = (powerUp.position - player.center).length;

      // 只考虑在检测范围内且在自己队伍区域的道具
      if (distance <= _powerUpDetectionRange &&
          _isValidPosition(powerUp.position)) {
        powerUps.add(powerUp);
      }
    }

    return powerUps;
  }

  /// 计划躲避动作
  void _planEvasiveAction(List<BallComponent> threats) {
    // 找到威胁最大的球
    BallComponent? mostDangerous;
    double minDistance = double.infinity;

    for (final ball in threats) {
      final distance = (ball.position - player.center).length;
      if (distance < minDistance) {
        minDistance = distance;
        mostDangerous = ball;
      }
    }

    if (mostDangerous != null) {
      // 计算更智能的躲避位置
      const dodgeDistance = 80.0;
      final ballVelocity = mostDangerous.velocity.normalized();
      final perpendicular1 = Vector2(-ballVelocity.y, ballVelocity.x);
      final target1 = player.center + perpendicular1 * dodgeDistance;
      final target2 = player.center - perpendicular1 * dodgeDistance;

      final isTarget1Valid =
          _isValidPosition(target1) && !_wouldOverlapWithOtherPlayers(target1);
      final isTarget2Valid =
          _isValidPosition(target2) && !_wouldOverlapWithOtherPlayers(target2);

      final validTargets = <Vector2>[];
      if (isTarget1Valid) {
        validTargets.add(target1);
      }
      if (isTarget2Valid) {
        validTargets.add(target2);
      }

      if (validTargets.isNotEmpty) {
        // 从有效的躲避方向中随机选择一个
        _targetPosition = validTargets[_random.nextInt(validTargets.length)];
      } else {
        // 如果两侧都无法躲避，尝试后退
        final awayDirection = (player.center - mostDangerous.position)
            .normalized();
        _targetPosition = player.center + awayDirection * dodgeDistance;
      }

      _clampToValidPosition(); // 确保最终目标位置在有效区域内
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
        final distance = (enemy.center - player.center).length;
        if (distance < minDistance) {
          minDistance = distance;
          target = enemy;
        }
      }

      if (target != null) {
        // 检查玩家的投球冷却时间
        if (player.canThrow) {
          // 停止移动以进行瞄准和投掷
          _isMoving = false;
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

  /// 计划收集道具
  void _planPowerUpCollection(PowerUpComponent powerUp) {
    // 设置目标位置为道具位置（转换为玩家中心点）
    _targetPosition = powerUp.position + Vector2.all(18); // 道具大小的一半
    _isMoving = true;
  }

  /// 执行移动
  void _executeMovement(double dt) {
    if (!_isMoving) return;

    final distance = (_targetPosition - player.center).length;

    if (distance < 10.0) {
      // 到达目标位置
      _isMoving = false;
      return;
    }

    // 朝目标移动
    final direction = (_targetPosition - player.center).normalized();
    final movement = direction * _movementSpeed * dt;

    final newPosition = player.center + movement;

    // 确保不会移动出边界、不与其他玩家重叠、不与障碍物碰撞
    if (_isValidPosition(newPosition) &&
        !_wouldOverlapWithOtherPlayers(newPosition) &&
        !_isPositionOnObstacle(newPosition, player.size)) {
      player.center = newPosition;

      // 更新玩家的朝向方向为移动方向
      player.setDirection(direction);
    } else {
      // 如果遇到障碍物，重新规划路径
      _isMoving = false;
      _planPositionalMovement(); // 寻找新的目标位置
    }
  }

  /// 生成团队区域内的随机位置（避开障碍物）
  Vector2 _generateRandomPositionInTeamZone() {
    final isRedTeam = player.team == Team.red;
    final area = isRedTeam
        ? FieldConfig.getRedTeamArea(gameSize)
        : FieldConfig.getBluTeamArea(gameSize);

    final margin = 20.0; // 距离边界的边距
    const maxAttempts = 30; // 最多尝试30次

    for (int attempt = 0; attempt < maxAttempts; attempt++) {
      final x =
          area.left + margin + _random.nextDouble() * (area.width - margin * 2);
      final y =
          area.top + margin + _random.nextDouble() * (area.height - margin * 2);

      final position = Vector2(x, y);

      // 检查这个位置是否在障碍物上
      if (!_isPositionOnObstacle(position, player.size)) {
        return position;
      }
    }

    // 如果尝试30次都没找到，返回中心位置（容错）
    return Vector2(area.left + area.width / 2, area.top + area.height / 2);
  }

  /// 检查位置是否有效
  bool _isValidPosition(Vector2 position) {
    final isRedTeam = player.team == Team.red;

    if (isRedTeam) {
      return FieldConfig.isInRedTeamArea(
        position,
        gameSize,
        playerRadius: player.radius,
      );
    } else {
      return FieldConfig.isInBlueTeamArea(
        position,
        gameSize,
        playerRadius: player.radius,
      );
    }
  }

  /// 限制位置到有效范围
  void _clampToValidPosition() {
    final isRedTeam = player.team == Team.red;
    _targetPosition = FieldConfig.clampToTeamArea(
      _targetPosition,
      isRedTeam,
      gameSize,
      playerRadius: player.radius,
    );
  }

  bool _wouldOverlapWithOtherPlayers(Vector2 newPosition) {
    final game = findGame();
    if (game == null) return false;

    // 检查与其他玩家的距离（newPosition是中心位置）
    for (final other in game.children.whereType<PlayerComponent>()) {
      if (other == player || other.isEliminated) continue;

      final distance = newPosition.distanceTo(other.center);
      final minDistance = player.radius + other.radius + 2.0; // 额外2像素间隔

      if (distance < minDistance) {
        return true; // 会重叠
      }
    }

    return false; // 不会重叠
  }

  /// 检查位置是否在障碍物上（使用圆形碰撞检测）
  bool _isPositionOnObstacle(Vector2 position, Vector2 playerSize) {
    final game = findGame();
    if (game == null) return false;

    // playerSize 转换为半径
    final radius = playerSize.x / 2;
    // 递归检查所有障碍物组件（包括嵌套在 BrickWallComponent 中的原子砖块）
    return _checkObstacleCollisionRecursive(game, position, radius);
  }

  /// 递归检查组件树中的障碍物碰撞（圆形与矩形碰撞检测）
  bool _checkObstacleCollisionRecursive(
    Component parent,
    Vector2 circleCenter,
    double circleRadius,
  ) {
    for (final child in parent.children) {
      // 检查 ObstacleComponent（RockComponent 等）
      if (child is ObstacleComponent) {
        // ObstacleComponent 的 body.position 是中心位置
        final obstacleCenter = child.body.position;
        // 计算障碍物的矩形（左上角坐标）
        final obstacleRect = Rect.fromLTWH(
          obstacleCenter.x - child.size.x / 2,
          obstacleCenter.y - child.size.y / 2,
          child.size.x,
          child.size.y,
        );
        // 使用圆形与矩形碰撞检测
        if (_circleRectCollision(circleCenter, circleRadius, obstacleRect)) {
          return true;
        }
      }
      // 检查 AtomicBrickComponent（砖墙的原子砖块）
      else if (child is AtomicBrickComponent) {
        // AtomicBrickComponent 的 body.position 是中心位置
        final brickCenter = child.body.position;
        final brickSize = AtomicBrickComponent.atomicSize;
        // 计算砖块的矩形（左上角坐标）
        final brickRect = Rect.fromLTWH(
          brickCenter.x - brickSize / 2,
          brickCenter.y - brickSize / 2,
          brickSize,
          brickSize,
        );
        // 使用圆形与矩形碰撞检测
        if (_circleRectCollision(circleCenter, circleRadius, brickRect)) {
          return true;
        }
      }

      // 递归检查子组件（例如 BrickWallComponent 的子组件）
      if (_checkObstacleCollisionRecursive(child, circleCenter, circleRadius)) {
        return true;
      }
    }
    return false;
  }

  /// 圆形与矩形碰撞检测
  bool _circleRectCollision(
    Vector2 circleCenter,
    double circleRadius,
    Rect rect,
  ) {
    // 找到矩形上离圆心最近的点
    final closestX = circleCenter.x.clamp(rect.left, rect.right);
    final closestY = circleCenter.y.clamp(rect.top, rect.bottom);

    // 计算圆心到最近点的距离
    final distanceX = circleCenter.x - closestX;
    final distanceY = circleCenter.y - closestY;
    final distanceSquared = distanceX * distanceX + distanceY * distanceY;

    // 如果距离小于半径，则发生碰撞
    return distanceSquared < circleRadius * circleRadius;
  }

  /// 请求投球
  void _requestThrow(Vector2 targetPosition) {
    final game = findGame();
    if (game != null && game is HasThrowRequest) {
      // 投掷方向应始终朝向目标
      final throwDirection = (targetPosition - player.center).normalized();

      // 更新玩家朝向以面对目标
      player.setDirection(throwDirection);

      final throwDistance = 200.0;
      final actualTargetPosition =
          player.center + throwDirection * throwDistance;

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
