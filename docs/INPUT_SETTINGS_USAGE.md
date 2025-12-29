# 输入设置使用示例

## 快速开始

### 1. 打开设置界面

在游戏首页，点击右上角的⚙️图标即可进入输入设置界面。

```dart
// 在代码中打开设置界面
Navigator.of(context).push(
  MaterialPageRoute(
    builder: (context) => const InputSettingsScreen(),
  ),
);
```

### 2. 配置键位

选择玩家标签页（玩家1或玩家2），然后：
1. 点击要修改的按键按钮
2. 按下键盘上的目标按键
3. 按键会立即更新
4. 点击右上角的保存图标保存配置

### 3. 在游戏中使用

配置会自动加载到游戏中，无需额外代码。

## 代码集成示例

### 加载玩家配置

```dart
// 在游戏初始化时加载配置
final player1Config = await KeyboardConfig.load(0);
final player2Config = await KeyboardConfig.load(1);

// 创建输入控制器
final inputController = InputController(
  playerId: 0,
  keyboardConfig: player1Config,
  onMove: (direction) {
    // 处理移动
  },
  onThrow: (direction) {
    // 处理投掷
  },
);
```

### 保存配置

```dart
// 修改配置后保存
final config = KeyboardConfig(
  playerId: 0,
  up: LogicalKeyboardKey.keyW,
  down: LogicalKeyboardKey.keyS,
  left: LogicalKeyboardKey.keyA,
  right: LogicalKeyboardKey.keyD,
  throwKey: LogicalKeyboardKey.space,
);

await config.save();
```

### 重置配置

```dart
// 重置为默认配置
await config.reset();
```

## 默认配置

### 玩家1
- **上**：W
- **下**：S
- **左**：A
- **右**：D
- **投掷**：空格

### 玩家2
- **上**：I
- **下**：K
- **左**：J
- **右**：L
- **投掷**：数字0

## 键盘事件处理

输入控制器会自动处理键盘事件：

```dart
// InputController 内部实现
void _updateKeyboardInput() {
  _movementInput = Vector2.zero();

  // 使用配置的按键
  if (_pressedKeys.contains(_keyboardConfig.up)) {
    _movementInput.y -= 1;
  }
  if (_pressedKeys.contains(_keyboardConfig.down)) {
    _movementInput.y += 1;
  }
  if (_pressedKeys.contains(_keyboardConfig.left)) {
    _movementInput.x -= 1;
  }
  if (_pressedKeys.contains(_keyboardConfig.right)) {
    _movementInput.x += 1;
  }

  // 投掷键
  if (_pressedKeys.contains(_keyboardConfig.throwKey)) {
    if (_movementInput.length > 0.1) {
      onThrow(_movementInput.normalized());
    }
  }
}
```

## 手柄支持

手柄输入会自动工作，无需配置：

```dart
// 手柄配置会自动处理输入
final gamepadConfig = GamepadConfig(playerId: 0);

// 处理手柄输入
final (direction, shouldThrow) = gamepadConfig.handleGamepadInput(keysPressed);
```

## 常见用例

### 1. 检查按键名称

```dart
final config = await KeyboardConfig.load(0);
final upKeyName = config.getKeyName(config.up); // 返回 "W"
```

### 2. 获取默认配置

```dart
final defaultConfig = KeyboardConfig.getDefault(0);
```

### 3. 动态更新配置

```dart
// 在游戏设置界面更新配置
setState(() {
  config.up = LogicalKeyboardKey.arrowUp;
});
await config.save();
```

## 多玩家配置

支持两个玩家独立配置：

```dart
// 玩家1
final player1Config = await KeyboardConfig.load(0);
final player1Controller = InputController(
  playerId: 0,
  keyboardConfig: player1Config,
  // ...
);

// 玩家2
final player2Config = await KeyboardConfig.load(1);
final player2Controller = InputController(
  playerId: 1,
  keyboardConfig: player2Config,
  // ...
);
```

## 注意事项

1. **配置持久化**：配置会保存在本地，应用重启后自动加载
2. **按键冲突**：建议为不同玩家配置不同的按键
3. **手柄优先**：如果同时连接手柄和键盘，手柄输入优先级更高
4. **实时更新**：配置更改后需要保存才能在下次启动时生效

## 扩展功能

### 添加新的操作

如需添加新的操作（如跳跃、防御等），可以扩展 `KeyboardConfig` 类：

```dart
class KeyboardConfig {
  // 现有字段
  LogicalKeyboardKey up;
  LogicalKeyboardKey down;
  LogicalKeyboardKey left;
  LogicalKeyboardKey right;
  LogicalKeyboardKey throwKey;
  
  // 新增字段
  LogicalKeyboardKey jumpKey;    // 跳跃
  LogicalKeyboardKey defendKey;  // 防御
  
  // 更新构造函数和保存/加载逻辑
}
```

### 添加预设配置

可以添加预设配置供用户快速选择：

```dart
class KeyboardPresets {
  static KeyboardConfig wasd() {
    return KeyboardConfig(
      playerId: 0,
      up: LogicalKeyboardKey.keyW,
      down: LogicalKeyboardKey.keyS,
      left: LogicalKeyboardKey.keyA,
      right: LogicalKeyboardKey.keyD,
      throwKey: LogicalKeyboardKey.space,
    );
  }
  
  static KeyboardConfig arrows() {
    return KeyboardConfig(
      playerId: 0,
      up: LogicalKeyboardKey.arrowUp,
      down: LogicalKeyboardKey.arrowDown,
      left: LogicalKeyboardKey.arrowLeft,
      right: LogicalKeyboardKey.arrowRight,
      throwKey: LogicalKeyboardKey.enter,
    );
  }
}
```

## 调试技巧

### 打印当前配置

```dart
void printConfig(KeyboardConfig config) {
  print('Player ${config.playerId} Config:');
  print('  Up: ${config.getKeyName(config.up)}');
  print('  Down: ${config.getKeyName(config.down)}');
  print('  Left: ${config.getKeyName(config.left)}');
  print('  Right: ${config.getKeyName(config.right)}');
  print('  Throw: ${config.getKeyName(config.throwKey)}');
}
```

### 检查按键ID

```dart
void checkKeyId(LogicalKeyboardKey key) {
  print('Key: ${key.debugName}, ID: ${key.keyId}');
}
```

## 测试

### 测试配置保存和加载

```dart
test('KeyboardConfig save and load', () async {
  final config = KeyboardConfig.getDefault(0);
  config.up = LogicalKeyboardKey.arrowUp;
  
  await config.save();
  
  final loadedConfig = await KeyboardConfig.load(0);
  expect(loadedConfig.up, equals(LogicalKeyboardKey.arrowUp));
});
```

### 测试输入控制器

```dart
testWidgets('InputController handles keyboard input', (tester) async {
  var moveDirection = Vector2.zero();
  
  final controller = InputController(
    playerId: 0,
    onMove: (direction) {
      moveDirection = direction;
    },
    onThrow: (direction) {},
  );
  
  // 模拟按键事件
  controller.handleKeyEvent({LogicalKeyboardKey.keyW});
  
  // 验证移动方向
  expect(moveDirection.y, lessThan(0));
});
```

