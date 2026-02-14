import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/constants.dart';

/// Seeds Firestore with realistic demo data.
///
/// Run once after Firebase setup to populate the database with
/// a site, panel, zones, outputs, and sample events.
///
/// Usage from a temporary button or test:
///   await SeedService().seedDemoData(userId: currentUser.uid);
class SeedService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Seed everything for a given user.
  ///
  /// Set [latitude] and [longitude] to your actual location so
  /// geofencing works when you test it.
  Future<void> seedDemoData({
    required String userId,
    double latitude = -26.2041,  // Johannesburg default
    double longitude = 28.0473,
  }) async {
    // Clean existing demo data
    await _cleanExisting(userId);

    // Create site
    final siteRef = await _db.collection(Collections.sites).add({
      'name': 'Home',
      'ownerId': userId,
      'address': '42 Security Street, Sandton',
      'geofence': {
        'latitude': latitude,
        'longitude': longitude,
        'radiusMeters': 200,
        'enabled': true,
        'mode': 'prompt',
        'dwellSeconds': 120,
      },
      'members': [
        {'userId': userId, 'role': 'owner'},
      ],
    });

    // Create panel
    final panelRef = await _db.collection(Collections.panels).add({
      'siteId': siteRef.id,
      'name': 'mi64 Main Panel',
      'model': 'mi64',
      'connected': true,
      'partitions': [
        {
          'id': 1,
          'name': 'House',
          'state': 'disarmed',
          'autoArmOnLeave': true,
          'autoDisarmOnArrive': true,
        },
        {
          'id': 2,
          'name': 'Perimeter',
          'state': 'armed',
          'autoArmOnLeave': true,
          'autoDisarmOnArrive': false,
        },
      ],
      'zones': [
        // House zones (partition 1)
        {'id': 1, 'name': 'Front Door', 'type': 'entry_exit', 'partitionId': 1, 'state': 'closed'},
        {'id': 2, 'name': 'Kitchen PIR', 'type': 'instant', 'partitionId': 1, 'state': 'closed'},
        {'id': 3, 'name': 'Bedroom PIR', 'type': 'instant', 'partitionId': 1, 'state': 'closed'},
        {'id': 4, 'name': 'Bathroom PIR', 'type': 'instant', 'partitionId': 1, 'state': 'closed'},
        // Perimeter zones (partition 2)
        {'id': 5, 'name': 'Gate Beam', 'type': 'instant', 'partitionId': 2, 'state': 'closed'},
        {'id': 6, 'name': 'Garden PIR', 'type': 'instant', 'partitionId': 2, 'state': 'closed'},
        {'id': 7, 'name': 'Driveway Beam', 'type': 'entry_exit', 'partitionId': 2, 'state': 'closed'},
        {'id': 8, 'name': 'Back Wall', 'type': 'instant', 'partitionId': 2, 'state': 'closed'},
      ],
      'outputs': [
        {'id': 1, 'name': 'Gate', 'type': 'momentary', 'state': 'off'},
        {'id': 2, 'name': 'Garage', 'type': 'momentary', 'state': 'off'},
        {'id': 3, 'name': 'Garden Lights', 'type': 'toggle', 'state': 'off'},
      ],
    });

    // Create initial presence
    await _db.collection(Collections.presence).doc(siteRef.id).set({
      'members': {
        userId: {
          'inside': true,
          'lastUpdate': FieldValue.serverTimestamp(),
          'lastLatitude': latitude,
          'lastLongitude': longitude,
        },
      },
    });

    // Create sample events over the past week
    await _seedEvents(panelRef.id, siteRef.id, userId);
  }

  Future<void> _seedEvents(
    String panelId,
    String siteId,
    String userId,
  ) async {
    final now = DateTime.now();
    final batch = _db.batch();

    final sampleEvents = [
      // Today
      _event(panelId, siteId, now.subtract(const Duration(minutes: 30)),
          'disarm', 'app', userId, 'House disarmed', 1),
      _event(panelId, siteId, now.subtract(const Duration(minutes: 32)),
          'zone_open', 'system', null, 'Front Door opened', 1),
      _event(panelId, siteId, now.subtract(const Duration(hours: 2)),
          'arm', 'geofence', userId, 'Perimeter armed (geofence)', 2),
      _event(panelId, siteId, now.subtract(const Duration(hours: 2, minutes: 1)),
          'geofence_exit', 'system', userId, 'Justin left home', null),

      // Yesterday
      _event(panelId, siteId, now.subtract(const Duration(hours: 18)),
          'output_toggle', 'app', userId, 'Garden Lights turned off', null),
      _event(panelId, siteId, now.subtract(const Duration(hours: 20)),
          'output_toggle', 'app', userId, 'Garden Lights turned on', null),
      _event(panelId, siteId, now.subtract(const Duration(hours: 22)),
          'arm', 'app', userId, 'House armed', 1),
      _event(panelId, siteId, now.subtract(const Duration(hours: 22)),
          'arm', 'app', userId, 'Perimeter armed', 2),
      _event(panelId, siteId, now.subtract(const Duration(hours: 26)),
          'disarm', 'geofence', userId, 'House disarmed (geofence)', 1),
      _event(panelId, siteId, now.subtract(const Duration(hours: 26)),
          'geofence_enter', 'system', userId, 'Justin arrived home', null),

      // 2 days ago
      _event(panelId, siteId, now.subtract(const Duration(hours: 45)),
          'alarm', 'system', null, 'Garden PIR triggered', 2),
      _event(panelId, siteId, now.subtract(const Duration(hours: 45, minutes: 1)),
          'zone_open', 'system', null, 'Garden PIR opened', 2),
      _event(panelId, siteId, now.subtract(const Duration(hours: 50)),
          'arm', 'app', userId, 'Perimeter armed', 2),

      // 3 days ago
      _event(panelId, siteId, now.subtract(const Duration(hours: 72)),
          'output_toggle', 'app', userId, 'Gate triggered', null),
      _event(panelId, siteId, now.subtract(const Duration(hours: 75)),
          'disarm', 'app', userId, 'House disarmed', 1),
    ];

    for (final event in sampleEvents) {
      final ref = _db.collection(Collections.events).doc();
      batch.set(ref, event);
    }

    await batch.commit();
  }

  Map<String, dynamic> _event(
    String panelId,
    String siteId,
    DateTime timestamp,
    String type,
    String source,
    String? userId,
    String details,
    int? partitionId,
  ) {
    return {
      'panelId': panelId,
      'siteId': siteId,
      'timestamp': Timestamp.fromDate(timestamp),
      'type': type,
      'source': source,
      'userId': userId,
      'details': details,
      'partitionId': partitionId,
    };
  }

  Future<void> _cleanExisting(String userId) async {
    // Delete existing sites for this user
    final sites = await _db
        .collection(Collections.sites)
        .where('ownerId', isEqualTo: userId)
        .get();

    for (final site in sites.docs) {
      // Delete panels for this site
      final panels = await _db
          .collection(Collections.panels)
          .where('siteId', isEqualTo: site.id)
          .get();
      for (final panel in panels.docs) {
        // Delete events for this panel
        final events = await _db
            .collection(Collections.events)
            .where('panelId', isEqualTo: panel.id)
            .get();
        for (final event in events.docs) {
          await event.reference.delete();
        }
        await panel.reference.delete();
      }

      // Delete presence
      await _db.collection(Collections.presence).doc(site.id).delete();

      await site.reference.delete();
    }
  }
}
