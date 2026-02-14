import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import '../models/site.dart';

/// Monitors device location and detects geofence entry/exit.
///
/// This service runs in the foreground with a persistent notification
/// (Android requirement for background location). It:
///
/// 1. Listens to position changes (every 50m of movement)
/// 2. Calculates distance to the geofence center
/// 3. Applies a dwell timer to prevent GPS jitter false triggers
/// 4. Updates presence in Firestore when confirmed entry/exit occurs
///
/// The Cloud Function (server-side) then evaluates whether to arm/disarm
/// based on ALL users' presence, not just this one.
class GeofenceService {
  final _db = FirebaseFirestore.instance;
  StreamSubscription<Position>? _positionStream;
  bool _isInsideGeofence = true;
  DateTime? _exitTime;

  /// Request location permissions. Must be called before startMonitoring.
  Future<bool> requestPermissions() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return false;
    }

    if (permission == LocationPermission.deniedForever) return false;

    return true;
  }

  /// Start monitoring geofence for the given site.
  ///
  /// Call once after login when the user has an active site with
  /// geofencing enabled. Stops any existing monitoring first.
  Future<void> startMonitoring(Site site) async {
    stopMonitoring();

    if (!site.geofence.enabled) return;

    final hasPermission = await requestPermissions();
    if (!hasPermission) return;

    // Determine initial position
    final currentPosition = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );

    final initialDistance = Geolocator.distanceBetween(
      currentPosition.latitude,
      currentPosition.longitude,
      site.geofence.latitude,
      site.geofence.longitude,
    );
    _isInsideGeofence = initialDistance <= site.geofence.radiusMeters;

    // Update initial presence
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      await _updatePresence(
        site.id,
        userId,
        inside: _isInsideGeofence,
        latitude: currentPosition.latitude,
        longitude: currentPosition.longitude,
      );
    }

    // Start continuous monitoring
    // distanceFilter: 50 = only wake up every 50 meters of movement
    // This is the key battery optimisation
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 50,
    );

    _positionStream = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen((position) {
      _evaluatePosition(position, site);
    });
  }

  /// Evaluate whether a position update crosses the geofence.
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
      // Just crossed out — start dwell timer
      _exitTime = DateTime.now();
    } else if (!wasInside && isNowInside) {
      // Came back inside — cancel any pending exit
      _exitTime = null;
      if (!_isInsideGeofence) {
        _isInsideGeofence = true;
        _onEnterGeofence(site, position);
      }
    }

    // Check if dwell time has been exceeded (confirmed departure)
    if (_exitTime != null && !isNowInside) {
      final dwellElapsed = DateTime.now().difference(_exitTime!);
      if (dwellElapsed.inSeconds >= site.geofence.dwellSeconds) {
        _isInsideGeofence = false;
        _exitTime = null;
        _onExitGeofence(site, position);
      }
    }
  }

  /// Called when user has confirmed exited the geofence.
  Future<void> _onExitGeofence(Site site, Position position) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    await _updatePresence(
      site.id,
      userId,
      inside: false,
      latitude: position.latitude,
      longitude: position.longitude,
    );

    // The Cloud Function watching 'presence/{siteId}' will now
    // evaluate whether everyone has left and trigger arm if needed.
  }

  /// Called when user has entered the geofence.
  Future<void> _onEnterGeofence(Site site, Position position) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    await _updatePresence(
      site.id,
      userId,
      inside: true,
      latitude: position.latitude,
      longitude: position.longitude,
    );
  }

  Future<void> _updatePresence(
    String siteId,
    String userId, {
    required bool inside,
    double? latitude,
    double? longitude,
  }) {
    return _db.collection('presence').doc(siteId).set({
      'members.$userId': {
        'inside': inside,
        'lastUpdate': FieldValue.serverTimestamp(),
        if (latitude != null) 'lastLatitude': latitude,
        if (longitude != null) 'lastLongitude': longitude,
      },
    }, SetOptions(merge: true));
  }

  /// Stop monitoring. Call on logout or when geofencing is disabled.
  void stopMonitoring() {
    _positionStream?.cancel();
    _positionStream = null;
    _exitTime = null;
  }
}
