import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/panel.dart';
import '../../models/panel_event.dart';
import '../../providers/auth_provider.dart';
import '../../providers/geofence_provider.dart';
import '../../providers/panel_provider.dart';
import '../../services/firestore_service.dart';
import '../../utils/theme.dart';
import '../../widgets/event_tile.dart';
import 'partition_card.dart';
import 'output_button.dart';

// ═══════════════════════════════════════════════════════════════════
// TASK 2: Dashboard Screen                                ~45 min
// ═══════════════════════════════════════════════════════════════════
//
// WHAT YOU'LL LEARN:
//   - ConsumerWidget (Riverpod's version of a widget that reads state)
//   - How to use ref.watch() to subscribe to providers
//   - AsyncValue.when() for handling loading/error/data states
//   - Flutter layout: Column, Row, Expanded, ListView
//   - Widget composition: building a screen from smaller widgets
//
// REFERENCE: Look at event_history_screen.dart to see how it:
//   - Watches a provider with ref.watch()
//   - Handles the AsyncValue with .when()
//   - Builds a list from stream data
//
// REQUIREMENTS:
//   1. Show site name + connection status at the top
//   2. Render a PartitionCard for each partition (widget provided)
//   3. Render OutputButton for each output (your Task 3)
//   4. Show last 5 events at the bottom using EventTile (provided)
//   5. Handle loading and error states
//
// DATA FLOW:
//   ref.watch(primarySiteProvider) → get the site
//   From site → get panelId (use firestoreService.getPanelForSite)
//   ref.watch(panelStreamProvider(panelId)) → real-time panel data
//   ref.watch(panelEventsProvider(panelId)) → recent events
//
// NOTE: You need to complete Task 4 (panel_provider.dart) first,
//   OR you can temporarily use the FirestoreService directly with
//   StreamBuilder (like event_history_screen.dart does) and swap
//   to providers later.
//
// LAYOUT GUIDE:
//   Scaffold
//     AppBar (site name, connection indicator)
//     body: SingleChildScrollView or ListView
//       - Section: Partitions (PartitionCard for each)
//       - Section: Quick Controls (Row of OutputButtons)
//       - Section: Recent Activity (last 5 EventTiles)
//
// ═══════════════════════════════════════════════════════════════════

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final siteAsync = ref.watch(primarySiteProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('miAlarm'),
        // TODO: Show site name from siteAsync data
        // TODO: Add connection status indicator in actions
      ),
      body: siteAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (site) {
          if (site == null) {
            return const Center(child: Text('No site configured'));
          }

          // TODO: Get the panel for this site and build the dashboard
          //
          // Use FutureBuilder with firestoreService.getPanelForSite(site.id)
          // to get the panelId, then use StreamBuilder or providers to
          // stream the panel data.
          //
          // See event_history_screen.dart for this exact pattern.

          return const Center(
            child: Text('TODO: Build dashboard content'),
          );
        },
      ),
    );
  }

  // HINT: You'll probably want helper methods like:
  //
  // Widget _buildPartitions(Panel panel, String userId) { ... }
  // Widget _buildOutputs(Panel panel, String userId) { ... }
  // Widget _buildRecentEvents(List<PanelEvent> events) { ... }
  //
  // Each section can be a Column with a header Text and the widgets.
}
