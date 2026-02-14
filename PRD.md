# miAlarm Clone - Product Requirements Document

## Project Overview

A functional Flutter clone of Finmon's **miAlarm** app with an added **geofencing auto-arm/disarm** feature that their competitors offer but they currently lack. Built as a portfolio/interview demonstration piece with a Firebase backend simulating panel state.

**Target company**: Finmon (PTY) LTD - South African alarm monitoring communications company
**Their stack**: Flutter (mentioned in job listing)
**Their apps**: miAlarm (consumer), finMonitor (control room), finmonTech (technician)

---

## Architecture

### System Diagram

```
┌─────────────────────────────────────────────────────┐
│                   Flutter App                        │
│                                                      │
│  ┌──────────┐  ┌──────────┐  ┌───────────────────┐  │
│  │ Auth     │  │ Panel    │  │ Geofence          │  │
│  │ Screens  │  │ Control  │  │ Manager           │  │
│  │          │  │ Screens  │  │                   │  │
│  └────┬─────┘  └────┬─────┘  └────┬──────────────┘  │
│       │              │             │                  │
│  ┌────▼──────────────▼─────────────▼──────────────┐  │
│  │           State Management (Riverpod)           │  │
│  └────┬──────────────┬─────────────┬──────────────┘  │
│       │              │             │                  │
│  ┌────▼────┐  ┌──────▼─────┐  ┌───▼──────────────┐  │
│  │ Auth    │  │ Firestore  │  │ Location         │  │
│  │ Service │  │ Service    │  │ Service          │  │
│  └────┬────┘  └──────┬─────┘  └───┬──────────────┘  │
└───────┼──────────────┼─────────────┼─────────────────┘
        │              │             │
   ┌────▼────┐  ┌──────▼─────┐  ┌───▼──────────────┐
   │Firebase │  │ Firestore  │  │ Phone GPS        │
   │  Auth   │  │  Database  │  │ (Native)         │
   └─────────┘  └──────┬─────┘  └──────────────────┘
                       │
                ┌──────▼──────┐
                │  Cloud      │
                │  Functions  │
                │ (triggers,  │
                │  FCM push)  │
                └─────────────┘
```

### Tech Stack

| Layer | Technology | Purpose |
|-------|-----------|---------|
| UI | Flutter 3.x | Cross-platform mobile app |
| State | Riverpod | Reactive state management |
| Auth | Firebase Auth | Email/password login |
| Database | Cloud Firestore | Real-time panel state, events, geofence data |
| Push | Firebase Cloud Messaging (FCM) | Alarm event notifications |
| Backend Logic | Cloud Functions (Node.js) | Geofence evaluation, event logging |
| Location | `geolocator` + `flutter_local_notifications` | GPS tracking, geofence detection |
| Routing | GoRouter | Declarative navigation |

### Why Riverpod (not Provider, not BLoC)

You'll see three state management approaches discussed in Flutter circles. Here's why we're using Riverpod:

- **Provider** is the predecessor. Riverpod fixes its limitations (no BuildContext dependency, better testing, compile-safe).
- **BLoC** is powerful but ceremony-heavy. For an app this size, the boilerplate overhead isn't justified.
- **Riverpod** is the current community recommendation. It's what you'd reach for on a new project in 2026. If Finmon asks "why Riverpod?" you have a clear answer.

---

## Data Model

### Firestore Collections

```
users/
  {userId}/
    email: string
    displayName: string
    createdAt: timestamp

sites/
  {siteId}/
    name: string                    # "Home", "Office"
    ownerId: string                 # userId
    address: string
    geofence: {
      latitude: number
      longitude: number
      radiusMeters: number          # default 200
      enabled: boolean
      mode: "auto" | "prompt"       # auto-arm or ask first
      dwellSeconds: number          # default 120 (2 min)
    }
    members: [                      # family members
      { userId: string, role: "owner" | "member" }
    ]

panels/
  {panelId}/
    siteId: string
    name: string                    # "Main Panel"
    model: string                   # "mi64", "mi8", etc.
    connected: boolean
    partitions: [
      {
        id: number                  # 1-8
        name: string                # "House", "Perimeter"
        state: "armed" | "disarmed" | "home_arm" | "sleep_arm"
        autoArmOnLeave: boolean     # geofence: arm this partition?
        autoDisarmOnArrive: boolean
      }
    ]
    zones: [
      {
        id: number
        name: string                # "Front Door", "Kitchen PIR"
        type: "entry_exit" | "instant" | "24hr" | "fire"
        partitionId: number
        state: "closed" | "open" | "bypassed" | "tamper"
      }
    ]
    outputs: [
      {
        id: number
        name: string                # "Gate", "Garage", "Garden Lights"
        type: "momentary" | "toggle"  # gate = momentary, light = toggle
        state: "on" | "off"
      }
    ]

events/
  {eventId}/
    panelId: string
    siteId: string
    timestamp: timestamp
    type: "arm" | "disarm" | "alarm" | "panic" | "zone_open" |
          "zone_close" | "output_toggle" | "geofence_enter" |
          "geofence_exit" | "geofence_arm" | "geofence_disarm"
    source: "app" | "keypad" | "geofence" | "system"
    userId: string | null
    details: string                 # "Front Door opened", "Perimeter armed"
    partitionId: number | null

presence/
  {siteId}/
    members: {
      {userId}: {
        inside: boolean
        lastUpdate: timestamp
        lastLatitude: number
        lastLongitude: number
      }
    }
```

