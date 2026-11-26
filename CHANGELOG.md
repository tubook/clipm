# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- MIT `LICENSE`, `SECURITY.md`, `CONTRIBUTING.md`, `CODE_OF_CONDUCT.md`, and `CHANGELOG.md`.
- GitHub Issue & Pull Request templates, Dependabot configuration, and CI workflow for `flutter analyze` and `flutter test`.

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

[Unreleased]: https://github.com/tubook/clipm/compare/v1.0.2...HEAD
[1.0.2]: https://github.com/tubook/clipm/compare/v1.0.1...v1.0.2
[1.0.1]: https://github.com/tubook/clipm/compare/v1.0.0...v1.0.1
[1.0.0]: https://github.com/tubook/clipm/releases/tag/v1.0.0
