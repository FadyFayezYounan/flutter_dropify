# Repository Notes

## Shape

- This is a Flutter package repo, not a full app; package entrypoint is `lib/flutter_dropify.dart`.
- `example/` is a separate generated Flutter app with its own `pubspec.yaml`, lockfile, analyzer config, and tests.
- The generated README/CHANGELOG and current `Calculator` API are placeholders; product intent lives in `ai_specs/001-flutter_dropify.md`.
- `example/` currently does not depend on or demonstrate `flutter_dropify`; it is still the stock counter app.
- `refrences/` is intentionally misspelled in the repo and contains commented Flutter framework source references for dropdown/menu behavior.

## Toolchain

- Both root and `example/` require Dart SDK `^3.10.3`; dot-shorthand syntax is already used in `example/lib/main.dart`.
- Lints come only from `package:flutter_lints/flutter.yaml`; there are no repo-local custom lint rules.
- No Melos, CI workflow, pre-commit config, task runner, or code generation config is present.

## Commands

- Root package setup: `flutter pub get` from repo root.
- Example setup: `flutter pub get` from `example/` after changing example dependencies.
- Root analyzer: `flutter analyze` from repo root.
- Example analyzer: `flutter analyze` from `example/`.
- Root focused test: `flutter test test/flutter_dropify_test.dart` from repo root.
- Example focused test: `flutter test test/widget_test.dart` from `example/`.

## Current Verification State

- Root focused test passes: `flutter test test/flutter_dropify_test.dart`.
- Example focused test passes: `flutter test test/widget_test.dart` from `example/`.
- Root analyzer currently reports one pre-existing warning: unused `package:flutter/material.dart` import in `lib/flutter_dropify.dart`.
- Example analyzer currently passes.

## Development Gotchas

- If adding real package widgets, update the root package tests first; the existing example app will not catch package regressions until it imports the package.
- If using Flutter framework references, treat `refrences/` files as reference material only; they are commented copies, not compiled source.
- Root `.gitignore` ignores `/pubspec.lock` for the library package, but `example/pubspec.lock` is not ignored.