---

## Screens & Features

### 1. Authentication

**Screens**: Login, Register, Forgot Password

Firebase Auth with email/password. Keep it simple - no social login needed for a demo.

```dart
// Example: Auth service structure
// This is PROVIDED for you - auth is plumbing, not the learning goal

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserCredential> signIn(String email, String password) {
    return _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<UserCredential> register(String email, String password) {
    return _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() => _auth.signOut();
}
```

### 2. Dashboard (Home Screen)

The main screen after login. Shows:
- Site name and connection status
- Partition cards with current state and arm/disarm buttons
- Quick-access output controls (gate, garage, lights)
- Geofence status indicator ("Home" / "Away")
- Recent events (last 5)

**Layout reference** (what the real miAlarm roughly looks like):
```
┌─────────────────────────────┐
│  🏠 Home          ● Online  │
│─────────────────────────────│
│                             │
│  ┌─────────────────────┐   │
│  │ House        ARMED 🟢│   │
│  │ [Disarm] [Home] [Sleep]│ │
│  └─────────────────────┘   │
│                             │
│  ┌─────────────────────┐   │
│  │ Perimeter   DISARMED 🔴│ │
│  │ [Arm]   [Home]  [Sleep]│ │
│  └─────────────────────┘   │
│                             │
│  ── Quick Controls ──       │
│  [🚗 Gate] [🏠 Garage] [💡]│
│                             │
│  ── Recent Activity ──      │
│  10:30 Front Door opened    │
│  10:28 House disarmed (App) │
│  08:15 Perimeter armed (Geo)│
│─────────────────────────────│
│  🏠    📋    ⚙️    📍       │
│ Home  Events Settings Geo   │
└─────────────────────────────┘
```

### 3. Panel Control

**Arm/Disarm operations with confirmation:**

```dart
// Example: How a partition state change flows through the app
// This demonstrates the Riverpod pattern you'll use throughout

// --- provider (provided for you) ---

@riverpod
Stream<Panel> panelStream(PanelStreamRef ref, String panelId) {
  return FirebaseFirestore.instance
      .collection('panels')
      .doc(panelId)
      .snapshots()
      .map((snap) => Panel.fromFirestore(snap));
}

// --- the arm action (provided for you) ---

Future<void> armPartition(String panelId, int partitionId, String state) async {
  final panelRef = FirebaseFirestore.instance.collection('panels').doc(panelId);

  await FirebaseFirestore.instance.runTransaction((txn) async {
    final snap = await txn.get(panelRef);
    final panel = Panel.fromFirestore(snap);

    // Check no zones are open in this partition
    final openZones = panel.zones
        .where((z) => z.partitionId == partitionId && z.state == 'open')
        .toList();

    if (openZones.isNotEmpty) {
      throw Exception(
        'Cannot arm: ${openZones.map((z) => z.name).join(", ")} still open'
      );
    }

    // Update partition state
    final partitions = panel.partitions.map((p) {
      if (p.id == partitionId) return p.copyWith(state: state);
      return p;
    }).toList();

    txn.update(panelRef, {
      'partitions': partitions.map((p) => p.toMap()).toList(),
    });
  });

  // Log the event
  await FirebaseFirestore.instance.collection('events').add({
    'panelId': panelId,
    'timestamp': FieldValue.serverTimestamp(),
    'type': 'arm',
    'source': 'app',
    'details': 'Partition $partitionId set to $state',
    'partitionId': partitionId,
  });
}
```

