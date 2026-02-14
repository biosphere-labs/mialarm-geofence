import 'package:cloud_firestore/cloud_firestore.dart';

class GeofenceConfig {
  final double latitude;
  final double longitude;
  final double radiusMeters;
  final bool enabled;
  final String mode; // "auto" | "prompt"
  final int dwellSeconds;

  const GeofenceConfig({
    required this.latitude,
    required this.longitude,
    this.radiusMeters = 200,
    this.enabled = false,
    this.mode = 'prompt',
    this.dwellSeconds = 120,
  });

  factory GeofenceConfig.fromMap(Map<String, dynamic> map) {
    return GeofenceConfig(
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      radiusMeters: (map['radiusMeters'] as num?)?.toDouble() ?? 200,
      enabled: map['enabled'] as bool? ?? false,
      mode: map['mode'] as String? ?? 'prompt',
      dwellSeconds: map['dwellSeconds'] as int? ?? 120,
    );
  }

  Map<String, dynamic> toMap() => {
        'latitude': latitude,
        'longitude': longitude,
        'radiusMeters': radiusMeters,
        'enabled': enabled,
        'mode': mode,
        'dwellSeconds': dwellSeconds,
      };

  GeofenceConfig copyWith({
    double? latitude,
    double? longitude,
    double? radiusMeters,
    bool? enabled,
    String? mode,
    int? dwellSeconds,
  }) {
    return GeofenceConfig(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      radiusMeters: radiusMeters ?? this.radiusMeters,
      enabled: enabled ?? this.enabled,
      mode: mode ?? this.mode,
      dwellSeconds: dwellSeconds ?? this.dwellSeconds,
    );
  }
}

class SiteMember {
  final String userId;
  final String role; // "owner" | "member"

  const SiteMember({required this.userId, required this.role});

  factory SiteMember.fromMap(Map<String, dynamic> map) {
    return SiteMember(
      userId: map['userId'] as String,
      role: map['role'] as String? ?? 'member',
    );
  }

  Map<String, dynamic> toMap() => {'userId': userId, 'role': role};
}

class Site {
  final String id;
  final String name;
  final String ownerId;
  final String address;
  final GeofenceConfig geofence;
  final List<SiteMember> members;

  const Site({
    required this.id,
    required this.name,
    required this.ownerId,
    this.address = '',
    required this.geofence,
    this.members = const [],
  });

  factory Site.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Site(
      id: doc.id,
      name: data['name'] as String? ?? 'My Site',
      ownerId: data['ownerId'] as String? ?? '',
      address: data['address'] as String? ?? '',
      geofence: GeofenceConfig.fromMap(
        data['geofence'] as Map<String, dynamic>? ?? {},
      ),
      members: (data['members'] as List<dynamic>?)
              ?.map((m) => SiteMember.fromMap(m as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'ownerId': ownerId,
        'address': address,
        'geofence': geofence.toMap(),
        'members': members.map((m) => m.toMap()).toList(),
      };
}
