import 'package:flutter/material.dart';
import '../../models/panel.dart';
import '../../utils/theme.dart';

// ═══════════════════════════════════════════════════════════════════
// TASK 3: Output Button Widget                            ~30 min
// ═══════════════════════════════════════════════════════════════════
//
// WHAT YOU'LL LEARN:
//   - Building reusable widgets with parameters and callbacks
//   - The difference between momentary and toggle interactions
//   - Optimistic UI updates (show change immediately, revert on error)
//   - Choosing icons based on data
//
// REFERENCE: Look at partition_card.dart — it follows the same pattern:
//   - Takes data + callbacks as parameters
//   - Has local loading state
//   - Calls the callback and handles errors
//
// REQUIREMENTS:
//   1. Display an icon based on output name:
//      - "Gate" → Icons.door_sliding
//      - "Garage" → Icons.garage
//      - "Garden Lights" or anything with "light" → Icons.lightbulb
//      - Default → Icons.power_settings_new
//   2. Show the output name below the icon
//   3. For TOGGLE outputs (lights):
//      - Show on/off state visually (filled vs outlined icon, color)
//      - Tap toggles the state
//   4. For MOMENTARY outputs (gate, garage):
//      - Tap shows a brief "active" animation (icon fills/pulses)
//      - Returns to inactive after the callback completes
//   5. Disabled appearance when panelConnected is false
//   6. Show loading indicator during the action
//
// HINTS:
//   - This should be a StatefulWidget (needs local _loading state)
//   - The onTrigger callback does the Firestore update — you just
//     call it and handle the async result
//   - For momentary: the callback already handles the on→delay→off
//     cycle in FirestoreService.triggerOutput()
//   - Use InkWell or IconButton for the tap target
//   - Size: roughly 80x80 including label
//
// ═══════════════════════════════════════════════════════════════════

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

  // TODO: Implement _trigger() method
  //   1. If loading or not connected, return
  //   2. Set loading = true
  //   3. Call widget.onTrigger()
  //   4. Catch errors → show SnackBar
  //   5. Set loading = false

  // TODO: Helper to pick icon based on output name
  //   IconData _iconForOutput(String name) { ... }

  @override
  Widget build(BuildContext context) {
    // TODO: Build the output button widget
    //
    // Suggested structure:
    //   SizedBox(width: 80)
    //     Column
    //       InkWell or GestureDetector
    //         Container (circle, colored border)
    //           Icon (filled if on, outlined if off)
    //       SizedBox(height: 4)
    //       Text (output name, centered, small font)

    return SizedBox(
      width: 80,
      child: Column(
        children: [
          const Icon(Icons.power_settings_new, size: 32),
          const SizedBox(height: 4),
          Text(
            widget.output.name,
            style: const TextStyle(fontSize: 11),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
