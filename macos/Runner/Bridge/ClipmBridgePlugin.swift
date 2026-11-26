import Cocoa
import FlutterMacOS

final class ClipmBridgePlugin: NSObject, FlutterPlugin, FlutterStreamHandler {
    private var eventSink: FlutterEventSink?
    private var monitor: ClipboardMonitor?
    private let focusManager = FocusAndPasteManager()
    private weak var window: NSWindow?

    init(window: NSWindow?) {
        self.window = window
        super.init()
    }

    static func register(with registrar: FlutterPluginRegistrar, window: NSWindow?) {
        let instance = ClipmBridgePlugin(window: window)

        let methodChannel = FlutterMethodChannel(
            name: "com.clipm/native_bridge/methods",
            binaryMessenger: registrar.messenger
        )
        registrar.addMethodCallDelegate(instance, channel: methodChannel)

        let eventChannel = FlutterEventChannel(
            name: "com.clipm/native_bridge/events",
            binaryMessenger: registrar.messenger
        )
        eventChannel.setStreamHandler(instance)
    }

    static func register(with registrar: FlutterPluginRegistrar) {
        register(with: registrar, window: NSApp.mainWindow)
    }

    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        self.eventSink = events
        return nil
    }

    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        self.eventSink = nil
        return nil
    }

    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "startMonitoring":
            if monitor == nil {
                monitor = ClipboardMonitor { [weak self] payload in
                    DispatchQueue.main.async {
                        self?.eventSink?(payload)
                    }
                }
            }
            monitor?.start()
            result(nil)

        case "stopMonitoring":
            monitor?.stop()
            result(nil)

        case "capturePreviousApp":
            focusManager.capturePreviousApp()
            result(nil)

        case "writeClipboard":
            guard let args = call.arguments as? [String: Any],
                  let type = args["type"] as? String else {
                result(FlutterError(code: "INVALID_ARGS", message: "Missing clipboard payload", details: nil))
                return
            }
            let plainText = args["plainText"] as? String
            let richContent = args["richContent"] as? String
            let imageBytes = (args["imageBytes"] as? FlutterStandardTypedData)?.data
            monitor?.writeToPasteboard(
                type: type,
                plainText: plainText,
                richContent: richContent,
                imageBytes: imageBytes
            )
            result(nil)

        case "restoreFocusAndPaste":
            let args = call.arguments as? [String: Any]
            let simulatePaste = (args?["simulatePaste"] as? Bool) ?? true
            focusManager.restoreFocusAndPaste(window: window ?? NSApp.mainWindow, simulatePaste: simulatePaste)
            result(nil)

        case "checkAccessibilityPermission":
            let args = call.arguments as? [String: Any]
            let prompt = (args?["prompt"] as? Bool) ?? false
            result(focusManager.checkAccessibilityPermission(prompt: prompt))

        default:
            result(FlutterMethodNotImplemented)
        }
    }
}
