import 'package:air_traffic_sim/simulation/concretes/simulation_stats.dart';

/// Stable identifiers returned when a run is started in persistence.
class SimulationRunHandle {
  final int runId;
  final String scenarioId;

  const SimulationRunHandle({
    required this.runId,
    required this.scenarioId,
  });
}

/// Final aggregate metrics for one simulation run.
class SummaryMetricsPayload {
  /// Delay/queue/counter stats computed by the simulation engine.
  final SimulationStats stats;

  /// Timestamp representing when the summary snapshot was created.
  final DateTime createdAt;

  const SummaryMetricsPayload({
    required this.stats,
    required this.createdAt,
  });
}

/// Persistence contract used by the simulation layer.
abstract class ISimulationPersistencePort {
  /// Creates a run row for [scenarioId] and returns identifiers used for future writes.
  Future<SimulationRunHandle> startRun({
    required String scenarioId,
  });

  /// Updates summary metrics for [run].
  Future<void> finalizeRun({
    required SimulationRunHandle run,
    required SummaryMetricsPayload summary,
  });
}
