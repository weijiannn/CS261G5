import 'package:air_traffic_sim/ui/widgets/section_average_graph.dart';
import 'package:flutter/material.dart';

import 'package:air_traffic_sim/ui/models/realtime_dashboard_models.dart';

/// Stateless panel that simply renders the latest input/output metrics.
///
/// The owning screen (see `RealTimeScreen`) is responsible for rebuilding this
/// widget with fresh [inputMetrics] and [outputMetrics] whenever configuration
/// values or simulation statistics change.
class LiveMetricsCard extends StatelessWidget {
  /// Configuration-derived metrics (built via
  /// [buildInputMetricsFromConfiguration]).
  final List<LiveMetricEntry> inputMetrics;

  /// Simulation-derived metrics (built via
  /// [buildLiveMetricsFromTempRealStats]).
  final List<LiveMetricEntry> outputMetrics;

  final List<List<double>> landingDelayOverTime;
  final List<List<double>> takeoffDelayOverTime;

  const LiveMetricsCard({
    super.key,
    required this.inputMetrics,
    required this.outputMetrics,
    required this.landingDelayOverTime,
    required this.takeoffDelayOverTime,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

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
              'Live Metrics',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFFFFFFFF),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Scrollbar(
                thumbVisibility: true,
                thickness: 6,
                radius: const Radius.circular(4),
                child: ListView(
                  primary: true,
                  padding: const EdgeInsets.only(right: 12),
                  children: [
                    Text(
                      'INPUT',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFFFFFFF),
                      ),
                    ),
                    const SizedBox(height: 4),
                    ...inputMetrics
                        .map((metric) => _buildMetricRow(metric, textTheme)),
                    const SizedBox(height: 12),
                    Text(
                      'OUTPUT',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFFFFFFF),
                      ),
                    ),
                    const SizedBox(height: 4),
                    ...outputMetrics
                        .map((metric) => _buildMetricRow(metric, textTheme)),
                    const SizedBox(height: 2),
                    SectionAverageGraph(
                      title: "Average Landing Delay Over Time",
                      multiSectionAverages: landingDelayOverTime,
                    ),
                    SectionAverageGraph(
                      title: "Average Takeoff Delay Over Time",
                      multiSectionAverages: takeoffDelayOverTime,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricRow(
    LiveMetricEntry metric,
    TextTheme textTheme,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              metric.label,
              style: textTheme.bodyMedium?.copyWith(
                color: const Color(0xCCFFFFFF),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: Text(
              metric.value,
              textAlign: TextAlign.right,
              style: textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: const Color(0xFFFFFFFF),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
