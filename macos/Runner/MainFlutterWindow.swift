import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    
    // 设置窗口初始尺寸为 1400x900（适合显示 1280x720 的游戏内容）
    let screenSize = NSScreen.main?.frame.size ?? NSSize(width: 1920, height: 1080)
    let windowWidth: CGFloat = 1400
    let windowHeight: CGFloat = 900
    let x = (screenSize.width - windowWidth) / 2
    let y = (screenSize.height - windowHeight) / 2
    
    let windowFrame = NSRect(x: x, y: y, width: windowWidth, height: windowHeight)
    
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
    
    // 启动后自动进入全屏模式
    DispatchQueue.main.async {
      self.toggleFullScreen(nil)
    }
  }
}
