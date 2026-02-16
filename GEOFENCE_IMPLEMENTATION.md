# Geofence Auto-Arm — Implementation Plan

## Current Status

The geofence monitoring **backend is not yet connected**. The UI for configuring geofence settings is complete, and all the underlying service code exists, but the pieces are not wired together. This document describes what's built, what's missing, and exactly how to complete it.

## What's Already Built

### Client-Side

| Component | File | Status |
|-----------|------|--------|
| Geofence config UI | `lib/screens/geofence/geofence_screen.dart` | Complete — map, radius slider, mode selector, presence display |
| GeofenceService | `lib/services/geofence_service.dart` | Complete — location monitoring, dwell timer, entry/exit detection |
| Presence tracking | `lib/services/firestore_service.dart` | Complete — `updatePresence()` writes to Firestore |
| Geofence providers | `lib/providers/geofence_provider.dart` | Partial — site/presence providers exist, monitoring provider missing |
| GeofenceConfig model | `lib/models/site.dart` | Complete — enabled, mode, radius, dwell time, coordinates |

### Server-Side

| Component | File | Status |
|-----------|------|--------|
| Cloud Function | `functions/index.js` | Complete — `evaluateGeofence` triggers on presence changes |
| Firestore rules | `firestore.rules` | Complete — presence collection allows auth read/write |

### Packages (already in pubspec.yaml)

- `geolocator: ^13.0.2` — GPS location services
- `flutter_local_notifications: ^18.0.1` — local notification display
- `firebase_messaging: ^15.2.0` — FCM push notifications (unused)

### Android Permissions (already in AndroidManifest.xml)

- `ACCESS_FINE_LOCATION`
- `ACCESS_COARSE_LOCATION`
- `ACCESS_BACKGROUND_LOCATION`

## What's Missing

The services exist but are **never started**. Specifically:

1. **No monitoring lifecycle** — `GeofenceService.startMonitoring()` is never called
2. **No local notifications** — entry/exit events aren't surfaced to the user
3. **Cloud Function not deployed** — `evaluateGeofence` hasn't been deployed to Firebase
4. **No provider wiring** — nothing connects auth state → site loading → monitoring start

## Implementation (~70 lines across 4 files)

### Step 1: Add Monitoring Provider

**File:** `lib/providers/geofence_provider.dart` (append to end)

```dart
/// Manages geofence monitoring lifecycle.
/// Auto-starts when logged in with an enabled geofence, auto-stops on logout.
final geofenceMonitoringProvider = Provider<void>((ref) {
  final authState = ref.watch(authStateProvider);
  final siteAsync = ref.watch(primarySiteProvider);
  final geofenceService = ref.watch(geofenceServiceProvider);

  ref.onDispose(() {
    geofenceService.stopMonitoring();
  });

  authState.whenData((user) {
    if (user == null) {
      geofenceService.stopMonitoring();
      return;
    }
    siteAsync.whenData((site) {
      if (site == null || !site.geofence.enabled) {
        geofenceService.stopMonitoring();
        return;
      }
      geofenceService.startMonitoring(site);
    });
  });
});
```

### Step 2: Activate Provider in App Root

**File:** `lib/app.dart` — add one line in `MiAlarmApp.build()`:

```dart
@override
Widget build(BuildContext context, WidgetRef ref) {
  final authState = ref.watch(authStateProvider);
  ref.watch(geofenceMonitoringProvider); // <-- Add this line
  // ... rest unchanged
}
```

### Step 3: Add Local Notifications to GeofenceService

**File:** `lib/services/geofence_service.dart`

Add import and notification plugin:

```dart
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class GeofenceService {
  final _db = FirebaseFirestore.instance;
  final _notifications = FlutterLocalNotificationsPlugin();
  // ... existing fields
```

Add initialization (call at start of `startMonitoring()`):

```dart
Future<void> _initNotifications() async {
  const android = AndroidInitializationSettings('@mipmap/ic_launcher');
  await _notifications.initialize(const InitializationSettings(android: android));
}
```

Add notification helper:

```dart
Future<void> _notify(String title, String body) async {
  const details = NotificationDetails(
    android: AndroidNotificationDetails(
      'geofence', 'Geofence Events',
      channelDescription: 'Geofence entry and exit alerts',
      importance: Importance.high,
      priority: Priority.high,
    ),
  );
  await _notifications.show(0, title, body, details);
}
```

Call in `_onExitGeofence()` and `_onEnterGeofence()`:

```dart
Future<void> _onExitGeofence(Site site, Position position) async {
  // ... existing presence update code ...
  await _notify('You left ${site.name}', 'Arm the alarm?');
}

Future<void> _onEnterGeofence(Site site, Position position) async {
  // ... existing presence update code ...
  await _notify('Welcome to ${site.name}', 'Disarm the alarm?');
}
```

### Step 4: Deploy Cloud Function

**File:** `firebase.json` — add functions config:

```json
{
  "firestore": {
    "rules": "firestore.rules",
    "indexes": "firestore.indexes.json"
  },
  "functions": {
    "source": "functions"
  }
}
```

Then deploy:

```bash
cd functions && npm install && cd ..
firebase deploy --only functions --project mialarm-geofence-demo
```

**Note:** Cloud Functions require the Firebase Blaze plan (pay-as-you-go). The free tier includes 2M invocations/month. If billing is not enabled, the client-side monitoring and local notifications still work — just without server-side auto-arm.

## How It Works End-to-End

```
User walks away from home
  → Geolocator detects movement (every 50m)
  → GeofenceService calculates distance to geofence center
  → User crosses geofence boundary
  → Dwell timer starts (2 minutes)
  → User stays outside for 2 minutes
  → Confirmed exit:
      → Local notification: "You left Home — arm the alarm?"
      → Presence updated in Firestore: {inside: false}
      → Cloud Function triggers on presence change
      → Checks if anyone else is still home
      → If nobody home + auto mode: arms all partitions
      → If nobody home + prompt mode: logs prompt event
```

## Limitations (by design for demo)

- **Foreground only** — monitoring requires the app to be running. If the app is killed, monitoring stops. A production version would use an Android foreground service with a persistent notification.
- **No FCM push notifications** — the Cloud Function logs events but doesn't send push notifications. Stubs exist in `functions/index.js` (lines 72-73, 90).
- **Single user assumed** — the presence system supports multiple users per site, but the demo assumes one user.
