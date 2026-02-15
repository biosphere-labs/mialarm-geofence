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
import '../../widgets/status_indicator.dart';
import 'partition_card.dart';
import 'output_button.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final siteAsync = ref.watch(primarySiteProvider);

    return Scaffold(
      appBar: AppBar(
        title: siteAsync.when(
          data: (site) => Text(site?.name ?? 'miAlarm'),
          loading: () => const Text('miAlarm'),
          error: (_, __) => const Text('miAlarm'),
        ),
        actions: [
          siteAsync.when(
            data: (site) => Padding(
              padding: const EdgeInsets.only(right: 16),
              child: StatusIndicator(
                color: site != null ? AppColors.armed : AppColors.textMuted,
              ),
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const Padding(
              padding: EdgeInsets.only(right: 16),
              child: StatusIndicator(color: AppColors.disarmed),
            ),
          ),
        ],
      ),
      body: siteAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (site) {
          if (site == null) {
            return const Center(child: Text('No site configured'));
          }

          final firestoreService = ref.read(firestoreServiceProvider);

          return FutureBuilder(
            future: firestoreService.getPanelForSite(site.id),
            builder: (context, panelSnap) {
              if (panelSnap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (panelSnap.data == null) {
                return const Center(child: Text('No panel found'));
              }

              final panelId = panelSnap.data!.id;
              return _DashboardContent(panelId: panelId);
            },
          );
        },
      ),
    );
  }
}

class _DashboardContent extends ConsumerWidget {
  final String panelId;
  const _DashboardContent({required this.panelId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final panelAsync = ref.watch(panelStreamProvider(panelId));
    final eventsAsync = ref.watch(panelEventsProvider(panelId));
    final userId = ref.watch(currentUserIdProvider) ?? '';
    final firestoreService = ref.read(firestoreServiceProvider);

    return panelAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (panel) {
        return SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Partitions
              for (final partition in panel.partitions)
                PartitionCard(
                  partition: partition,
                  hasOpenZones: ref.watch(
                    hasOpenZonesProvider((panelId, partition.id)),
                  ),
                  panelConnected: panel.connected,
                  onStateChange: (state) => firestoreService
                      .setPartitionState(panelId, partition.id, state, userId),
                ),

              // Outputs
              if (panel.outputs.isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    'Quick Controls',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: panel.outputs
                        .map((output) => OutputButton(
                              output: output,
                              panelConnected: panel.connected,
                              onTrigger: () => firestoreService.triggerOutput(
                                  panelId, output.id, userId),
                            ))
                        .toList(),
                  ),
                ),
              ],

              // Recent events
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
                child: Text(
                  'Recent Activity',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              eventsAsync.when(
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (e, _) => Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('Error loading events: $e'),
                ),
                data: (events) {
                  final recent = events.take(5).toList();
                  if (recent.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'No events yet',
                        style: TextStyle(color: AppColors.textMuted),
                      ),
                    );
                  }
                  return Column(
                    children: recent
                        .map((event) => EventTile(event: event))
                        .toList(),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
