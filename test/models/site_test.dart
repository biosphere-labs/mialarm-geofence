import 'package:flutter_test/flutter_test.dart';
import 'package:mialarm_geofence/models/site.dart';

void main() {
  group('GeofenceConfig', () {
    test('creates with defaults', () {
      const config = GeofenceConfig(latitude: -26.2, longitude: 28.0);
      expect(config.radiusMeters, 200);
      expect(config.enabled, false);
      expect(config.mode, 'prompt');
      expect(config.dwellSeconds, 120);
    });

    test('fromMap with all fields', () {
      final config = GeofenceConfig.fromMap({
        'latitude': -26.2,
        'longitude': 28.0,
        'radiusMeters': 500,
        'enabled': true,
        'mode': 'auto',
        'dwellSeconds': 60,
      });
      expect(config.latitude, -26.2);
      expect(config.longitude, 28.0);
      expect(config.radiusMeters, 500);
      expect(config.enabled, true);
      expect(config.mode, 'auto');
      expect(config.dwellSeconds, 60);
    });

    test('fromMap with missing optional fields uses defaults', () {
      final config = GeofenceConfig.fromMap({
        'latitude': -26.2,
        'longitude': 28.0,
      });
      expect(config.radiusMeters, 200);
      expect(config.enabled, false);
      expect(config.mode, 'prompt');
      expect(config.dwellSeconds, 120);
    });

    test('fromMap handles int latitude/longitude', () {
      final config = GeofenceConfig.fromMap({
        'latitude': 10,
        'longitude': 20,
      });
      expect(config.latitude, 10.0);
      expect(config.longitude, 20.0);
    });

    test('toMap roundtrips correctly', () {
      const original = GeofenceConfig(
        latitude: -26.2,
        longitude: 28.0,
        radiusMeters: 300,
        enabled: true,
        mode: 'auto',
        dwellSeconds: 90,
      );
      final map = original.toMap();
      final restored = GeofenceConfig.fromMap(map);

      expect(restored.latitude, original.latitude);
      expect(restored.longitude, original.longitude);
      expect(restored.radiusMeters, original.radiusMeters);
      expect(restored.enabled, original.enabled);
      expect(restored.mode, original.mode);
      expect(restored.dwellSeconds, original.dwellSeconds);
    });

    test('copyWith overrides specific fields', () {
      const config = GeofenceConfig(
        latitude: -26.2,
        longitude: 28.0,
        enabled: false,
      );
      final updated = config.copyWith(enabled: true, radiusMeters: 500);

      expect(updated.enabled, true);
      expect(updated.radiusMeters, 500);
      expect(updated.latitude, -26.2); // unchanged
      expect(updated.longitude, 28.0); // unchanged
    });
  });

  group('SiteMember', () {
    test('creates from map', () {
      final member = SiteMember.fromMap({
        'userId': 'user123',
        'role': 'owner',
      });
      expect(member.userId, 'user123');
      expect(member.role, 'owner');
    });

    test('defaults role to member', () {
      final member = SiteMember.fromMap({'userId': 'user123'});
      expect(member.role, 'member');
    });

    test('toMap roundtrips', () {
      const member = SiteMember(userId: 'u1', role: 'owner');
      final restored = SiteMember.fromMap(member.toMap());
      expect(restored.userId, 'u1');
      expect(restored.role, 'owner');
    });
  });

  group('Site', () {
    test('toMap includes all fields', () {
      const site = Site(
        id: 's1',
        name: 'Home',
        ownerId: 'u1',
        address: '42 Test St',
        geofence: GeofenceConfig(latitude: -26.2, longitude: 28.0),
        members: [SiteMember(userId: 'u1', role: 'owner')],
      );
      final map = site.toMap();

      expect(map['name'], 'Home');
      expect(map['ownerId'], 'u1');
      expect(map['address'], '42 Test St');
      expect(map['geofence'], isA<Map>());
      expect((map['members'] as List).length, 1);
    });

    test('toMap does not include id (Firestore doc ID)', () {
      const site = Site(
        id: 's1',
        name: 'Home',
        ownerId: 'u1',
        geofence: GeofenceConfig(latitude: 0, longitude: 0),
      );
      expect(site.toMap().containsKey('id'), false);
    });
  });
}
