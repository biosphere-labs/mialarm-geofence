import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collection/collection.dart';
import '../../models/panel.dart';
import '../../providers/auth_provider.dart';
import '../../providers/geofence_provider.dart';
import '../../services/firestore_service.dart';
import '../../utils/theme.dart';
import '../../widgets/status_indicator.dart';

// ═══════════════════════════════════════════════════════════════════
// TASK 5: Zone List Screen + Confirmation Dialog          ~45 min
// ═══════════════════════════════════════════════════════════════════
//
// WHAT YOU'LL LEARN:
//   - ListView.builder for efficient scrolling lists
//   - Grouping data (zones grouped by partition)
//   - Conditional rendering (different colors/icons per zone state)
//   - showDialog and returning values from dialogs
//
// REFERENCE: event_history_screen.dart shows the StreamBuilder +
//   ListView.builder pattern. partition_card.dart shows state colors.
//
// REQUIREMENTS:
//   1. Zones grouped under partition name headers
//   2. Each zone shows: name, type badge, state with colored dot
//   3. Tap a zone → confirmation dialog → bypass/unbypass
//   4. Bypassed zones shown in amber/yellow
//
// THE CONFIRMATION DIALOG (built inline here, not a separate file):
//   Use showDialog<bool>() to ask "Bypass [zone name]?"
//   Return true on confirm, false on cancel.
//   If the zone is already bypassed, ask "Unbypass [zone name]?"
//
// LAYOUT:
//   Scaffold
//     AppBar("Zones")
//     body: StreamBuilder or FutureBuilder to get panel
//       ListView.builder
//         - For each partition: header text
//         - For each zone in that partition: ListTile
//
// HINTS:
//   - Group zones: groupBy(panel.zones, (z) => z.partitionId)
//     (from package:collection)
//   - Find partition name: panel.partitions.firstWhere((p) => p.id == id)
//   - Zone state colors: use zoneStateColor() from utils/theme.dart
//   - After bypass, call firestoreService.setZoneBypass()
//
// ═══════════════════════════════════════════════════════════════════

class ZoneListScreen extends ConsumerWidget {
  const ZoneListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final siteAsync = ref.watch(primarySiteProvider);
    final firestoreService = ref.read(firestoreServiceProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Zones')),
      body: siteAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (site) {
          if (site == null) {
            return const Center(child: Text('No site configured'));
          }

          // TODO: Get panel for site (same pattern as event_history_screen)
          // Then build the grouped zone list

          return const Center(child: Text('TODO: Build zone list'));
        },
      ),
    );
  }

  // TODO: Implement _showBypassDialog
  //
  // Future<bool?> _showBypassDialog(BuildContext context, Zone zone) {
  //   final isBypassed = zone.state == 'bypassed';
  //   return showDialog<bool>(
  //     context: context,
  //     builder: (ctx) => AlertDialog(
  //       title: Text(isBypassed ? 'Unbypass Zone' : 'Bypass Zone'),
  //       content: Text(
  //         isBypassed
  //           ? 'Restore ${zone.name} to normal monitoring?'
  //           : 'Bypass ${zone.name}? It will not trigger alarms while bypassed.',
  //       ),
  //       actions: [
  //         TextButton(
  //           onPressed: () => Navigator.pop(ctx, false),
  //           child: const Text('Cancel'),
  //         ),
  //         TextButton(
  //           onPressed: () => Navigator.pop(ctx, true),
  //           style: TextButton.styleFrom(
  //             foregroundColor: isBypassed ? AppColors.armed : AppColors.bypassed,
  //           ),
  //           child: Text(isBypassed ? 'Unbypass' : 'Bypass'),
  //         ),
  //       ],
  //     ),
  //   );
  // }
}
