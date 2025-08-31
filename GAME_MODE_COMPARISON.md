# 单人模式 vs 多人模式 游戏规则对比分析

## 🎮 总体架构差异

| 方面 | 单人模式 | 多人模式 |
|------|----------|----------|
| **权威性** | 客户端权威 | 服务器权威 |
| **物理引擎** | Flutter/Flame引擎 | Go语言自制引擎 |
| **实时性** | 本地即时响应 | 网络延迟 + 插值 |
| **一致性** | 单机保证 | 服务器保证 |

## ⚽ 球的物理参数差异

### 1. 球的速度
| 模式 | 投掷方式 | 速度值 | 备注 |
|------|----------|--------|------|
| **单人模式** | 点击投掷 | 360.0 | 固定速度 |
| **单人模式** | AI投掷 | 300.0-420.0 | 随机变化 |
| **单人模式** | 键盘投掷 | 400.0 | 玩家按键 |
| **多人模式** | 所有投掷 | 400.0 | 统一固定 |

### 2. 弹跳次数
| 模式 | 弹跳次数 | 实现方式 |
|------|----------|----------|
| **单人模式** | 1-5次 (玩家), 1-4次 (AI) | 客户端随机生成 |
| **多人模式** | 1-5次 | 服务器随机生成 |

### 3. 反弹机制
| 模式 | 能量损失 | 实现位置 |
|------|----------|----------|
| **单人模式** | 无明确损失 | `ball_component.dart` |
| **多人模式** | 20%能量损失 | 服务器端 `loop.go` |

```dart
// 单人模式反弹
void reflectOnHorizontalWall() {
  velocity.y = -velocity.y;  // 简单反向
}

void reflectOnVerticalWall() {
  velocity.x = -velocity.x;  // 简单反向
}
```

```go
// 多人模式反弹
b.Velocity.X = -b.Velocity.X * 0.8  // 损失20%能量
b.Velocity.Y = -b.Velocity.Y * 0.8  // 损失20%能量
```

## 🎯 投掷冷却机制差异

### 单人模式："一球一投"机制
```dart
// 投掷锁定机制
final Set<int> playersLocked = {};

// 投掷时锁定玩家
playersLocked.add(thrower.playerId);

// 球碰撞后解锁
timer = TimerComponent(
  period: 0.05,
  repeat: true,
  onTick: () {
    if (!ball.isMounted || ball.collidedOnce) {
      playersLocked.remove(thrower.playerId);  // 解锁
      timer.removeFromParent();
    }
  },
);
```

**特点**：
- ✅ 必须等球碰撞后才能再次投掷
- ✅ 防止球满天飞的情况
- ❌ 如果球一直不碰撞会一直锁定

### 多人模式：时间冷却机制
```go
// 10秒固定冷却
const throwCooldown = 10.0

// 检查冷却时间
if ev.Throw && p.CanThrow && (currentTime - p.LastThrowTime) >= p.ThrowCooldown {
    // 允许投掷
    p.LastThrowTime = currentTime
    p.CanThrow = false
}

// 自动恢复投掷能力
if !p.CanThrow {
    if (r.State.GameTime - p.LastThrowTime) >= p.ThrowCooldown {
        p.CanThrow = true
    }
}
```

**特点**：
- ✅ 固定10秒冷却，可预期
- ✅ 不依赖球的状态
- ✅ 更符合原始需求

## 🏃 玩家移动速度

| 模式 | 速度值 | 单位 |
|------|--------|------|
| **单人模式** | 未明确定义 | Flutter像素/秒 |
| **多人模式** | 200.0 | 服务器像素/秒 |

## ⚔️ 队伍球碰撞规则

### 单人模式
```dart
// ball_component.dart 第99行
if (player.isEliminated || player.team == team) {
  return;  // 本队球不击中本队玩家
}
```

### 多人模式
```go
// loop.go handleBallPlayerCollisions
if b.Team == p.Team {
    continue  // 本队球不击中本队玩家
}
```

**结论**: ✅ **两种模式的队伍球碰撞规则一致**

## 🏆 游戏胜利条件

### 单人模式
```dart
// 淘汰赛：检查队伍存活人数
final redAlive = redPlayers.length;
final blueAlive = bluePlayers.length;

if (redAlive == 0) {
  _handleVictory(GameState.blueWins);
} else if (blueAlive == 0) {
  _handleVictory(GameState.redWins);
}

// 限时赛：计算队伍总分
final redScore = redPlayers.fold<int>(0, (sum, player) => sum + player.score);
final blueScore = bluePlayers.fold<int>(0, (sum, player) => sum + player.score);
```

### 多人模式
```go
// 由服务器控制，客户端不处理胜利逻辑
// 淘汰：更新 RedCount/BlueCount
if p.Team == TeamRed {
    r.State.RedCount--
} else {
    r.State.BlueCount--
}
```

## 📊 关键差异总结

### 🔴 **重大差异**

1. **投掷冷却机制完全不同**
   - 单人：一球一投（依赖碰撞）
   - 多人：10秒时间冷却

2. **球的反弹物理不同**
   - 单人：无能量损失
   - 多人：20%能量损失

3. **权威性和一致性**
   - 单人：客户端决定一切
   - 多人：服务器权威，客户端仅显示

### 🟡 **中等差异**

4. **球速度参数**
   - 单人：多种速度值（300-420）
   - 多人：统一400

5. **玩家移动速度**
   - 单人：未明确定义
   - 多人：200像素/秒

### 🟢 **一致的规则**

6. **队伍球碰撞规则** ✅
7. **弹跳次数范围** ✅ (1-5次)
8. **基础游戏玩法** ✅
9. **胜利条件逻辑** ✅

## 🚨 **问题和建议**

### 1. 投掷冷却不一致 ⚠️
**问题**: 单人模式的"一球一投"与多人模式的"10秒冷却"体验差异很大

**建议**: 统一为10秒冷却机制
```dart
// 在单人模式中也实现时间冷却
class PlayerComponent {
  double lastThrowTime = 0;
  double throwCooldown = 10.0;
  bool canThrow = true;
}
```

### 2. 球的物理参数不一致 ⚠️
**问题**: 反弹能量损失和速度参数不同，影响游戏手感

**建议**: 统一物理参数
- 球速度：统一为400
- 反弹：统一20%能量损失

### 3. 玩家移动速度不明确 ⚠️
**问题**: 单人模式移动速度未明确定义

**建议**: 明确定义为200像素/秒

## 🎯 **推荐的统一方案**

### 优先级1（必须统一）
1. ✅ 投掷冷却机制：改为10秒时间冷却
2. ✅ 球的物理参数：统一速度和能量损失

### 优先级2（建议统一）
3. ✅ 明确玩家移动速度
4. ✅ 统一AI行为参数

### 优先级3（保持现状）
5. 权威性差异（单机vs网络）
6. 物理引擎差异（技术实现）

通过统一这些参数，可以确保玩家在单人和多人模式之间切换时有一致的游戏体验。
