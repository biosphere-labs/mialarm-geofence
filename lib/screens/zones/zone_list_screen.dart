import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collection/collection.dart';
import '../../models/panel.dart';
import '../../providers/auth_provider.dart';
import '../../providers/geofence_provider.dart';
import '../../services/firestore_service.dart';
import '../../utils/theme.dart';
import '../../widgets/status_indicator.dart';

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

          return FutureBuilder(
            future: firestoreService.getPanelForSite(site.id),
            builder: (context, panelSnap) {
              if (panelSnap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (panelSnap.data == null) {
                return const Center(child: Text('No panel found'));
              }

              final panel = panelSnap.data!;
              return _buildZoneList(context, ref, panel);
            },
          );
        },
      ),
    );
  }

  Widget _buildZoneList(BuildContext context, WidgetRef ref, Panel panel) {
    final firestoreService = ref.read(firestoreServiceProvider);
    final userId = ref.watch(currentUserIdProvider) ?? '';
    final grouped = groupBy(panel.zones, (Zone z) => z.partitionId);

    final items = <Widget>[];
    for (final entry in grouped.entries) {
      final partition =
          panel.partitions.firstWhereOrNull((p) => p.id == entry.key);
      final partitionName = partition?.name ?? 'Partition ${entry.key}';

      items.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Text(
            partitionName,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      );

      for (final zone in entry.value) {
        items.add(
          ListTile(
            leading: StatusIndicator(
              color: zoneStateColor(zone.state),
              size: 14,
            ),
            title: Text(zone.name),
            subtitle: Text(
              zone.displayType,
              style: const TextStyle(fontSize: 12),
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: zoneStateColor(zone.state).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                zone.state.toUpperCase(),
                style: TextStyle(
                  color: zoneStateColor(zone.state),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            onTap: () async {
              final confirmed = await _showBypassDialog(context, zone);
              if (confirmed == true) {
                await firestoreService.setZoneBypass(
                  panel.id,
                  zone.id,
                  !zone.isBypassed,
                  userId,
                );
              }
            },
          ),
        );
      }
    }

    if (items.isEmpty) {
      return Center(
        child: Text('No zones configured', style: TextStyle(color: AppColors.textMuted)),
      );
    }

    return ListView(children: items);
  }

  Future<bool?> _showBypassDialog(BuildContext context, Zone zone) {
    final isBypassed = zone.isBypassed;
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isBypassed ? 'Unbypass Zone' : 'Bypass Zone'),
        content: Text(
          isBypassed
              ? 'Restore ${zone.name} to normal monitoring?'
              : 'Bypass ${zone.name}? It will not trigger alarms while bypassed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(
              foregroundColor:
                  isBypassed ? AppColors.armed : AppColors.bypassed,
            ),
            child: Text(isBypassed ? 'Unbypass' : 'Bypass'),
          ),
        ],
      ),
    );
  }
}
