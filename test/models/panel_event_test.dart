import 'package:flutter_test/flutter_test.dart';
import 'package:mialarm_geofence/models/panel_event.dart';

void main() {
  group('PanelEvent', () {
    test('iconName maps event types correctly', () {
      PanelEvent make(String type) => PanelEvent(
            id: 'e1',
            panelId: 'p1',
            timestamp: DateTime(2024, 1, 1),
            type: type,
            details: 'test',
          );

      expect(make('arm').iconName, 'lock');
      expect(make('disarm').iconName, 'lock_open');
      expect(make('alarm').iconName, 'warning');
      expect(make('panic').iconName, 'emergency');
      expect(make('zone_open').iconName, 'sensor_door');
      expect(make('zone_close').iconName, 'door_front');
      expect(make('output_toggle').iconName, 'toggle_on');
      expect(make('geofence_enter').iconName, 'location_on');
      expect(make('geofence_exit').iconName, 'location_off');
      expect(make('geofence_arm').iconName, 'my_location');
      expect(make('geofence_disarm').iconName, 'location_searching');
      expect(make('unknown').iconName, 'info');
    });

    test('isAlert for alarm and panic events', () {
      PanelEvent make(String type) => PanelEvent(
            id: 'e1',
            panelId: 'p1',
            timestamp: DateTime(2024, 1, 1),
            type: type,
            details: 'test',
          );

      expect(make('alarm').isAlert, true);
      expect(make('panic').isAlert, true);
      expect(make('arm').isAlert, false);
      expect(make('disarm').isAlert, false);
      expect(make('zone_open').isAlert, false);
    });

    test('optional fields have correct defaults', () {
      final event = PanelEvent(
        id: 'e1',
        panelId: 'p1',
        timestamp: DateTime(2024, 1, 1),
        type: 'arm',
        details: 'Armed',
      );
      expect(event.siteId, '');
      expect(event.source, 'system');
      expect(event.userId, isNull);
      expect(event.partitionId, isNull);
    });

    test('toMap includes all fields', () {
      final event = PanelEvent(
        id: 'e1',
        panelId: 'p1',
        siteId: 's1',
        timestamp: DateTime(2024, 1, 15, 10, 30),
        type: 'arm',
        source: 'app',
        userId: 'u1',
        details: 'House armed',
        partitionId: 1,
      );
      final map = event.toMap();

      expect(map['panelId'], 'p1');
      expect(map['siteId'], 's1');
      expect(map['type'], 'arm');
      expect(map['source'], 'app');
      expect(map['userId'], 'u1');
      expect(map['details'], 'House armed');
      expect(map['partitionId'], 1);
      // timestamp is a Firestore Timestamp, not a DateTime
      expect(map['timestamp'], isNotNull);
      // id is not in map (Firestore doc ID)
      expect(map.containsKey('id'), false);
    });
  });
}
