# Contributing to CookMate

Thank you for your interest in contributing to **CookMate**! We welcome contributions from developers of all experience levels to build the premier open-source culinary and recipe ecosystem.

Please review this guide before submitting issues or pull requests.

---

## Code of Conduct

This project and everyone participating in it is governed by the [CookMate Code of Conduct](CODE_OF_CONDUCT.md). By participating, you are expected to uphold this code.

---

## How Can I Contribute?

### 1. Reporting Bugs
- Check existing [GitHub Issues](https://github.com/AbdullahAzeem12/CookMate/issues) to avoid duplicates.
- Use the **Bug Report** template.
- Include clear reproduction steps, device specifications (OS, device model/emulator), Flutter SDK version (`flutter --version`), and relevant logs or stack traces.

### 2. Suggesting Enhancements & New Features
- Open an issue using the **Feature Request** template.
- Describe the motivation, culinary utility, proposed API or UI interaction, and any alternative solutions considered.

### 3. Submitting Pull Requests
- Fork the repository and create a descriptive branch from `main` (e.g., `feat/ingredient-unit-converter` or `fix/timer-background-ticker`).
- Write clean, idiomatic Dart code adhering to the project's architecture (see [ARCHITECTURE.md](ARCHITECTURE.md)).
- Include automated tests for any new features or bug fixes.
- Verify tests and static analysis pass locally before pushing.

---

## Development Setup

### Prerequisites
- [Flutter SDK](https://flutter.dev/docs/get-started/install) (`^3.22.0` or later)
- [Dart SDK](https://dart.dev/get-dart) (`^3.4.0` or later)
- Git

### Initializing the Project
```bash
git clone https://github.com/AbdullahAzeem12/CookMate.git
cd CookMate
flutter pub get
```

---

## Verification Standards

Every Pull Request must pass the following two checks without warnings or failures:

### 1. Static Analysis & Linting
```bash
flutter analyze
```
All code must comply with `analysis_options.yaml` (0 warnings, 0 errors, 0 lints).

### 2. Automated Test Suite
```bash
flutter test
```
All existing and newly added unit, widget, and domain tests must pass.

---

## Git Commit Guidelines

We adhere to the [Conventional Commits](https://www.conventionalcommits.org/) standard:

- `feat:` A new feature or capability (e.g., `feat(core): add fraction parser to recipe scaler`)
- `fix:` A bug fix (e.g., `fix(timer): prevent negative timer countdown on pause`)
- `docs:` Documentation improvements (e.g., `docs: clarify installation steps in README`)
- `test:` Adding or refactoring automated tests (e.g., `test(search): add diacritic test cases`)
- `refactor:` Code reorganization without behavioral changes
- `chore:` Maintenance tasks, dependency updates, or CI configuration

---

## Pull Request Checklist

Before submitting your PR, verify:
- [ ] Branch is rebased onto the latest `main`.
- [ ] `flutter analyze` passes with 0 issues.
- [ ] `flutter test` passes with 100% pass rate.
- [ ] New logic is covered by unit or widget tests.
- [ ] Public API methods and domain services include Dartdoc comments (`///`).
- [ ] PR title follows Conventional Commits.
- [ ] PR description explains the problem and evidence of verification.

Thank you for helping CookMate grow! 👨‍🍳✨

