# Contributing to clipm

Thank you for your interest in contributing to **clipm**! Whether you are reporting a bug, suggesting a feature, improving documentation, or submitting a pull request, your help is welcome.

Please read our [Code of Conduct](CODE_OF_CONDUCT.md) before participating.

## Ways to Contribute

- **Report bugs**: Open an issue using the [Bug Report](https://github.com/tubook/clipm/issues/new?template=bug_report.yml) template with your OS, clipm version, and clear reproduction steps.
- **Request features**: Open an issue using the [Feature Request](https://github.com/tubook/clipm/issues/new?template=feature_request.yml) template. For larger changes, opening an issue to discuss the design first helps avoid wasted effort.
- **Submit code or docs**: Fork the repository, make your changes on a feature branch, and open a pull request.

## Development Setup

### Prerequisites

- **Flutter**: `>= 3.27.0` (Dart SDK `^3.6.0`)
- **macOS**: Xcode + CocoaPods (for macOS desktop builds)
- **Windows**: Visual Studio with the "Desktop development with C++" workload (for Windows desktop builds)

### Getting Started

1. Fork and clone the repository:

   ```bash
   git clone https://github.com/<your-username>/clipm.git
   cd clipm
   ```

2. Install dependencies:

   ```bash
   flutter pub get
   ```

3. If you modify Drift database tables, DAOs, or other code-generated files, regenerate them:

   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```

4. Run locally:

   ```bash
   flutter run -d macos    # macOS
   flutter run -d windows  # Windows
   ```

## Checks Before Opening a Pull Request

Please make sure your changes pass static analysis and unit tests before submitting:

```bash
flutter analyze
flutter test
```

> On Linux, `sqlite3` native libraries (`libsqlite3-dev`) may be required to run database tests.

## Pull Request Guidelines

- Keep pull requests focused on a single bug fix or feature.
- Follow the existing Dart style and lint rules defined in `analysis_options.yaml`.
- Use clear, descriptive commit messages (Conventional Commits such as `feat:`, `fix:`, `docs:`, `chore:` are appreciated).
- Add or update unit tests when changing core logic (such as database queries, deduplication, or filtering).
- Update `README.md` or `CHANGELOG.md` if your change affects user-facing behavior.

## License

By contributing to **clipm**, you agree that your contributions will be licensed under the [MIT License](LICENSE).
