import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:dodgeball/network/server_config_manager.dart';

void main() {
  group('ServerConfigManager Tests', () {
    setUpAll(() {
      TestWidgetsFlutterBinding.ensureInitialized();
    });

    test(
      'should initialize with default config when file loading fails',
      () async {
        // 模拟文件加载失败
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(
              const MethodChannel('plugins.flutter.io/services'),
              null,
            );

        final manager = ServerConfigManager.instance;
        await manager.initialize();

        expect(manager.isInitialized, true);
        expect(manager.serverUrl, 'ws://localhost:8080/ws');
        expect(manager.fallbackServers, ['ws://localhost:8080/ws']);
      },
    );

    test('should provide singleton instance', () {
      final instance1 = ServerConfigManager.instance;
      final instance2 = ServerConfigManager.instance;

      expect(identical(instance1, instance2), true);
    });

    test('should throw error when accessing before initialization', () {
      // 创建一个新的实例来测试未初始化状态
      final manager = ServerConfigManager.instance;
      
      // 重置状态后测试
      manager.reset();
      expect(() => manager.serverUrl, throwsStateError);
      expect(() => manager.fallbackServers, throwsStateError);
      expect(() => manager.allServerUrls, throwsStateError);
    });
  });
}
