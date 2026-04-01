import 'package:flutter/material.dart';

// Shared constants controlling the simulation speed slider behaviour.
const double kMinSimulationSpeed = 0.25;
const double kMaxSimulationSpeed = 4.0;
const int kSimulationSpeedDivisions = 15;

class SimulationSpeedCard extends StatelessWidget {
  final double speedMultiplier;
  final ValueChanged<double> onSpeedChanged;
  final VoidCallback onAddRunwayEvent;
  final String simulationTimeLabel;

  const SimulationSpeedCard({
    super.key,
    required this.speedMultiplier,
    required this.onSpeedChanged,
    required this.onAddRunwayEvent,
    required this.simulationTimeLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      color: const Color(0xFF276FBF),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Simulation Speed',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFFFFFFFF),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Time Elapsed',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xCCFFFFFF),
                  ),
                ),
                Text(
                  simulationTimeLabel,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFFFFFF),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: const Color(0xFFFFFFFF),
                      secondaryActiveTrackColor: const Color(0xFFFFFFFF),
                      inactiveTrackColor: const Color(0x80FFFFFF),
                      thumbColor: const Color(0xFFFFFFFF),
                      overlayColor: const Color(0x33FFFFFF),
                      valueIndicatorColor: const Color(0xFF183059)
                    ),
                    child: Slider(
                      min: kMinSimulationSpeed,
                      max: kMaxSimulationSpeed,
                      divisions: kSimulationSpeedDivisions,
                      value: speedMultiplier,
                      label: '${speedMultiplier.toStringAsFixed(2)}x',
                      onChanged: onSpeedChanged,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${speedMultiplier.toStringAsFixed(2)}x',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFFFFFF),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: onAddRunwayEvent,
              style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF183059),
                  foregroundColor: Color(0xFFFFFFFF),
                ),
              icon: const Icon(Icons.add),
              label: const Text('Add Runway Event'),
            )
          ],
        ),
      ),
    );
  }
}
