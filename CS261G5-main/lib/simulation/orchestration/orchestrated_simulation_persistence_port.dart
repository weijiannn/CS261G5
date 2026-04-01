import 'package:air_traffic_sim/persistence/repositories/run_repository.dart';
import 'package:air_traffic_sim/simulation/concretes/simulation_stats.dart';
import 'package:air_traffic_sim/simulation/interfaces/interface_simulation_persistence_port.dart';

/// Simple adapter that writes simulation records directly to persistent storage.
class OrchestratedSimulationPersistencePort implements ISimulationPersistencePort {
  final RunRepository _runRepository;

  OrchestratedSimulationPersistencePort({
    required RunRepository runRepository,
  })  : _runRepository = runRepository;

  @override
  Future<SimulationRunHandle> startRun({
    required String scenarioId,
  }) async {
    final persistedRunId = await _runRepository.inTransaction((transaction) {
      return _runRepository.insertRun(
        transaction: transaction,
        scenarioId: scenarioId,
        stats: SimulationStats.empty(),
      );
    });

    return SimulationRunHandle(
      runId: persistedRunId,
      scenarioId: scenarioId,
    );
  }

  @override
  Future<void> finalizeRun({
    required SimulationRunHandle run,
    required SummaryMetricsPayload summary,
  }) async {
    final existingRun = await _runRepository.getRun(run.runId);
    if (existingRun == null) {
      throw StateError('Run ${run.runId} cannot be finalized without summary metrics.');
    }

    await _runRepository.inTransaction((transaction) {
      return _runRepository.updateRun(
        transaction: transaction,
        id: run.runId,
        stats: summary.stats,
        updatedAt: summary.createdAt,
      );
    });
  }
}
