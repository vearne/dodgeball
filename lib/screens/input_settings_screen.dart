import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../game/keyboard_config.dart';

/// 输入设置界面 - 配置键盘和手柄按键绑定
class InputSettingsScreen extends StatefulWidget {
  const InputSettingsScreen({super.key});

  @override
  State<InputSettingsScreen> createState() => _InputSettingsScreenState();
}

class _InputSettingsScreenState extends State<InputSettingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // 玩家1和玩家2的键盘配置
  late KeyboardConfig _player1KeyboardConfig;
  late KeyboardConfig _player2KeyboardConfig;

  // 是否正在等待按键输入
  String? _waitingForKey;
  int _waitingForPlayer = 0;

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadConfigs();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadConfigs() async {
    // 加载保存的配置
    _player1KeyboardConfig = await KeyboardConfig.load(0);
    _player2KeyboardConfig = await KeyboardConfig.load(1);
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _saveConfigs() async {
    await _player1KeyboardConfig.save();
    await _player2KeyboardConfig.save();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('设置已保存'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _resetToDefaults(int playerId) async {
    final config =
        playerId == 0 ? _player1KeyboardConfig : _player2KeyboardConfig;
    await config.reset();
    setState(() {});
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('玩家${playerId + 1}的设置已重置为默认值'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _startWaitingForKey(int playerId, String action) {
    setState(() {
      _waitingForKey = action;
      _waitingForPlayer = playerId;
    });
  }

  void _handleKeyPress(KeyEvent event) {
    if (_waitingForKey != null && event is KeyDownEvent) {
      final key = event.logicalKey;
      final config = _waitingForPlayer == 0
          ? _player1KeyboardConfig
          : _player2KeyboardConfig;

      setState(() {
        switch (_waitingForKey) {
          case '上':
            config.up = key;
            break;
          case '下':
            config.down = key;
            break;
          case '左':
            config.left = key;
            break;
          case '右':
            config.right = key;
            break;
          case '投掷':
            config.throwKey = key;
            break;
        }
        _waitingForKey = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final focusNode = FocusNode();
    
    // 在构建完成后请求焦点
    WidgetsBinding.instance.addPostFrameCallback((_) {
      focusNode.requestFocus();
    });
    
    return KeyboardListener(
      focusNode: focusNode,
      autofocus: true,
      onKeyEvent: _handleKeyPress,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('输入设置'),
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          bottom: TabBar(
            controller: _tabController,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: const [
              Tab(text: '玩家1 (键盘)'),
              Tab(text: '玩家2 (键盘)'),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.save),
              tooltip: '保存设置',
              onPressed: _saveConfigs,
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                controller: _tabController,
                children: [
                  _buildPlayerKeyboardSettings(0, _player1KeyboardConfig),
                  _buildPlayerKeyboardSettings(1, _player2KeyboardConfig),
                ],
              ),
      ),
    );
  }

  Widget _buildPlayerKeyboardSettings(int playerId, KeyboardConfig config) {
    final isPlayer1 = playerId == 0;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 说明卡片
          Card(
            color: Colors.blue[50],
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue[700]),
                      const SizedBox(width: 8),
                      Text(
                        '玩家${playerId + 1} - 键盘设置',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '点击下方按钮后，按下您想要绑定的键位。\n'
                    '支持字母键、数字键、方向键、空格等。',
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // 键位设置
          _buildKeyBindingCard(
            title: '移动控制',
            icon: Icons.gamepad,
            children: [
              _buildKeyBinding(playerId, '上', config.up, config),
              _buildKeyBinding(playerId, '下', config.down, config),
              _buildKeyBinding(playerId, '左', config.left, config),
              _buildKeyBinding(playerId, '右', config.right, config),
            ],
          ),
          const SizedBox(height: 16),

          _buildKeyBindingCard(
            title: '动作控制',
            icon: Icons.sports_baseball,
            children: [
              _buildKeyBinding(playerId, '投掷', config.throwKey, config),
            ],
          ),
          const SizedBox(height: 24),

          // 重置按钮
          OutlinedButton.icon(
            onPressed: () => _resetToDefaults(playerId),
            icon: const Icon(Icons.refresh),
            label: const Text('重置为默认设置'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),

          const SizedBox(height: 16),

          // 默认配置说明
          Card(
            color: Colors.grey[100],
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '默认配置',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isPlayer1
                        ? '玩家1: WASD移动 + 空格投掷'
                        : '玩家2: IJKL移动 + 数字0投掷',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ),

          // 手柄说明
          const SizedBox(height: 16),
          Card(
            color: Colors.amber[50],
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(Icons.videogame_asset, color: Colors.amber[700]),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '手柄支持：连接手柄后可直接使用摇杆和按钮控制，无需额外配置。',
                      style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKeyBindingCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.blue[700], size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildKeyBinding(
    int playerId,
    String action,
    LogicalKeyboardKey key,
    KeyboardConfig config,
  ) {
    final isWaiting = _waitingForKey == action && _waitingForPlayer == playerId;
    final keyName = config.getKeyName(key);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            child: Text(
              action,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 200, // 固定宽度，让输入框更紧凑
            child: ElevatedButton(
              onPressed: () => _startWaitingForKey(playerId, action),
              style: ElevatedButton.styleFrom(
                backgroundColor: isWaiting ? Colors.orange : Colors.blue[100],
                foregroundColor: isWaiting ? Colors.white : Colors.blue[900],
                elevation: isWaiting ? 4 : 1,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: Text(
                isWaiting ? '按下任意键...' : keyName,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isWaiting ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

