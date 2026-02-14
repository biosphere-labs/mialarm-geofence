/// Firestore collection names.
class Collections {
  static const users = 'users';
  static const sites = 'sites';
  static const panels = 'panels';
  static const events = 'events';
  static const presence = 'presence';
}

/// Partition arm states.
class ArmState {
  static const armed = 'armed';
  static const disarmed = 'disarmed';
  static const homeArm = 'home_arm';
  static const sleepArm = 'sleep_arm';
}

/// Zone states.
class ZoneState {
  static const closed = 'closed';
  static const open = 'open';
  static const bypassed = 'bypassed';
  static const tamper = 'tamper';
}

/// Event types.
class EventType {
  static const arm = 'arm';
  static const disarm = 'disarm';
  static const alarm = 'alarm';
  static const panic = 'panic';
  static const zoneOpen = 'zone_open';
  static const zoneClose = 'zone_close';
  static const outputToggle = 'output_toggle';
  static const geofenceEnter = 'geofence_enter';
  static const geofenceExit = 'geofence_exit';
  static const geofenceArm = 'geofence_arm';
  static const geofenceDisarm = 'geofence_disarm';
}

/// Event sources.
class EventSource {
  static const app = 'app';
  static const keypad = 'keypad';
  static const geofence = 'geofence';
  static const system = 'system';
}

/// Default geofence settings.
class GeofenceDefaults {
  static const radiusMeters = 200.0;
  static const dwellSeconds = 120;
  static const mode = 'prompt';
}
