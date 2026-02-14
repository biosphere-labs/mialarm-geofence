import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/panel.dart';
import '../models/panel_event.dart';
import '../models/site.dart';
import '../utils/constants.dart';

/// Centralized Firestore operations for panels, sites, and events.
///
/// Each method is a single Firestore operation. The providers layer
/// (Riverpod) decides when to call these and how to expose the data
/// to the UI.
class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── Sites ──

  /// Stream a single site document.
  Stream<Site> streamSite(String siteId) {
    return _db
        .collection(Collections.sites)
        .doc(siteId)
        .snapshots()
        .map((snap) => Site.fromFirestore(snap));
  }

  /// Get sites owned by or shared with a user.
  Stream<List<Site>> streamUserSites(String userId) {
    return _db
        .collection(Collections.sites)
        .where('members', arrayContains: {'userId': userId, 'role': 'owner'})
        .snapshots()
        .map((snap) => snap.docs.map((d) => Site.fromFirestore(d)).toList());
  }

  /// Update geofence config for a site.
  Future<void> updateGeofence(String siteId, GeofenceConfig config) {
    return _db
        .collection(Collections.sites)
        .doc(siteId)
        .update({'geofence': config.toMap()});
  }

  // ── Panels ──

  /// Stream a single panel document (real-time updates).
  Stream<Panel> streamPanel(String panelId) {
    return _db
        .collection(Collections.panels)
        .doc(panelId)
        .snapshots()
        .map((snap) => Panel.fromFirestore(snap));
  }

  /// Get the panel for a given site.
  Future<Panel?> getPanelForSite(String siteId) async {
    final snap = await _db
        .collection(Collections.panels)
        .where('siteId', isEqualTo: siteId)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return Panel.fromFirestore(snap.docs.first);
  }

  /// Arm or disarm a partition.
  Future<void> setPartitionState(
    String panelId,
    int partitionId,
    String newState,
    String userId,
  ) async {
    final panelRef = _db.collection(Collections.panels).doc(panelId);
    final snap = await panelRef.get();
    final panel = Panel.fromFirestore(snap);

    final updatedPartitions = panel.partitions.map((p) {
      if (p.id == partitionId) return p.copyWith(state: newState);
      return p;
    }).toList();

    await panelRef.update({
      'partitions': updatedPartitions.map((p) => p.toMap()).toList(),
    });

    await _logEvent(
      panelId: panelId,
      type: newState == ArmState.disarmed ? EventType.disarm : EventType.arm,
      source: EventSource.app,
      userId: userId,
      details:
          'Partition $partitionId ${newState == ArmState.disarmed ? "disarmed" : "set to $newState"}',
      partitionId: partitionId,
    );
  }

  /// Toggle or pulse an output.
  Future<void> triggerOutput(
    String panelId,
    int outputId,
    String userId,
  ) async {
    final panelRef = _db.collection(Collections.panels).doc(panelId);
    final snap = await panelRef.get();
    final panel = Panel.fromFirestore(snap);

    final output = panel.outputs.firstWhere((o) => o.id == outputId);

    if (output.isMomentary) {
      // Momentary: set to "on", then back to "off" after 2 seconds
      final updatedOn = panel.outputs.map((o) {
        if (o.id == outputId) return o.copyWith(state: 'on');
        return o;
      }).toList();

      await panelRef.update({
        'outputs': updatedOn.map((o) => o.toMap()).toList(),
      });

      // Reset after delay (in production this would be a Cloud Function)
      await Future.delayed(const Duration(seconds: 2));

      final updatedOff = panel.outputs.map((o) {
        if (o.id == outputId) return o.copyWith(state: 'off');
        return o;
      }).toList();

      await panelRef.update({
        'outputs': updatedOff.map((o) => o.toMap()).toList(),
      });
    } else {
      // Toggle: flip the state
      final newState = output.isOn ? 'off' : 'on';
      final updated = panel.outputs.map((o) {
        if (o.id == outputId) return o.copyWith(state: newState);
        return o;
      }).toList();

      await panelRef.update({
        'outputs': updated.map((o) => o.toMap()).toList(),
      });
    }

    await _logEvent(
      panelId: panelId,
      type: EventType.outputToggle,
      source: EventSource.app,
      userId: userId,
      details: '${output.name} triggered',
    );
  }

  /// Bypass or unbypass a zone.
  Future<void> setZoneBypass(
    String panelId,
    int zoneId,
    bool bypass,
    String userId,
  ) async {
    final panelRef = _db.collection(Collections.panels).doc(panelId);
    final snap = await panelRef.get();
    final panel = Panel.fromFirestore(snap);

    final updated = panel.zones.map((z) {
      if (z.id == zoneId) {
        return z.copyWith(state: bypass ? ZoneState.bypassed : ZoneState.closed);
      }
      return z;
    }).toList();

    await panelRef.update({
      'zones': updated.map((z) => z.toMap()).toList(),
    });

    final zone = panel.zones.firstWhere((z) => z.id == zoneId);
    await _logEvent(
      panelId: panelId,
      type: bypass ? EventType.zoneOpen : EventType.zoneClose,
      source: EventSource.app,
      userId: userId,
      details: '${zone.name} ${bypass ? "bypassed" : "unbypass"}',
    );
  }

  // ── Events ──

  /// Stream events for a panel, ordered by most recent first.
  Stream<List<PanelEvent>> streamEvents(String panelId, {int limit = 50}) {
    return _db
        .collection(Collections.events)
        .where('panelId', isEqualTo: panelId)
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => PanelEvent.fromFirestore(d)).toList());
  }

  /// Log an event to the events collection.
  Future<void> _logEvent({
    required String panelId,
    required String type,
    required String source,
    String? userId,
    required String details,
    int? partitionId,
    String siteId = '',
  }) {
    return _db.collection(Collections.events).add({
      'panelId': panelId,
      'siteId': siteId,
      'timestamp': FieldValue.serverTimestamp(),
      'type': type,
      'source': source,
      'userId': userId,
      'details': details,
      'partitionId': partitionId,
    });
  }

  // ── Presence ──

  /// Update this user's presence for a site.
  Future<void> updatePresence(
    String siteId,
    String userId, {
    required bool inside,
    double? latitude,
    double? longitude,
  }) {
    return _db.collection(Collections.presence).doc(siteId).set({
      'members.$userId': {
        'inside': inside,
        'lastUpdate': FieldValue.serverTimestamp(),
        if (latitude != null) 'lastLatitude': latitude,
        if (longitude != null) 'lastLongitude': longitude,
      },
    }, SetOptions(merge: true));
  }
}
