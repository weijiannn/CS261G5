import 'package:flutter/material.dart';

/// Compact card that exposes the primary controls for the
/// real-time simulation: start, pause, and navigate back.
///
/// It is intentionally stateless; the owning screen wires the
/// callbacks to the appropriate simulation and navigation logic.
class ControlsCard extends StatelessWidget {
  final VoidCallback onStart;
  final VoidCallback onPause;
  final VoidCallback onBack;

  const ControlsCard({
    super.key,
    required this.onStart,
    required this.onPause,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      color: const Color(0xFF276FBF),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: onStart,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF183059),
                  foregroundColor: Color(0xFFFFFFFF),
                ),
                child: const Text('START'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: onPause,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF183059),
                  foregroundColor: Color(0xFFFFFFFF),
                ),
                child: const Text('PAUSE'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: onBack,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF183059),
                  foregroundColor: Color(0xFFFFFFFF),
                ),
                child: const Text('BACK'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

