# 输入设置功能 - 完整实现

## 功能概述

为游戏添加了完整的键盘和手柄输入配置功能，允许玩家自定义按键绑定。

## ✨ 主要功能

### 1. 键盘配置
- ✅ 支持玩家1和玩家2独立配置
- ✅ 支持字母、数字、方向键、特殊键等多种按键
- ✅ 实时按键捕获和显示
- ✅ 配置持久化保存

### 2. 手柄支持
- ✅ 自动检测手柄连接
- ✅ 摇杆控制移动
- ✅ 按钮控制投掷
- ✅ 无需额外配置

### 3. 用户界面
- ✅ 直观的设置界面
- ✅ 分标签页管理多玩家
- ✅ 实时预览按键名称
- ✅ 一键重置为默认配置

## 📁 文件结构

```
lib/
├── screens/
│   ├── input_settings_screen.dart      # 输入设置界面（新增）
│   └── game_mode_selection_screen.dart # 首页（已修改）
├── game/
│   ├── keyboard_config.dart            # 键盘配置类（已增强）
│   ├── gamepad_config.dart             # 手柄配置类
│   └── input_controller.dart           # 输入控制器
docs/
├── INPUT_SETTINGS_GUIDE.md            # 功能说明文档（新增）
└── INPUT_SETTINGS_USAGE.md            # 使用示例文档（新增）
```

## 🚀 快速开始

### 访问设置
1. 启动应用
2. 在首页右上角点击⚙️设置图标
3. 进入输入设置界面

### 配置键位
1. 选择玩家标签（玩家1或玩家2）
2. 点击要修改的操作按钮
3. 按下键盘上的目标按键
4. 点击右上角💾保存图标保存

### 重置配置
- 点击"重置为默认设置"按钮恢复默认键位

## 🎮 默认配置

### 玩家1
- 上：W
- 下：S
- 左：A
- 右：D
- 投掷：空格

### 玩家2
- 上：I
- 下：K
- 左：J
- 右：L
- 投掷：数字0

## 💾 配置存储

- 使用 `SharedPreferences` 持久化存储
- 配置在应用重启后自动加载
- 每个玩家的配置独立存储
- 存储键格式：`keyboard_config_{playerId}_{action}`

## 🔧 技术实现

### 键盘配置类 (KeyboardConfig)

```dart
class KeyboardConfig {
  final int playerId;
  LogicalKeyboardKey up;
  LogicalKeyboardKey down;
  LogicalKeyboardKey left;
  LogicalKeyboardKey right;
  LogicalKeyboardKey throwKey;
  
  // 加载配置
  static Future<KeyboardConfig> load(int playerId);
  
  // 保存配置
  Future<void> save();
  
  // 重置为默认
  Future<void> reset();
  
  // 获取按键名称
  String getKeyName(LogicalKeyboardKey key);
}
```

### 输入控制器 (InputController)

```dart
class InputController extends Component {
  InputController({
    required this.onMove,
    required this.onThrow,
    this.playerId = 0,
    KeyboardConfig? keyboardConfig,
  });
  
  // 设置键盘配置
  void setKeyboardConfig(KeyboardConfig config);
  
  // 处理键盘事件
  void handleKeyEvent(Set<LogicalKeyboardKey> keysPressed);
}
```

### 设置界面 (InputSettingsScreen)

- 使用 `KeyboardListener` 捕获键盘事件
- 使用 `TabController` 管理多玩家标签页
- 实时更新按键显示
- 支持保存和重置配置

## 📝 代码修改清单

### 新增文件
- ✅ `lib/screens/input_settings_screen.dart` - 输入设置界面
- ✅ `docs/INPUT_SETTINGS_GUIDE.md` - 功能说明文档
- ✅ `docs/INPUT_SETTINGS_USAGE.md` - 使用示例文档

### 修改文件
- ✅ `lib/screens/game_mode_selection_screen.dart` - 添加设置按钮
- ✅ `lib/game/keyboard_config.dart` - 增强键位支持和显示

### 增强内容
1. **KeyboardConfig.dart**
   - 扩展支持的按键列表（70+ 按键）
   - 改进按键名称显示（中文特殊键名）
   - 优化按键查找算法

2. **GameModeSelectionScreen.dart**
   - 在 AppBar 添加设置按钮
   - 导入 InputSettingsScreen

## 🎯 支持的按键类型

### 字母键
A-Z（26个）

### 数字键
0-9（10个）

### 方向键
↑ ↓ ← →

### 特殊键
- 空格
- 回车
- Shift（左/右）
- Ctrl（左/右）
- Alt（左/右）
- Tab
- Esc
- 退格

### 功能键
F1-F12

## 🔍 测试建议

### 功能测试
1. ✅ 打开设置界面
2. ✅ 切换玩家标签页
3. ✅ 配置各个按键
4. ✅ 保存配置
5. ✅ 重启应用验证配置加载
6. ✅ 重置为默认配置
7. ✅ 在游戏中测试按键响应

### 手柄测试
1. ✅ 连接手柄
2. ✅ 测试摇杆移动
3. ✅ 测试按钮投掷
4. ✅ 断开重连测试

## 📊 性能考虑

- 配置加载：启动时异步加载，不阻塞UI
- 按键捕获：使用 KeyboardListener，性能优秀
- 配置保存：使用 SharedPreferences，快速可靠
- 内存占用：配置数据极小，可忽略不计

## 🐛 已知问题

无已知问题

## 🚧 未来改进

- [ ] 按键冲突检测和提示
- [ ] 手柄按键重新绑定
- [ ] 预设配置方案（竞技、休闲等）
- [ ] 配置导出/导入功能
- [ ] 云同步配置
- [ ] 触摸屏虚拟按键配置

## 📞 支持

如有问题，请查看：
- [功能说明文档](docs/INPUT_SETTINGS_GUIDE.md)
- [使用示例文档](docs/INPUT_SETTINGS_USAGE.md)

## 📄 许可

与主项目保持一致

---

## 总结

✅ **功能完整**：支持键盘和手柄输入配置
✅ **用户友好**：直观的UI和实时反馈
✅ **可靠稳定**：配置持久化和自动加载
✅ **易于扩展**：清晰的代码结构和文档

**状态：已完成并可用于生产环境**

