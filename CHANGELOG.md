# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.2.0] - 2026-11-27

### Added
- Smart preview renderers in `PreviewPane`: color swatches (`#Hex` / `rgb()` / `rgba()`), clickable HTTP(S) URL banner with `Cmd/Ctrl + O` open-in-browser, formatted/raw JSON toggle, and `Cmd/Ctrl + S` image export to Downloads.
- Keyboard-driven Quick Action Palette (`Cmd/Ctrl + K`) supporting Copy Only (without auto-paste) and instant text transforms (Trim, Single Line, Uppercase/Lowercase, camelCase/snake_case, Pretty/Minify JSON, URL & Base64 Encode/Decode).
- Native file clipboard support on macOS (`NSPasteboard` `.fileURL`) and Windows (`CF_HDROP`) with `FILE` filter pill, file list preview, native file paste (`Enter`), and plain path paste (`Shift+Enter`).
- Unit tests for `ContentDetector`, `TextTransforms`, file clipboard ingestion/write-back, and collision-safe image Downloads export.

## [1.1.1] - 2026-11-27

### Added
- macOS `.pkg` installer (`clipm-*-macos.pkg`) with a `preinstall` script that automatically quits running `clipm` instances before upgrading `/Applications/clipm.app`.
- Automatic graceful exit on macOS when a `clipm` installer DMG is mounted, plus single-instance handoff on launch.

### Fixed
- macOS DMG background text rendering upside-down and shortcut pill vertical centering in `render_dmg_bg.swift`.
- Popup overlay typography switched from `Menlo` to native macOS system UI font (`SF Pro`) and `SF Mono` with tabular figures.
- Bottom status bar vertical centering and single-baseline alignment for shortcut hints and metadata.
- Search input thick block cursor obscuring placeholder text and filter chip vertical alignment.

## [1.1.0] - 2026-11-27

### Added
- Quick-paste keyboard shortcuts (`Cmd+1~9` on macOS / `Ctrl+1~9` on Windows, with `Shift` for plain text) and 1–9 slot indicators in the history list.
- Category filter pills (`ALL / TXT / IMG / PIN`) toggled with `Tab` / `Shift+Tab`, plus `@app:<name>` source-application search syntax.
- Inline Preferences view (`Cmd+,` / `Ctrl+,`) persisted locally to `settings.json`: custom global hotkey recorder, configurable unpinned history cap & retention days, launch at login (macOS `SMAppService` / Windows `HKCU\...\Run`), privacy pause toggle, ignored app blacklist, and multi-monitor cursor-screen positioning.
- Tray menu actions for **Pause / Resume Monitoring** and **Settings...**.
- Unit tests covering DAO filtering/retention, settings persistence/recovery, and monitor pause/blacklist behavior.

## [1.0.2] - 2026-11-26

### Fixed
- macOS DMG installer Retina HiDPI TIFF background, light canvas for crisp Finder labels, and bottom margin layout.

## [1.0.1] - 2026-11-26

### Added
- Custom app and system tray icons for macOS and Windows.
- Styled macOS DMG installer background.

### Fixed
- Transparent rounded overlay frame rendering without clipped corners.

## [1.0.0] - 2026-11-26

### Added
- Local-first desktop clipboard history manager for macOS and Windows built with Flutter and Drift (SQLite + FTS5 trigram search).
- Seamless paste workflow with previous window focus restoration and paste loop prevention.
- Sensitive clipboard content filtering for password managers on macOS and Windows.
- SHA-256 deduplication, pinning, and automatic pruning of up to 500 unpinned items with disk image cleanup.
- GitHub Actions release workflow for macOS (`.dmg`, `.zip`) and Windows (`x64 .zip`).

[Unreleased]: https://github.com/tubook/clipm/compare/v1.1.1...HEAD
[1.1.1]: https://github.com/tubook/clipm/compare/v1.1.0...v1.1.1
[1.1.0]: https://github.com/tubook/clipm/compare/v1.0.5...v1.1.0
[1.0.2]: https://github.com/tubook/clipm/compare/v1.0.1...v1.0.2
[1.0.1]: https://github.com/tubook/clipm/compare/v1.0.0...v1.0.1
[1.0.0]: https://github.com/tubook/clipm/releases/tag/v1.0.0
