import Cocoa
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate {
  override func applicationDidFinishLaunching(_ notification: Notification) {
    super.applicationDidFinishLaunching(notification)
    terminateOtherInstances()

    NSWorkspace.shared.notificationCenter.addObserver(
      self,
      selector: #selector(handleVolumeDidMount(_:)),
      name: NSWorkspace.didMountNotification,
      object: nil
    )
  }

  override func applicationWillTerminate(_ notification: Notification) {
    NSWorkspace.shared.notificationCenter.removeObserver(self)
    super.applicationWillTerminate(notification)
  }

  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return false
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }

  private func terminateOtherInstances() {
    guard let bundleId = Bundle.main.bundleIdentifier else { return }
    let currentPid = NSRunningApplication.current.processIdentifier
    for app in NSRunningApplication.runningApplications(withBundleIdentifier: bundleId) {
      if app.processIdentifier != currentPid {
        app.terminate()
      }
    }
  }

  @objc private func handleVolumeDidMount(_ notification: Notification) {
    guard let volumeURL = notification.userInfo?[NSWorkspace.volumeURLUserInfoKey] as? URL,
          let currentBundleId = Bundle.main.bundleIdentifier else {
      return
    }

    let candidateAppURL = volumeURL.appendingPathComponent("clipm.app").standardizedFileURL
    let currentAppURL = Bundle.main.bundleURL.standardizedFileURL
    guard candidateAppURL != currentAppURL,
          FileManager.default.fileExists(atPath: candidateAppURL.path),
          Bundle(url: candidateAppURL)?.bundleIdentifier == currentBundleId else {
      return
    }

    DispatchQueue.main.async {
      NSApplication.shared.terminate(nil)
    }
  }
}