### 4. Zone Management

View all zones, their states, and bypass individual zones.

```
┌─────────────────────────────┐
│  Zones              Filter ▼│
│─────────────────────────────│
│  HOUSE (Partition 1)        │
│  ┌─────────────────────┐   │
│  │ Front Door    CLOSED 🟢│  │
│  │ Kitchen PIR   CLOSED 🟢│  │
│  │ Bedroom PIR   BYPASS 🟡│  │
│  └─────────────────────┘   │
│                             │
│  PERIMETER (Partition 2)    │
│  ┌─────────────────────┐   │
│  │ Gate Beam     CLOSED 🟢│  │
│  │ Garden PIR    OPEN   🔴│  │
│  │ Driveway Beam CLOSED 🟢│  │
│  └─────────────────────┘   │
└─────────────────────────────┘
```

### 5. Event History

Full scrollable timeline of all events with filtering.

```dart
// Example: Event list with real-time Firestore stream
// Note the pagination pattern - important for production apps

@riverpod
Stream<List<PanelEvent>> eventStream(
  EventStreamRef ref,
  String panelId, {
  int limit = 50,
}) {
  return FirebaseFirestore.instance
      .collection('events')
      .where('panelId', isEqualTo: panelId)
      .orderBy('timestamp', descending: true)
      .limit(limit)
      .snapshots()
      .map((snap) =>
          snap.docs.map((d) => PanelEvent.fromFirestore(d)).toList());
}
```

### 6. Geofence Configuration Screen

This is THE differentiator feature. Screen where users:
- Set geofence center (map with draggable pin, or use current location)
- Adjust radius (slider, 100m - 500m)
- Choose mode: auto vs. prompt
- Select which partitions to auto-arm/disarm
- See family member presence status
- Set dwell time

```
┌─────────────────────────────┐
│  ← Geofence Settings        │
│─────────────────────────────│
│                             │
│  ┌─────────────────────┐   │
│  │     [MAP VIEW]       │   │
│  │    with radius       │   │
│  │    circle overlay    │   │
│  └─────────────────────┘   │
│                             │
│  Radius: ====●======= 200m │
│                             │
│  When I leave:              │
│  ☑ Arm "House"              │
│  ☑ Arm "Perimeter"          │
│                             │
│  When I arrive:             │
│  ☑ Disarm "House"           │
│  ☐ Disarm "Perimeter"       │
│                             │
│  Mode: [Auto ▼]             │
│  Dwell time: [2 min ▼]      │
│                             │
│  ── Who's Home ──           │
│  🟢 Justin (Home)           │
│  🔴 Sarah (Away)            │
│                             │
│  [Save Settings]            │
└─────────────────────────────┘
```

### 7. Settings

- Profile management
- Notification preferences
- Panel info
- About/version

---

## Geofencing - Detailed Design

### Client-Side Location Tracking

```dart
// The geofence monitoring service
// This runs as a background isolate on the device

import 'package:geolocator/geolocator.dart';

class GeofenceService {
  StreamSubscription<Position>? _positionStream;
  bool _isInsideGeofence = true;
  DateTime? _exitTime;

  /// Start monitoring. Call once after login.
  Future<void> startMonitoring(Site site) async {
    // Check permissions
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    // Background location settings
    // On Android, this requires a foreground service notification
    const locationSettings = AndroidSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 50, // only update every 50m of movement
      intervalDuration: Duration(seconds: 30),
      foregroundNotificationConfig: ForegroundNotificationConfig(
        notificationText: 'miAlarm is monitoring your location',
        notificationTitle: 'Geofence Active',
        enableWakeLock: true,
      ),
    );

    _positionStream = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen((position) {
      _evaluatePosition(position, site);
    });
  }

  void _evaluatePosition(Position position, Site site) {
    final distance = Geolocator.distanceBetween(
      position.latitude,
      position.longitude,
      site.geofence.latitude,
      site.geofence.longitude,
    );

    final wasInside = _isInsideGeofence;
    final isNowInside = distance <= site.geofence.radiusMeters;

    if (wasInside && !isNowInside) {
      // Just crossed out - start dwell timer
      _exitTime = DateTime.now();
    } else if (!wasInside && isNowInside) {
      // Came back in - cancel dwell timer
      _exitTime = null;
      _isInsideGeofence = true;
      _onEnterGeofence(site);
    }

    // Check if dwell time exceeded (confirmed departure)
    if (_exitTime != null) {
      final dwellElapsed = DateTime.now().difference(_exitTime!);
      if (dwellElapsed.inSeconds >= site.geofence.dwellSeconds) {
        _isInsideGeofence = false;
        _exitTime = null;
        _onExitGeofence(site);
      }
    }
  }

  Future<void> _onExitGeofence(Site site) async {
    // Update presence in Firestore
    await _updatePresence(site.id, inside: false);

    // Cloud Function evaluates: is anyone still home?
    // If not, it triggers the arm command (or sends a prompt notification)
  }

  Future<void> _onEnterGeofence(Site site) async {
    await _updatePresence(site.id, inside: true);
    // Cloud Function evaluates: should we disarm?
  }

  Future<void> _updatePresence(String siteId, {required bool inside}) async {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    await FirebaseFirestore.instance
        .collection('presence')
        .doc(siteId)
        .set({
      'members.$userId': {
        'inside': inside,
        'lastUpdate': FieldValue.serverTimestamp(),
      },
    }, SetOptions(merge: true));
  }

  void stopMonitoring() {
    _positionStream?.cancel();
  }
}
```

