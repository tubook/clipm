# clipm

A local-first, zero-account, keyboard-driven desktop clipboard history manager inspired by Omarchy's high-contrast monospace aesthetic.

## Features (v1.0 MVP)
- **100% Local**: SQLite (Drift) + FTS5 trigram full-text search (English & CJK substrings); images stored content-addressed under `<ApplicationSupport>/images/`.
- **Seamless Paste**: Captures previous foreground window before showing overlay, writes back to OS clipboard with loop prevention, hides overlay, restores focus, and sends `Cmd+V` (macOS) / `Ctrl+V` (Windows).
- **Sensitive Content Filtering**: Drops password-manager clipboard entries (`org.nspasteboard.ConcealedType` / `TransientType` on macOS; `ExcludeClipboardContentFromMonitorProcessing` / `CanIncludeInClipboardHistory` on Windows).
- **Auto Dedup & Capacity Limit**: SHA-256 deduplication; keeps up to 500 unpinned items and automatically cleans up evicted disk images.

## Keyboard Shortcuts
- `Cmd + Ctrl + V` (macOS) / `Win + Ctrl + V` (Windows): Toggle overlay globally
- `Up / Down` or `Ctrl + P / Ctrl + N`: Navigate history list
- `Enter`: Paste selected item
- `Shift + Enter`: Paste selected item as plain text
- `Cmd + P` (macOS) / `Ctrl + Shift + P` (Windows): Toggle Pin
- `Ctrl + D` (or `Delete` when search is empty): Delete selected item & local image
- `Esc`: Hide overlay and restore focus

## Build & Run

```bash
flutter pub get
dart run build_runner build
```

### macOS
1. Open `macos/Runner.xcworkspace` in Xcode and ensure the 3 Swift files under `macos/Runner/Bridge/` (`ClipmBridgePlugin.swift`, `ClipboardMonitor.swift`, `FocusAndPasteManager.swift`) are added to the **Runner** target.
2. Run `flutter run -d macos`.
3. Grant **Accessibility** permission when prompted so `CGEvent` can synthesize `Cmd+V`.

### Windows
```powershell
flutter run -d windows
```
All C++ bridge sources (`windows/runner/bridge/*.cpp`) and `gdiplus.lib` are already wired in `windows/runner/CMakeLists.txt`.
