import 'package:cloud_firestore/cloud_firestore.dart';

class PanelEvent {
  final String id;
  final String panelId;
  final String siteId;
  final DateTime timestamp;
  final String type;
  final String source; // "app" | "keypad" | "geofence" | "system"
  final String? userId;
  final String details;
  final int? partitionId;

  const PanelEvent({
    required this.id,
    required this.panelId,
    this.siteId = '',
    required this.timestamp,
    required this.type,
    this.source = 'system',
    this.userId,
    required this.details,
    this.partitionId,
  });

  /// Icon to show in the event list based on event type.
  String get iconName => switch (type) {
        'arm' => 'lock',
        'disarm' => 'lock_open',
        'alarm' => 'warning',
        'panic' => 'emergency',
        'zone_open' => 'sensor_door',
        'zone_close' => 'door_front',
        'output_toggle' => 'toggle_on',
        'geofence_enter' => 'location_on',
        'geofence_exit' => 'location_off',
        'geofence_arm' => 'my_location',
        'geofence_disarm' => 'location_searching',
        _ => 'info',
      };

  /// Whether this is a high-priority event (alarm, panic).
  bool get isAlert => type == 'alarm' || type == 'panic';

  factory PanelEvent.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PanelEvent(
      id: doc.id,
      panelId: data['panelId'] as String? ?? '',
      siteId: data['siteId'] as String? ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      type: data['type'] as String? ?? 'info',
      source: data['source'] as String? ?? 'system',
      userId: data['userId'] as String?,
      details: data['details'] as String? ?? '',
      partitionId: data['partitionId'] as int?,
    );
  }

  Map<String, dynamic> toMap() => {
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
