import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../providers/geofence_provider.dart';
import '../../models/panel_event.dart';
import '../../services/firestore_service.dart';
import '../../utils/theme.dart';
import '../../widgets/event_tile.dart';

/// Full event history screen with filtering.
///
/// PROVIDED — this demonstrates:
/// - StreamProvider for real-time Firestore data
/// - ListView.builder for efficient scrolling
/// - AsyncValue.when() pattern for loading/error/data states
/// - Chip-based filtering UI
///
/// Study how the _selectedFilter state works with the stream.
/// Your ZoneListScreen (Task 5) will use a very similar pattern.
class EventHistoryScreen extends ConsumerStatefulWidget {
  const EventHistoryScreen({super.key});

  @override
  ConsumerState<EventHistoryScreen> createState() => _EventHistoryScreenState();
}

class _EventHistoryScreenState extends ConsumerState<EventHistoryScreen> {
  String _selectedFilter = 'all';

  static const _filters = {
    'all': 'All',
    'arm': 'Arm/Disarm',
    'alarm': 'Alarms',
    'zone': 'Zones',
    'output': 'Outputs',
    'geofence': 'Geofence',
  };

  @override
  Widget build(BuildContext context) {
    final site = ref.watch(primarySiteProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Event History')),
      body: site.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (site) {
          if (site == null) {
            return const Center(child: Text('No site configured'));
          }
          return _buildEventList(site.id);
        },
      ),
    );
  }

  Widget _buildEventList(String siteId) {
    // We need the panel ID. Use a FutureBuilder to get it once.
    final firestoreService = ref.read(firestoreServiceProvider);

    return FutureBuilder(
      future: firestoreService.getPanelForSite(siteId),
      builder: (context, panelSnap) {
        if (panelSnap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (panelSnap.data == null) {
          return const Center(child: Text('No panel found'));
        }

        final panelId = panelSnap.data!.id;

        return Column(
          children: [
            // Filter chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: _filters.entries.map((entry) {
                  final isSelected = _selectedFilter == entry.key;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(entry.value),
                      selected: isSelected,
                      onSelected: (_) =>
                          setState(() => _selectedFilter = entry.key),
                      selectedColor: AppColors.primary.withValues(alpha: 0.3),
                    ),
                  );
                }).toList(),
              ),
            ),

            // Event list
            Expanded(
              child: StreamBuilder<List<PanelEvent>>(
                stream: firestoreService.streamEvents(panelId, limit: 100),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final events = snapshot.data ?? [];
                  final filtered = _applyFilter(events);

                  if (filtered.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.history, size: 48,
                              color: AppColors.textMuted),
                          const SizedBox(height: 16),
                          Text(
                            'No events',
                            style: TextStyle(color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      return EventTile(event: filtered[index]);
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  List<PanelEvent> _applyFilter(List<PanelEvent> events) {
    if (_selectedFilter == 'all') return events;

    return events.where((e) {
      return switch (_selectedFilter) {
        'arm' => e.type == 'arm' || e.type == 'disarm',
        'alarm' => e.type == 'alarm' || e.type == 'panic',
        'zone' => e.type == 'zone_open' || e.type == 'zone_close',
        'output' => e.type == 'output_toggle',
        'geofence' => e.type.startsWith('geofence'),
        _ => true,
      };
    }).toList();
  }
}
