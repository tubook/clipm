import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override var canBecomeKey: Bool { true }
  override var canBecomeMain: Bool { true }

  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    flutterViewController.backgroundColor = .clear
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    self.styleMask = [.borderless]
    self.isOpaque = false
    self.backgroundColor = .clear
    self.hasShadow = true
    self.level = .floating
    self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

    RegisterGeneratedPlugins(registry: flutterViewController)
    ClipmBridgePlugin.register(
      with: flutterViewController.registrar(forPlugin: "ClipmBridgePlugin"),
      window: self
    )

    super.awakeFromNib()
  }
}
