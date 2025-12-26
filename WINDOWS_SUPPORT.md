# Windows 平台支持说明

## 概述

躲避球游戏现已支持 Windows 平台！您可以在 Windows 系统上构建和运行游戏。

## 系统要求

### 开发环境要求

1. **Flutter SDK**: 3.0 或更高版本
2. **Visual Studio**: 2019 或更高版本（需要安装 "Desktop development with C++" 工作负载）
3. **Windows SDK**: 10.0.19041.0 或更高版本
4. **CMake**: 3.14 或更高版本（通常随 Visual Studio 一起安装）

### 运行时要求

- Windows 10 或更高版本
- 至少 4GB RAM
- 支持 DirectX 11 的显卡

## 安装步骤

### 1. 安装 Flutter

如果还没有安装 Flutter，请按照 [Flutter 官方文档](https://docs.flutter.dev/get-started/install/windows) 进行安装。

### 2. 安装 Visual Studio

1. 下载并安装 [Visual Studio 2022](https://visualstudio.microsoft.com/downloads/)
2. 在安装程序中选择 "Desktop development with C++" 工作负载
3. 确保包含以下组件：
   - Windows 10/11 SDK
   - CMake tools for Windows
   - MSVC v143 - VS 2022 C++ x64/x86 build tools

### 3. 启用 Windows 桌面支持

在项目根目录运行：

```bash
flutter config --enable-windows-desktop
```

### 4. 验证环境

运行以下命令检查环境配置：

```bash
flutter doctor
```

确保 Windows 桌面开发工具链显示为已安装。

## 构建和运行

### 开发模式运行

在项目根目录运行：

```bash
flutter run -d windows
```

### 构建发布版本

#### 构建可执行文件

```bash
flutter build windows --release
```

构建完成后，可执行文件位于：
```
build/windows/x64/runner/Release/dodgeball.exe
```

#### 构建安装包（可选）

如果需要创建安装程序，可以使用以下工具：
- [Inno Setup](https://jrsoftware.org/isinfo.php)
- [NSIS](https://nsis.sourceforge.io/)
- [WiX Toolset](https://wixtoolset.org/)

## 游戏控制

在 Windows 平台上，游戏支持以下控制方式：

### 键盘控制
- **移动**: `WASD` 或方向键（↑↓←→）
- **投掷**: `空格键` 或鼠标点击瞄准投掷

### 鼠标控制
- **瞄准**: 鼠标移动控制投掷方向
- **投掷**: 鼠标左键点击投掷

## 依赖项兼容性

所有项目依赖项都已确认支持 Windows 平台：

- ✅ `flame: ^1.30.1` - 游戏引擎，支持 Windows
- ✅ `flame_audio: ^2.10.0` - 音频系统，支持 Windows
- ✅ `shared_preferences: ^2.2.2` - 本地存储，支持 Windows
- ✅ `web_socket_channel: ^2.4.5` - WebSocket 通信，支持 Windows
- ✅ `path_provider: ^2.1.1` - 路径提供，支持 Windows

## 平台特定功能

### 文件系统

游戏使用 `path_provider` 包来获取应用文档目录，在 Windows 上路径通常为：
```
C:\Users\<用户名>\Documents\dodgeball\missions\
```

### 音频支持

`flame_audio` 在 Windows 上使用系统音频 API，支持：
- 背景音乐播放
- 音效播放
- 音量控制

### 网络功能

WebSocket 客户端在 Windows 上完全支持，可以正常连接到游戏服务器。

## 故障排除

### 构建错误

**错误：找不到 CMake**
- 确保已安装 Visual Studio 并包含 CMake 工具
- 或者单独安装 [CMake](https://cmake.org/download/)

**错误：找不到 Windows SDK**
- 在 Visual Studio Installer 中安装 Windows 10/11 SDK
- 确保版本为 10.0.19041.0 或更高

**错误：链接器错误**
- 确保安装了 "Desktop development with C++" 工作负载
- 重新运行 `flutter clean` 然后 `flutter pub get`

### 运行时错误

**游戏无法启动**
- 检查是否安装了 Visual C++ Redistributable
- 下载并安装 [Microsoft Visual C++ Redistributable](https://aka.ms/vs/17/release/vc_redist.x64.exe)

**音频无法播放**
- 检查系统音频驱动是否正常
- 确保音频文件存在于 `assets/audio/` 目录

**网络连接失败**
- 检查防火墙设置
- 确保服务器地址配置正确（见 `assets/config/server_config.json`）

## 性能优化建议

1. **构建优化**：使用 `--release` 模式构建以获得最佳性能
2. **资源管理**：确保音频和图像资源已正确优化
3. **网络优化**：在局域网环境下运行多人游戏以获得最佳体验

## 打包分发

### 创建独立可执行文件

发布版本已经包含了所有必要的 DLL 文件。您需要将以下文件一起分发：

```
dodgeball.exe
flutter_windows.dll
data/ 目录（包含所有资源文件）
```

### 推荐的文件结构

```
dodgeball/
├── dodgeball.exe
├── flutter_windows.dll
└── data/
    ├── flutter_assets/
    └── icudtl.dat
```

## 更新日志

- **2024**: 初始 Windows 平台支持
  - 添加 Windows 平台配置文件
  - 验证所有依赖项兼容性
  - 测试游戏核心功能

## 相关文档

- [Flutter Windows 开发文档](https://docs.flutter.dev/development/platform-integration/windows)
- [Flame 游戏引擎文档](https://docs.flame-engine.org/)
- [多人游戏指南](./MULTIPLAYER_GUIDE.md)

## 技术支持

如果遇到问题，请检查：
1. Flutter 和 Visual Studio 是否正确安装
2. 所有依赖项是否已更新到最新版本
3. 项目是否已运行 `flutter pub get`