### Server-Side Evaluation (Cloud Function)

```javascript
// Cloud Function: triggered when presence document changes
// This is the "brain" that decides whether to arm/disarm

const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

exports.evaluateGeofence = functions.firestore
  .document('presence/{siteId}')
  .onWrite(async (change, context) => {
    const siteId = context.params.siteId;
    const presenceData = change.after.data();

    // Get site config
    const siteSnap = await admin.firestore()
      .collection('sites').doc(siteId).get();
    const site = siteSnap.data();

    if (!site.geofence.enabled) return;

    const members = presenceData.members;
    const anyoneHome = Object.values(members).some(m => m.inside === true);

    // Get panel for this site
    const panelSnap = await admin.firestore()
      .collection('panels')
      .where('siteId', '==', siteId)
      .limit(1)
      .get();

    if (panelSnap.empty) return;
    const panelRef = panelSnap.docs[0].ref;
    const panel = panelSnap.docs[0].data();

    if (!anyoneHome) {
      // Everyone left - arm configured partitions
      await armPartitions(panelRef, panel, site, 'leave');
    } else {
      // Someone arrived - check if we should disarm
      // Find who just arrived (inside === true with most recent lastUpdate)
      const justArrived = Object.entries(members)
        .filter(([_, m]) => m.inside === true)
        .sort((a, b) => b[1].lastUpdate - a[1].lastUpdate)[0];

      if (justArrived) {
        await disarmPartitions(panelRef, panel, site, 'arrive');
      }
    }
  });

async function armPartitions(panelRef, panel, site, trigger) {
  const updatedPartitions = panel.partitions.map(p => {
    if (p.autoArmOnLeave && p.state === 'disarmed') {
      return { ...p, state: 'armed' };
    }
    return p;
  });

  if (site.geofence.mode === 'auto') {
    // Auto-arm without asking
    await panelRef.update({ partitions: updatedPartitions });
    await logEvent(panel, 'geofence_arm', 'Auto-armed: everyone left');
  } else {
    // Send push notification asking user to confirm
    await sendPromptNotification(
      site,
      'Everyone has left home',
      'Arm the alarm?',
      { action: 'arm', siteId: site.id }
    );
  }
}

async function disarmPartitions(panelRef, panel, site, trigger) {
  // Disarm is ALWAYS prompt mode for security
  // You never silently disarm - that would be a security risk
  await sendPromptNotification(
    site,
    'Welcome home!',
    'Disarm the alarm?',
    { action: 'disarm', siteId: site.id }
  );
}
```

---

## Project Structure

