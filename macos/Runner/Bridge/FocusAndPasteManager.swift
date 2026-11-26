import ApplicationServices
import Carbon.HIToolbox
import Cocoa

final class FocusAndPasteManager {
    private weak var previousApp: NSRunningApplication?

    func capturePreviousApp() {
        let frontmost = NSWorkspace.shared.frontmostApplication
        let selfPid = ProcessInfo.processInfo.processIdentifier
        if let app = frontmost, app.processIdentifier != selfPid {
            previousApp = app
        }
    }

    func restoreFocusAndPaste(window: NSWindow?, simulatePaste: Bool) {
        window?.orderOut(nil)
        NSApp.hide(nil)

        if let targetApp = previousApp, !targetApp.isTerminated {
            if #available(macOS 14.0, *) {
                targetApp.activate()
            } else {
                targetApp.activate(options: [.activateIgnoringOtherApps])
            }
        }

        guard simulatePaste else { return }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
            self.sendCommandV()
        }
    }

    func checkAccessibilityPermission(prompt: Bool) -> Bool {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: prompt] as CFDictionary
        return AXIsProcessTrustedWithOptions(options)
    }

    private func sendCommandV() {
        guard let source = CGEventSource(stateID: .combinedSessionState) else { return }
        let vKeyCode = CGKeyCode(kVK_ANSI_V)

        guard let keyDown = CGEvent(keyboardEventSource: source, virtualKey: vKeyCode, keyDown: true),
              let keyUp = CGEvent(keyboardEventSource: source, virtualKey: vKeyCode, keyDown: false) else {
            return
        }

        keyDown.flags = .maskCommand
        keyUp.flags = .maskCommand

        keyDown.post(tap: .cgAnnotatedSessionEventTap)
        keyUp.post(tap: .cgAnnotatedSessionEventTap)
    }
}
