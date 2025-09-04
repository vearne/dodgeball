# 服务器配置系统说明

## 概述

躲避球游戏现在使用配置文件来管理服务器设置，而不是在界面上手动输入。这样可以提供更好的用户体验和更稳定的配置管理。

## 配置文件位置

服务器配置文件位于：`assets/config/server_config.json`

## 配置文件格式

```json
{
  "serverUrl": "ws://localhost:8080/ws",
  "fallbackServers": [
    "ws://localhost:8080/ws",
    "ws://192.168.1.100:8080/ws"
  ]
}
```

### 配置项说明

- **serverUrl**: 主服务器地址，游戏会优先连接此服务器
- **fallbackServers**: 备用服务器列表，当主服务器连接失败时会自动尝试连接

## 修改服务器配置

### 方法1：直接编辑配置文件

1. 打开 `assets/config/server_config.json` 文件
2. 修改 `serverUrl` 为您的主服务器地址
3. 在 `fallbackServers` 数组中添加备用服务器地址
4. 保存文件
5. 重启应用

### 方法2：通过应用界面查看

1. 在游戏模式选择界面选择"多人联机模式"
2. 点击"查看服务器配置信息"按钮
3. 查看当前配置（只读）

## 配置系统特性

### 自动配置加载
- 应用启动时自动读取配置文件
- 无需手动设置服务器地址
- 支持多个备用服务器

### 错误处理
- 如果配置文件读取失败，会使用默认配置
- 默认配置：`ws://localhost:8080/ws`

### 配置验证
- 配置管理器会验证配置文件的格式
- 提供清晰的错误信息

## 技术实现

### 核心类
- `ServerConfigManager`: 配置管理器，负责读取和管理服务器配置
- `ServerConfig`: 配置数据类，定义配置结构

### 使用方式
```dart
// 获取主服务器URL
final serverUrl = ServerConfigManager.instance.serverUrl;

// 获取备用服务器列表
final fallbackServers = ServerConfigManager.instance.fallbackServers;

// 获取所有服务器URL
final allServers = ServerConfigManager.instance.allServerUrls;
```

## 注意事项

1. **配置文件修改后需要重启应用**才能生效
2. 确保配置文件格式正确，否则会使用默认配置
3. 服务器地址格式应为：`ws://host:port/path` 或 `wss://host:port/path`
4. 建议至少配置一个备用服务器以提高连接成功率

## 故障排除

### 配置未生效
- 检查配置文件格式是否正确
- 确认应用已重启
- 查看应用日志中的配置加载信息

### 连接失败
- 检查服务器地址是否正确
- 确认服务器是否正在运行
- 检查网络连接和防火墙设置

## 更新日志

- **v1.0**: 初始版本，支持基本的服务器配置管理
- 移除了界面上的服务器地址输入框
- 添加了配置信息查看界面
- 实现了自动配置加载和错误处理
