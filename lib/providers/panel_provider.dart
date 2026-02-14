import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/panel.dart';
import '../models/panel_event.dart';
import '../utils/constants.dart';

// ═══════════════════════════════════════════════════════════════════
// TASK 4: Panel Provider (Riverpod)                       ~30 min
// ═══════════════════════════════════════════════════════════════════
//
// WHAT YOU'LL LEARN:
//   - StreamProvider: wraps a Stream and makes it available to widgets
//   - Provider.family: parameterized providers (same provider, different args)
//   - Derived providers: computing new values from existing providers
//   - Auto-dispose: providers clean up when no widget is listening
//
// REFERENCE: Look at auth_provider.dart and geofence_provider.dart
//   to see how StreamProvider and Provider work.
//
// HOW RIVERPOD WORKS (quick mental model):
//   - A Provider is a container that holds a value
//   - StreamProvider holds a Stream (like Firestore snapshots)
//   - Widgets call ref.watch(provider) to subscribe to changes
//   - When the stream emits a new value, all watching widgets rebuild
//   - .family means "this provider takes a parameter" — like a function
//   - ref.watch() returns AsyncValue<T> which has .when(data/loading/error)
//
// THREE PROVIDERS TO IMPLEMENT:
//
// 1. panelStreamProvider — Stream a panel document by ID
// 2. panelEventsProvider — Stream events for a panel
// 3. hasOpenZonesProvider — Derived: check if partition has open zones
//
// ═══════════════════════════════════════════════════════════════════

// ─── Provider 1: Panel Stream ──────────────────────────────────
//
// Stream a single panel document from Firestore.
// Widgets use: ref.watch(panelStreamProvider(panelId))
//
// IMPLEMENT:
//   - Query: FirebaseFirestore.instance.collection('panels').doc(panelId)
//   - Convert: .snapshots().map((snap) => Panel.fromFirestore(snap))
//
// EXAMPLE from geofence_provider.dart (similar pattern):
//   final primarySiteProvider = StreamProvider<Site?>((ref) {
//     return FirebaseFirestore.instance
//         .collection('sites')
//         .where(...)
//         .snapshots()
//         .map((snap) => ...);
//   });

final panelStreamProvider =
    StreamProvider.family<Panel, String>((ref, panelId) {
  // TODO: Return a stream of the panel document
  // FirebaseFirestore.instance.collection(Collections.panels).doc(panelId)
  //   .snapshots()
  //   .map((snap) => Panel.fromFirestore(snap));
  throw UnimplementedError('Implement panelStreamProvider');
});

// ─── Provider 2: Panel Events ──────────────────────────────────
//
// Stream events for a panel, ordered by most recent.
// Widgets use: ref.watch(panelEventsProvider(panelId))
//
// IMPLEMENT:
//   - Query: collection('events').where('panelId' == panelId)
//   - Order: .orderBy('timestamp', descending: true)
//   - Limit: .limit(50)
//   - Convert: .snapshots().map(snap => snap.docs.map(PanelEvent.fromFirestore))

final panelEventsProvider =
    StreamProvider.family<List<PanelEvent>, String>((ref, panelId) {
  // TODO: Return a stream of events for this panel
  throw UnimplementedError('Implement panelEventsProvider');
});

// ─── Provider 3: Has Open Zones ────────────────────────────────
//
// Derived provider: reads from panelStreamProvider and checks if
// any zones in a given partition are in "open" state.
//
// This is a "computed" value — it doesn't fetch data itself, it
// derives from another provider. Think of it like a computed
// property in Vue or a selector in Redux.
//
// Widgets use: ref.watch(hasOpenZonesProvider((panelId, partitionId)))
//
// IMPLEMENT:
//   - Watch the panel stream
//   - Filter zones by partitionId
//   - Return true if any zone has state == 'open'
//
// HINT: Use a Record (panelId, partitionId) as the family parameter.
//   Dart Records are value types, so (a, b) == (a, b) is true.

final hasOpenZonesProvider =
    Provider.family<bool, (String panelId, int partitionId)>((ref, params) {
  final (panelId, partitionId) = params;

  // TODO: Watch panelStreamProvider(panelId)
  // If loading or error, return false
  // Otherwise, check panel.zones for open zones in this partition
  //
  // final panelAsync = ref.watch(panelStreamProvider(panelId));
  // return panelAsync.when(
  //   data: (panel) => panel.zones.any((z) => ...),
  //   loading: () => false,
  //   error: (_, __) => false,
  // );

  return false; // TODO: replace with real implementation
});
