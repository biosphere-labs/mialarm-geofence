import 'package:flutter_test/flutter_test.dart';
import 'package:mialarm_geofence/utils/constants.dart';

void main() {
  group('Collections', () {
    test('has expected collection names', () {
      expect(Collections.users, 'users');
      expect(Collections.sites, 'sites');
      expect(Collections.panels, 'panels');
      expect(Collections.events, 'events');
      expect(Collections.presence, 'presence');
    });
  });

  group('ArmState', () {
    test('has expected states', () {
      expect(ArmState.armed, 'armed');
      expect(ArmState.disarmed, 'disarmed');
      expect(ArmState.homeArm, 'home_arm');
      expect(ArmState.sleepArm, 'sleep_arm');
    });
  });

  group('ZoneState', () {
    test('has expected states', () {
      expect(ZoneState.closed, 'closed');
      expect(ZoneState.open, 'open');
      expect(ZoneState.bypassed, 'bypassed');
      expect(ZoneState.tamper, 'tamper');
    });
  });

  group('EventType', () {
    test('has expected event types', () {
      expect(EventType.arm, 'arm');
      expect(EventType.disarm, 'disarm');
      expect(EventType.alarm, 'alarm');
      expect(EventType.panic, 'panic');
      expect(EventType.zoneOpen, 'zone_open');
      expect(EventType.zoneClose, 'zone_close');
      expect(EventType.outputToggle, 'output_toggle');
      expect(EventType.geofenceEnter, 'geofence_enter');
      expect(EventType.geofenceExit, 'geofence_exit');
      expect(EventType.geofenceArm, 'geofence_arm');
      expect(EventType.geofenceDisarm, 'geofence_disarm');
    });
  });

  group('EventSource', () {
    test('has expected sources', () {
      expect(EventSource.app, 'app');
      expect(EventSource.keypad, 'keypad');
      expect(EventSource.geofence, 'geofence');
      expect(EventSource.system, 'system');
    });
  });

  group('GeofenceDefaults', () {
    test('has expected defaults', () {
      expect(GeofenceDefaults.radiusMeters, 200.0);
      expect(GeofenceDefaults.dwellSeconds, 120);
      expect(GeofenceDefaults.mode, 'prompt');
    });
  });
}
