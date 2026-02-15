import 'package:flutter/material.dart';
import '../../models/panel.dart';
import '../../utils/theme.dart';
import '../../widgets/status_indicator.dart';

/// Card displaying a partition's state with arm/disarm controls.
///
/// THIS IS A REFERENCE WIDGET — study this to understand the pattern
/// used throughout the app:
///
/// 1. Takes data as parameters (not fetching its own)
/// 2. Uses callbacks for actions (not calling services directly)
/// 3. Handles loading/error states locally
/// 4. Uses the theme constants for colors
///
/// Your OutputButton (Task 3) should follow this same pattern.
class PartitionCard extends StatefulWidget {
  final Partition partition;
  final bool hasOpenZones;
  final bool panelConnected;
  final Future<void> Function(String state) onStateChange;

  const PartitionCard({
    super.key,
    required this.partition,
    this.hasOpenZones = false,
    this.panelConnected = true,
    required this.onStateChange,
  });

  @override
  State<PartitionCard> createState() => _PartitionCardState();
}

class _PartitionCardState extends State<PartitionCard> {
  bool _loading = false;
  String? _error;

  Future<void> _changeState(String newState) async {
    if (_loading || !widget.panelConnected) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await widget.onStateChange(newState);
    } catch (e) {
      setState(() => _error = e.toString());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.alert,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final stateColor = partitionStateColor(widget.partition.state);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: name + status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.partition.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                Row(
                  children: [
                    StatusIndicator(
                      color: stateColor,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      widget.partition.displayState,
                      style: TextStyle(
                        color: stateColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // Warning if zones are open
            if (widget.hasOpenZones) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.bypassed.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.warning_amber, size: 16, color: AppColors.bypassed),
                    SizedBox(width: 6),
                    Text(
                      'Zones open — bypass to arm',
                      style: TextStyle(color: AppColors.bypassed, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Action buttons
            if (_loading)
              const Center(child: CircularProgressIndicator())
            else
              Row(
                children: [
                  _ActionButton(
                    label: widget.partition.isArmed ? 'Disarm' : 'Arm',
                    icon: widget.partition.isArmed ? Icons.lock_open : Icons.lock,
                    color: widget.partition.isArmed
                        ? AppColors.disarmed
                        : AppColors.armed,
                    onPressed: widget.panelConnected
                        ? () => _changeState(
                              widget.partition.isArmed ? 'disarmed' : 'armed',
                            )
                        : null,
                  ),
                  const SizedBox(width: 8),
                  _ActionButton(
                    label: 'Home',
                    icon: Icons.home,
                    color: AppColors.homeArm,
                    onPressed: widget.panelConnected &&
                            widget.partition.state != 'home_arm'
                        ? () => _changeState('home_arm')
                        : null,
                    active: widget.partition.state == 'home_arm',
                  ),
                  const SizedBox(width: 8),
                  _ActionButton(
                    label: 'Sleep',
                    icon: Icons.bedtime,
                    color: AppColors.sleepArm,
                    onPressed: widget.panelConnected &&
                            widget.partition.state != 'sleep_arm'
                        ? () => _changeState('sleep_arm')
                        : null,
                    active: widget.partition.state == 'sleep_arm',
                  ),
                ],
              ),

            // Not connected overlay
            if (!widget.panelConnected)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Panel offline',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback? onPressed;
  final bool active;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    this.onPressed,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 16),
        label: Text(label, style: const TextStyle(fontSize: 12)),
        style: OutlinedButton.styleFrom(
          foregroundColor: active ? Colors.white : color,
          backgroundColor: active ? color.withValues(alpha: 0.3) : null,
          side: BorderSide(color: color.withValues(alpha: 0.5)),
          padding: const EdgeInsets.symmetric(vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }
}
