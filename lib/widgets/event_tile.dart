import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/panel_event.dart';
import '../utils/theme.dart';

/// A single event in the event history list.
///
/// Shows an icon (based on event type), the event details, timestamp,
/// and source. Alert events (alarm, panic) are highlighted in red.
class EventTile extends StatelessWidget {
  final PanelEvent event;

  const EventTile({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    final timeFormat = DateFormat('HH:mm');
    final dateFormat = DateFormat('dd MMM');
    final isToday = DateUtils.isSameDay(event.timestamp, DateTime.now());

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: event.isAlert
            ? AppColors.alert.withValues(alpha: 0.2)
            : AppColors.primary.withValues(alpha: 0.2),
        child: Icon(
          _iconForEvent(event.type),
          color: event.isAlert ? AppColors.alert : AppColors.accent,
          size: 20,
        ),
      ),
      title: Text(
        event.details,
        style: TextStyle(
          color: event.isAlert ? AppColors.alert : AppColors.textPrimary,
          fontWeight: event.isAlert ? FontWeight.bold : FontWeight.normal,
          fontSize: 14,
        ),
      ),
      subtitle: Text(
        '${event.source} • ${isToday ? timeFormat.format(event.timestamp) : dateFormat.format(event.timestamp)}',
        style: const TextStyle(
          color: AppColors.textMuted,
          fontSize: 12,
        ),
      ),
      trailing: Text(
        timeFormat.format(event.timestamp),
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 12,
        ),
      ),
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
    );
  }

  IconData _iconForEvent(String type) => switch (type) {
        'arm' => Icons.lock,
        'disarm' => Icons.lock_open,
        'alarm' => Icons.warning_amber,
        'panic' => Icons.emergency,
        'zone_open' => Icons.sensor_door,
        'zone_close' => Icons.door_front_door,
        'output_toggle' => Icons.toggle_on,
        'geofence_enter' => Icons.location_on,
        'geofence_exit' => Icons.location_off,
        'geofence_arm' => Icons.my_location,
        'geofence_disarm' => Icons.location_searching,
        _ => Icons.info_outline,
      };
}
