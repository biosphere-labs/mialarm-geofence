# miAlarm Clone with Geofence Auto-Arm

A functional Flutter clone of Finmon's miAlarm app with an added geofencing auto-arm/disarm feature. Built as a portfolio piece demonstrating Flutter, Firebase, and domain knowledge in the South African alarm monitoring industry.

miAlarm already requests location permission for emergency GPS sharing but doesn't offer background tracking or geofencing ([source](https://www.finmon.co.za/kb/books/mialarm-app/page/advanced-configuration)). This project adds geofence auto-arm as an opt-in feature — ideal for users who routinely forget to arm when leaving or fumble to disarm on arrival. Competitors like Ajax already offer this. See [FEATURE_BRIEF.md](FEATURE_BRIEF.md) for the full business case.

## What It Does

- Arm/disarm alarm partitions (House, Perimeter) with Home and Sleep modes
- Control outputs — gates, garage doors, lights
- View and bypass individual zones
- Event history with filtering
- Geofence auto-arm: automatically arms when everyone leaves home
- Multi-user presence tracking: only arms when the *last* person leaves
- Push notification prompts for security-sensitive actions

Backed by Firebase (Auth, Firestore, Cloud Functions, FCM) simulating a real alarm panel. The architecture mirrors production — swapping the simulated backend for the real Finmon API would be a single service layer change.

## Hand-Built Sections

Parts of this app were built by hand as a Flutter learning exercise. Scaffold and complex integrations were provided; core UI, state management, and widget composition were implemented manually.

| Task | What I Built | Concepts Practiced | Time |
|------|-------------|-------------------|------|
| Login screen | `lib/screens/auth/login_screen.dart` | StatefulWidget, forms, async/await, navigation | ~30 min |
| Dashboard | `lib/screens/dashboard/dashboard_screen.dart` | Riverpod ConsumerWidget, layout composition, streams | ~45 min |
| Output button | `lib/screens/dashboard/output_button.dart` | Reusable widgets, callbacks, optimistic UI | ~30 min |
| Panel provider | `lib/providers/panel_provider.dart` | Riverpod StreamProvider, derived state, Firestore streams | ~30 min |
| Zone list | `lib/screens/zones/zone_list_screen.dart` | ListView.builder, data grouping, confirmation dialogs | ~45 min |

## Setup

```bash
# Prerequisites
flutter --version    # 3.x required
firebase --version   # Firebase CLI
dart pub global activate flutterfire_cli

# Configure Firebase
flutterfire configure

# Install dependencies
flutter pub get

# Run
flutter run
```

After first login, go to Settings and tap "Seed Demo Data" to populate the database.

## Architecture

```
Flutter App (Riverpod) → Firebase Auth + Firestore → Cloud Functions
                                                          ↓
                                                    Simulated Panel State
                                                    Push Notifications (FCM)
                                                    Geofence Evaluation
```

## Tech Stack

- **Flutter 3.x** with Riverpod state management
- **Firebase** (Auth, Firestore, Cloud Functions, FCM)
- **GoRouter** for declarative navigation
- **Geolocator** for GPS/geofence monitoring
