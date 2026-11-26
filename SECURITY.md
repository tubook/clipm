# Security Policy

## Supported Versions

Only the latest release of **clipm** receives security updates and fixes.

| Version | Supported          |
| ------- | ------------------ |
| 1.x     | :white_check_mark: |
| < 1.0   | :x:                |

## Privacy & Security Model

**clipm** is designed as a **100% local-first, zero-account** desktop utility:

- **No network telemetry or cloud sync**: Clipboard data never leaves your machine.
- **Local storage**: Text history is stored in a local SQLite database and images are stored content-addressed under your OS application support directory.
- **Sensitive content filtering**: Entries marked as concealed or transient by password managers (`org.nspasteboard.ConcealedType` / `org.nspasteboard.TransientType` on macOS; `ExcludeClipboardContentFromMonitorProcessing` / `CanIncludeInClipboardHistory` on Windows) are ignored and not recorded.
- **OS permissions**: On macOS, **Accessibility** permission is requested solely to restore focus to the previous window and synthesize `Cmd+V` for seamless pasting.

## Reporting a Vulnerability

**Please do not report security vulnerabilities through public GitHub issues.**

Instead, please use GitHub's **Private Vulnerability Reporting** feature on this repository:

1. Go to the [Security tab](https://github.com/tubook/clipm/security).
2. Click **"Report a vulnerability"**.
3. Provide a clear description of the issue, steps to reproduce, affected OS/version, and any suggested mitigation if you have one.

We will acknowledge your report as soon as possible and coordinate a fix and disclosure timeline with you.
