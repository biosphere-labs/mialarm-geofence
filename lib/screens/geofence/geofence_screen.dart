import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/site.dart';
import '../../providers/auth_provider.dart';
import '../../providers/geofence_provider.dart';
import '../../utils/theme.dart';
import '../../widgets/status_indicator.dart';

/// Geofence configuration screen.
///
/// PROVIDED — this is the differentiator feature screen. It demonstrates:
/// - Slider for radius adjustment
/// - Switch for enable/disable
/// - DropdownButton for mode selection
/// - Real-time presence display
/// - Complex form state management
///
/// Note: Google Maps integration is commented out to avoid needing
/// a Maps API key for the initial build. You can add it later.
class GeofenceScreen extends ConsumerStatefulWidget {
  const GeofenceScreen({super.key});

  @override
  ConsumerState<GeofenceScreen> createState() => _GeofenceScreenState();
}

class _GeofenceScreenState extends ConsumerState<GeofenceScreen> {
  double _radius = 200;
  String _mode = 'prompt';
  bool _enabled = false;
  bool _saving = false;

  bool _initialized = false;

  void _initFromSite(Site site) {
    if (_initialized) return;
    _initialized = true;
    _radius = site.geofence.radiusMeters;
    _mode = site.geofence.mode;
    _enabled = site.geofence.enabled;
  }

  Future<void> _save(Site site) async {
    setState(() => _saving = true);

    try {
      final updatedConfig = site.geofence.copyWith(
        radiusMeters: _radius,
        mode: _mode,
        enabled: _enabled,
      );

      await ref.read(firestoreServiceProvider).updateGeofence(
            site.id,
            updatedConfig,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Geofence settings saved')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.alert,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final siteAsync = ref.watch(primarySiteProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Geofence Settings')),
      body: siteAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (site) {
          if (site == null) {
            return const Center(child: Text('No site configured'));
          }

          _initFromSite(site);
          return _buildContent(site);
        },
      ),
    );
  }

  Widget _buildContent(Site site) {
    final presenceAsync = ref.watch(presenceProvider(site.id));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Map placeholder
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.textMuted.withValues(alpha: 0.3)),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.map, size: 48, color: AppColors.textMuted),
                  const SizedBox(height: 8),
                  Text(
                    'Map view',
                    style: TextStyle(color: AppColors.textMuted),
                  ),
                  Text(
                    '${site.geofence.latitude.toStringAsFixed(4)}, '
                    '${site.geofence.longitude.toStringAsFixed(4)}',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    'Radius: ${_radius.round()}m',
                    style: TextStyle(
                      color: AppColors.accent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Enable/disable toggle
          SwitchListTile(
            title: const Text('Enable Geofencing'),
            subtitle: Text(
              _enabled
                  ? 'Auto-arm when everyone leaves'
                  : 'Manual arm/disarm only',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            value: _enabled,
            onChanged: (v) => setState(() => _enabled = v),
            activeColor: AppColors.primary,
          ),

          if (_enabled) ...[
            const Divider(),

            // Radius slider
            const SizedBox(height: 16),
            Text(
              'Radius: ${_radius.round()}m',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            Slider(
              value: _radius,
              min: 100,
              max: 500,
              divisions: 8,
              label: '${_radius.round()}m',
              onChanged: (v) => setState(() => _radius = v),
            ),

            // Mode selector
            const SizedBox(height: 16),
            const Text(
              'When everyone leaves:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                  value: 'auto',
                  label: Text('Auto-arm'),
                  icon: Icon(Icons.lock, size: 16),
                ),
                ButtonSegment(
                  value: 'prompt',
                  label: Text('Ask me'),
                  icon: Icon(Icons.notifications, size: 16),
                ),
              ],
              selected: {_mode},
              onSelectionChanged: (v) => setState(() => _mode = v.first),
            ),

            const SizedBox(height: 8),
            Text(
              _mode == 'auto'
                  ? 'System will arm automatically when the last person leaves.'
                  : 'You\'ll get a notification to confirm arming.',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),

            // Dwell time info
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(Icons.timer, color: AppColors.accent),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Dwell Time: 2 minutes',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Must be outside the zone for 2 minutes before triggering. Prevents false triggers from GPS drift.',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Who's home section
            const SizedBox(height: 24),
            const Text(
              'Who\'s Home',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            presenceAsync.when(
              loading: () => const CircularProgressIndicator(),
              error: (e, _) => Text('Error: $e'),
              data: (presence) {
                if (presence.isEmpty) {
                  return const Text(
                    'No presence data yet',
                    style: TextStyle(color: AppColors.textMuted),
                  );
                }

                return Column(
                  children: presence.entries.map((entry) {
                    final memberData =
                        entry.value as Map<String, dynamic>? ?? {};
                    final isInside = memberData['inside'] as bool? ?? false;

                    return ListTile(
                      leading: StatusIndicator(
                        color: isInside ? AppColors.armed : AppColors.disarmed,
                        size: 14,
                      ),
                      title: Text(entry.key.substring(0, 8)),
                      // In production: lookup display name
                      subtitle: Text(
                        isInside ? 'Home' : 'Away',
                        style: TextStyle(
                          color: isInside
                              ? AppColors.armed
                              : AppColors.disarmed,
                        ),
                      ),
                      dense: true,
                    );
                  }).toList(),
                );
              },
            ),
          ],

          // Save button
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saving ? null : () => _save(site),
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Save Settings'),
            ),
          ),
        ],
      ),
    );
  }
}
