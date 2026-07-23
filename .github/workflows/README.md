# CI Workflows

## flutter_ci.yml
On every push/PR to `main`, this runs (in order):
1. `flutter pub get`
2. `dart run build_runner build` — regenerates `*.g.dart` files (Riverpod
   providers), since those aren't committed and must exist for analysis/
   tests to pass.
3. `dart format --set-exit-if-changed .` — fails the build if any file
   isn't already formatted with `dart format`. Run `dart format .`
   locally before pushing if this fails.
4. `flutter analyze` — fails on any analyzer error/warning per
   `analysis_options.yaml`.
5. `flutter test` — runs the unit test suite under `test/`.

This does **not** currently build an APK/IPA or run integration tests —
see `ARCHITECTURE.md` for the broader "enterprise-readiness" roadmap
(domain layer, integration tests, etc.) this is the first slice of.