```
lib/
├── main.dart
├── app.dart                          # MaterialApp + GoRouter setup
├── firebase_options.dart             # Generated by FlutterFire CLI
│
├── models/                           # Data classes
│   ├── user_model.dart
│   ├── site.dart
│   ├── panel.dart                    # Panel, Partition, Zone, Output
│   ├── panel_event.dart
│   └── geofence_config.dart
│
├── services/                         # Firebase & platform interactions
│   ├── auth_service.dart             # PROVIDED
│   ├── firestore_service.dart        # PROVIDED
│   ├── geofence_service.dart         # PROVIDED (above)
│   ├── notification_service.dart     # 🔧 STUB - you build this
│   └── seed_service.dart             # PROVIDED - populates demo data
│
├── providers/                        # Riverpod providers
│   ├── auth_provider.dart            # PROVIDED
│   ├── panel_provider.dart           # 🔧 STUB - you build this
│   ├── event_provider.dart           # 🔧 STUB - you build this
│   └── geofence_provider.dart        # PROVIDED
│
├── screens/
│   ├── auth/
│   │   ├── login_screen.dart         # 🔧 STUB - you build this
│   │   └── register_screen.dart      # PROVIDED (similar to login)
│   │
│   ├── dashboard/
│   │   ├── dashboard_screen.dart     # 🔧 STUB - you build this
│   │   ├── partition_card.dart       # PROVIDED
│   │   └── output_button.dart        # 🔧 STUB - you build this
│   │
│   ├── zones/
│   │   └── zone_list_screen.dart     # 🔧 STUB - you build this
│   │
│   ├── events/
│   │   └── event_history_screen.dart # PROVIDED
│   │
│   ├── geofence/
│   │   └── geofence_screen.dart      # PROVIDED (complex, not learning goal)
│   │
│   └── settings/
│       └── settings_screen.dart      # 🔧 STUB - you build this
│
├── widgets/                          # Reusable components
│   ├── status_indicator.dart         # PROVIDED
│   ├── confirmation_dialog.dart      # 🔧 STUB - you build this
│   └── event_tile.dart               # PROVIDED
│
└── utils/
    ├── constants.dart                # PROVIDED
    └── theme.dart                    # PROVIDED
```

---

## What Gets PROVIDED vs. What YOU Build

### Provided (I build these - complex/boilerplate/not the learning goal)

| Component | Why provided |
|-----------|-------------|
| Auth service + provider | Auth is plumbing, not Flutter learning |
| Firestore service | Firebase CRUD is boilerplate |
| Geofence service | Complex native integration, better to study working code |
| Geofence screen | Map integration is fiddly, not core Flutter |
| Data models | Dart classes with fromFirestore/toMap - pattern, not challenge |
| Theme + constants | Design system, not learning |
| GoRouter setup | Routing config is reference material |
| Event history screen | Shows the ListView/Stream pattern you'll replicate |
| Partition card widget | Reference widget for how the others should work |
| Seed service | Populates Firestore with realistic demo data |
| Cloud Functions | Backend logic, not Flutter |

### Stubs (YOU build these - core Flutter learning)

Each stub will have:
- A skeleton file with the class/widget structure
- Detailed comments explaining what to implement
- References to the provided code that demonstrates the same pattern

---

## Your Tasks (5 exercises, ~3 hours total)

These are ordered to build your Flutter knowledge progressively. Each task teaches specific concepts you'd need to discuss in an interview.

---

### Task 1: Login Screen
**Concepts**: StatefulWidget, TextEditingController, Form validation, async/await
**Time**: ~30 min
**File**: `lib/screens/auth/login_screen.dart`

Build the login form with email and password fields. The auth service is provided — you just wire up the UI.

**Reference**: `register_screen.dart` is the same pattern with one extra field. Copy the structure, simplify.

**Acceptance criteria**:
- Email and password fields with validation
- "Sign In" button that shows a loading spinner during auth
- Error message displayed on failed login (SnackBar)
- Link to register page

---

### Task 2: Dashboard Screen
**Concepts**: ConsumerWidget (Riverpod), StreamProvider, layout composition
**Time**: ~45 min
**File**: `lib/screens/dashboard/dashboard_screen.dart`

Compose the provided PartitionCards, your OutputButtons (Task 3), and recent events into the main screen.

**Reference**: `event_history_screen.dart` shows StreamBuilder + FutureBuilder pattern with Firestore.

**Acceptance criteria**:
- Shows site name and connection status
- Renders a PartitionCard for each partition
- Shows output control buttons
- Shows last 5 events at the bottom

---

### Task 3: Output Button Widget
**Concepts**: Reusable widgets, callbacks, state feedback
**Time**: ~30 min
**File**: `lib/screens/dashboard/output_button.dart`

A button for controlling outputs (gate, garage, lights). Toggle outputs stay on/off. Momentary outputs show a brief active state.

**Reference**: `partition_card.dart` follows the same data + callback pattern.

**Acceptance criteria**:
- Appropriate icon per output type (gate, garage, light, generic)
- Tap triggers the output via callback
- Shows on/off state for toggle outputs
- Loading indicator during action

---

