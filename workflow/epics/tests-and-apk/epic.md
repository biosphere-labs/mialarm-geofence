---
name: tests-and-apk
status: in-progress
created: 2026-02-15T20:42:41Z
updated: 2026-02-15T20:42:41Z
progress: 0%
oneshot: true
github:
---

# Epic: Tests and APK Build

## Overview
Set up Flutter/Dart unit testing for the miAlarm geofence app and build an APK for physical device testing.

## Scope
- Research and configure Flutter's built-in test framework
- Write unit tests validating the initial implementation (models, services, providers)
- Update Android SDK to v36 (required by Flutter)
- Build a debug APK for phone testing
- Verify emulator availability

## Success Criteria
- [ ] Unit tests pass via `flutter test`
- [ ] Tests cover models, services, and providers
- [ ] Debug APK builds successfully
- [ ] APK can be installed on physical device

## Notes
- Flutter uses `package:test` and `package:flutter_test` built-in
- Android SDK 36 installed, emulator `Medium_Phone_API_36.1` available
- Working from `feature/complete-stubs` branch (no staging branch yet)
