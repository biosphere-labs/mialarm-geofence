# miAlarm Geofence Auto-Arm — Feature Brief

## What This Is

A functional Flutter clone of the **miAlarm** app with an added **geofencing auto-arm/disarm** feature — a capability that competitors like Ajax already offer but miAlarm currently lacks. Select sections were intentionally implemented by hand as a Flutter learning exercise.

## The App

This is a working mobile application backed by Firebase that simulates an alarm panel. It replicates miAlarm's core functionality:

- **Arm/Disarm partitions** (House, Perimeter) with Home Arm and Sleep Arm modes
- **Output control** — open/close gates and garage doors, toggle lights, geyser, pool pump
- **Zone management** — view zone status, bypass individual zones
- **Push notifications** — alarm triggers, zone events, geofence prompts
- **Event history** — full chronological log of all panel activity
- **Real-time sync** — all state updates are live via Firestore streams

## How It Works Without Hardware

The app connects to a Firebase backend that simulates panel state. The architecture is identical to what a production integration would look like — the only difference is the last hop. Instead of `Firestore → Cloud Function → real monitoring API → Physical Panel`, the Cloud Function updates simulated state in Firestore directly. Swapping in the real real monitoring API would be a single service layer change.

```
Flutter App → Firebase Auth + Firestore → Cloud Functions → Simulated Panel State
                                                ↓
                                          Push Notifications (FCM)
                                          Event Logging
                                          Geofence Evaluation
```

Everything else is real: authentication, database writes, real-time streams, push notifications, GPS location tracking, and background geofence monitoring.

## The Feature: Geofencing Auto-Arm/Disarm

### The Problem

Every alarm user experiences the same daily friction:
- **Leaving home**: Rush out, forget to arm. Half the time you're in the car wondering if you armed it.
- **Arriving home**: Walk to the door, alarm beeping, fumble to disarm before triggering a false alarm. In South Africa, security companies charge for unnecessary callouts.

### The Solution

Draw a virtual boundary around your home. The app uses GPS to detect when you cross it:

- **Leave the geofence** → Auto-arm the alarm (or prompt: "You've left home. Arm?")
- **Enter the geofence** → Prompt to disarm before you reach the front door

### Multi-User Intelligence

The system tracks all family members' presence. It only arms when the **last person** leaves and prompts disarm when the **first person** arrives. This prevents the classic problem of one person leaving and arming while the rest of the family is still home.

### Safety-First Design

- **Arming** (increasing security) can be fully automatic
- **Disarming** (lowering security) always requires human confirmation — never silent
- **Dwell time** prevents false triggers from GPS jitter (configurable, default 2 minutes)
- Per-partition control: auto-arm the perimeter but not the interior, for example

## Why This Feature Matters

### Competitors Already Have It

| Company | App | Geofencing |
|---------|-----|-----------|
| **Ajax** | Ajax PRO | Yes — geofence reminders for arming/disarming |
| **IDS** | hyyp+ | Not documented in official sources |
| **miAlarm** | miAlarm | **No** — location used only for emergency GPS sharing (per official app documentation) |

Notably, miAlarm already requests location permission from the user — but only for emergency GPS sharing during alarm events. The official documentation explicitly states "No background location tracking". This means the infrastructure for location access exists, but it's not used for automation. Geofence auto-arm would be a natural opt-in extension: users who want it can enable location-based arming, while others keep the existing manual workflow. Ajax Systems' app already includes a documented geofence function that sends reminders when leaving/entering a user-defined area.

### South African Context

South Africa has one of the highest private security adoption rates in the world. Armed response is a multi-billion rand industry. False alarms from late disarms are a real operational cost — security companies charge R500+ per unnecessary callout. Automated arming eliminates forgotten-to-arm scenarios entirely.

### Business Value

- **Reduced false alarms** → Lower operational cost for monitoring partners
- **Increased app engagement** → Users interact with the app more when it's proactive
- **Competitive parity** → Matches Ajax's geofencing capability
- **Upsell opportunity** → Geofencing could be a premium subscription feature
- **Differentiation** — Multi-user presence tracking (arm when *last* person leaves) is more sophisticated than most competitors' single-user implementations

## Technical Highlights

- **Flutter 3.x** with Riverpod state management
- **Firebase** backend (Auth, Firestore, Cloud Functions, FCM)
- **Background location** monitoring with battery-efficient distance filtering
- **Real-time sync** — panel state updates propagate to all connected devices instantly
- **Server-side geofence evaluation** — presence data flows to Cloud Functions which make arm/disarm decisions, preventing race conditions in multi-user scenarios