### Task 4: Panel Provider (Riverpod)
**Concepts**: StreamProvider, Provider.family, derived state
**Time**: ~30 min
**File**: `lib/providers/panel_provider.dart`

Create three Riverpod providers that expose panel state to the UI.

**Reference**: `auth_provider.dart` and `geofence_provider.dart` show the exact patterns.

**Providers to implement**:
1. `panelStreamProvider` — stream a panel document by ID
2. `panelEventsProvider` — stream events for a panel (ordered, limited)
3. `hasOpenZonesProvider` — derived: any open zones in a partition?

---

### Task 5: Zone List Screen + Confirmation Dialog
**Concepts**: ListView.builder, grouping data, showDialog
**Time**: ~45 min
**File**: `lib/screens/zones/zone_list_screen.dart`

Zones grouped by partition, tap to bypass/unbypass with a confirmation dialog.

**Reference**: `event_history_screen.dart` for list pattern, stub includes dialog skeleton.

**Acceptance criteria**:
- Zones grouped under partition headers
- Colored indicator per zone state
- Tap → confirmation dialog → bypass/unbypass
- Bypassed zones shown in amber

---

## Build & Run

### Prerequisites
```bash
# Flutter SDK (3.x)
flutter --version

# Firebase CLI
firebase --version
npm install -g firebase-tools

# FlutterFire CLI
dart pub global activate flutterfire_cli
```

### Setup Steps
```bash
# 1. Create the Flutter project
flutter create --org za.co.finmon mialarm_clone
cd mialarm_clone

# 2. Add dependencies
flutter pub add firebase_core firebase_auth cloud_firestore
flutter pub add firebase_messaging flutter_local_notifications
flutter pub add flutter_riverpod riverpod_annotation
flutter pub add go_router geolocator google_maps_flutter
flutter pub add freezed_annotation json_annotation
flutter pub add --dev freezed build_runner json_serializable
flutter pub add --dev riverpod_generator

# 3. Configure Firebase
flutterfire configure

# 4. Seed demo data (provided script)
dart run lib/services/seed_service.dart

# 5. Deploy Cloud Functions
cd functions && npm install && firebase deploy --only functions

# 6. Run
flutter run
```

### Demo Data (created by seed service)

The seed service creates a realistic demo environment:

- **Site**: "Home" at a configurable lat/long (your actual location)
- **Panel**: "mi64" with 2 partitions (House, Perimeter)
- **8 Zones**: Front Door, Kitchen PIR, Bedroom PIR, Bathroom PIR (House partition); Gate Beam, Garden PIR, Driveway Beam, Back Wall (Perimeter)
- **3 Outputs**: Gate (momentary), Garage (momentary), Garden Lights (toggle)
- **50 sample events**: Mix of arm/disarm/zone events over the past week
- **Geofence**: 200m radius around your location, prompt mode, 2 min dwell

---

## Interview Talking Points

After building this, you should be able to discuss:

1. **"Why Riverpod over Provider or BLoC?"** - You chose it, you used it, you can explain the tradeoffs.

2. **"How does Flutter handle background location?"** - Foreground service on Android, significant location change on iOS, battery implications.

3. **"How would you handle the multi-user geofence problem?"** - Server-side evaluation via Cloud Functions. Client reports presence, server decides action.

4. **"What's the difference between StatelessWidget and StatefulWidget?"** - You built both. StatefulWidget for forms with controllers, ConsumerWidget (Riverpod) for reactive data.

5. **"How does Firestore real-time sync work in Flutter?"** - StreamProvider wrapping snapshots(). UI rebuilds automatically. You implemented this in panel_provider.

6. **"Why not auto-disarm?"** - Security principle: lowering security should always require human confirmation. Auto-arm (raising security) is safe to automate.

7. **"How would you plug this into the real Finmon API?"** - Replace FirestoreService with an HTTP client. The provider layer stays the same. This is the benefit of the service abstraction.

---

## Success Criteria

The app is "done" when:
- [ ] You can register and login
- [ ] Dashboard shows real-time panel state from Firestore
- [ ] You can arm/disarm partitions with confirmation
- [ ] You can toggle outputs (gate, lights)
- [ ] You can view and bypass zones
- [ ] Event history shows chronological log
- [ ] Geofence config screen works (map, radius, partition selection)
- [ ] Leaving the geofence triggers arm prompt notification
- [ ] Arriving triggers disarm prompt notification
- [ ] Multi-user presence is tracked (even if tested with one user)
- [ ] You can explain every line you wrote in an interview
