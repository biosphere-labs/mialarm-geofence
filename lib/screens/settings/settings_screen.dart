import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../../providers/auth_provider.dart';
import '../../services/seed_service.dart';
import '../../utils/theme.dart';

/// Settings screen — simple, mostly provided.
///
/// This isn't a learning task. It's just logout + seed data button.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          // Profile section
          ListTile(
            leading: const CircleAvatar(child: Icon(Icons.person)),
            title: Text(user?.displayName ?? 'User'),
            subtitle: Text(user?.email ?? ''),
          ),
          const Divider(),

          // Seed demo data
          ListTile(
            leading: const Icon(Icons.dataset),
            title: const Text('Seed Demo Data'),
            subtitle: const Text('Uses your current GPS location for geofence'),
            onTap: () async {
              final userId = user?.uid;
              if (userId == null) return;

              try {
                // Get current location for realistic geofence placement
                double lat = -26.2041; // Johannesburg fallback
                double lng = 28.0473;

                try {
                  LocationPermission permission = await Geolocator.checkPermission();
                  if (permission == LocationPermission.denied) {
                    permission = await Geolocator.requestPermission();
                  }
                  if (permission == LocationPermission.whileInUse ||
                      permission == LocationPermission.always) {
                    final pos = await Geolocator.getCurrentPosition(
                      locationSettings: const LocationSettings(
                        accuracy: LocationAccuracy.high,
                        timeLimit: Duration(seconds: 10),
                      ),
                    );
                    lat = pos.latitude;
                    lng = pos.longitude;
                  }
                } catch (_) {
                  // Fall back to defaults if location unavailable
                }

                await SeedService().seedDemoData(
                  userId: userId,
                  latitude: lat,
                  longitude: lng,
                );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Demo data seeded with your location')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: AppColors.alert,
                    ),
                  );
                }
              }
            },
          ),

          // About
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('miAlarm Clone'),
            subtitle: Text('v1.0.0 — Geofence Demo'),
          ),
          const Divider(),

          // Logout
          ListTile(
            leading: const Icon(Icons.logout, color: AppColors.disarmed),
            title: const Text(
              'Sign Out',
              style: TextStyle(color: AppColors.disarmed),
            ),
            onTap: () => ref.read(authServiceProvider).signOut(),
          ),
        ],
      ),
    );
  }
}
