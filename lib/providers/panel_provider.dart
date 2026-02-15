import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/panel.dart';
import '../models/panel_event.dart';
import '../utils/constants.dart';

final panelStreamProvider =
    StreamProvider.family<Panel, String>((ref, panelId) {
  return FirebaseFirestore.instance
      .collection(Collections.panels)
      .doc(panelId)
      .snapshots()
      .map((snap) => Panel.fromFirestore(snap));
});

final panelEventsProvider =
    StreamProvider.family<List<PanelEvent>, String>((ref, panelId) {
  return FirebaseFirestore.instance
      .collection(Collections.events)
      .where('panelId', isEqualTo: panelId)
      .orderBy('timestamp', descending: true)
      .limit(50)
      .snapshots()
      .map((snap) =>
          snap.docs.map((d) => PanelEvent.fromFirestore(d)).toList());
});

final hasOpenZonesProvider =
    Provider.family<bool, (String panelId, int partitionId)>((ref, params) {
  final (panelId, partitionId) = params;
  final panelAsync = ref.watch(panelStreamProvider(panelId));
  return panelAsync.when(
    data: (panel) => panel.zones
        .where((z) => z.partitionId == partitionId)
        .any((z) => z.state == ZoneState.open),
    loading: () => false,
    error: (_, __) => false,
  );
});
