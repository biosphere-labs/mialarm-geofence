import 'package:flutter/material.dart';
import '../../models/panel.dart';
import '../../utils/theme.dart';

class OutputButton extends StatefulWidget {
  final Output output;
  final bool panelConnected;
  final Future<void> Function() onTrigger;

  const OutputButton({
    super.key,
    required this.output,
    this.panelConnected = true,
    required this.onTrigger,
  });

  @override
  State<OutputButton> createState() => _OutputButtonState();
}

class _OutputButtonState extends State<OutputButton> {
  bool _loading = false;

  Future<void> _trigger() async {
    if (_loading || !widget.panelConnected) return;

    setState(() => _loading = true);

    try {
      await widget.onTrigger();
    } catch (e) {
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

  IconData _iconForOutput(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('gate')) return Icons.door_sliding;
    if (lower.contains('garage')) return Icons.garage;
    if (lower.contains('light')) return Icons.lightbulb;
    return Icons.power_settings_new;
  }

  @override
  Widget build(BuildContext context) {
    final isOn = widget.output.isOn;
    final color = widget.panelConnected
        ? (isOn ? AppColors.accent : AppColors.textMuted)
        : AppColors.textMuted.withValues(alpha: 0.4);

    return SizedBox(
      width: 80,
      child: Column(
        children: [
          GestureDetector(
            onTap: widget.panelConnected ? _trigger : null,
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: color, width: 2),
                color: isOn ? color.withValues(alpha: 0.2) : Colors.transparent,
              ),
              child: _loading
                  ? const Padding(
                      padding: EdgeInsets.all(14),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(
                      _iconForOutput(widget.output.name),
                      size: 28,
                      color: color,
                    ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.output.name,
            style: TextStyle(fontSize: 11, color: color),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
