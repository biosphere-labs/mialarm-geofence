import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/site.dart';
import '../services/firestore_service.dart';
import '../services/geofence_service.dart';
import '../utils/constants.dart';
import 'auth_provider.dart';

/// Provides the FirestoreService instance.
final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService();
});

/// Provides the GeofenceService instance.
final geofenceServiceProvider = Provider<GeofenceService>((ref) {
  return GeofenceService();
});

/// Streams the user's primary site.
///
/// For this demo we assume one site per user. In production
/// you'd have a site selector.
final primarySiteProvider = StreamProvider<Site?>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return Stream.value(null);

  // Query for sites where this user is an owner
  return FirebaseFirestore.instance
      .collection(Collections.sites)
      .where('ownerId', isEqualTo: userId)
      .limit(1)
      .snapshots()
      .map((snap) {
    if (snap.docs.isEmpty) return null;
    return Site.fromFirestore(snap.docs.first);
  });
});

/// Streams the presence data for a site.
///
/// Returns a map of userId → {inside: bool, lastUpdate: Timestamp}
final presenceProvider =
    StreamProvider.family<Map<String, dynamic>, String>((ref, siteId) {
  return FirebaseFirestore.instance
      .collection(Collections.presence)
      .doc(siteId)
      .snapshots()
      .map((snap) {
    final data = snap.data();
    if (data == null) return {};
    return data['members'] as Map<String, dynamic>? ?? {};
  });
});
