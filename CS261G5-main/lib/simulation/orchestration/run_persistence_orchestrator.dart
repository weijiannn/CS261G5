import 'package:air_traffic_sim/persistence/models/run_record.dart';
import 'package:air_traffic_sim/persistence/repositories/run_repository.dart';
import 'package:air_traffic_sim/simulation/concretes/simulation_stats.dart';
import 'package:air_traffic_sim/simulation/interfaces/interface_simulation_persistence_port.dart';

import 'orchestrated_simulation_persistence_port.dart';

/// Orchestrates persistence for simulation runs.
class RunPersistenceOrchestrator {
  final RunRepository runRepository;

  const RunPersistenceOrchestrator({
    required this.runRepository,
  });

  Future<int> persistRunLifecycle({
    required String scenarioId,
    required SimulationStats metrics,
  }) async {
    final persistencePort = OrchestratedSimulationPersistencePort(
      runRepository: runRepository,
    );

    final run = await persistencePort.startRun(
      scenarioId: scenarioId
    );
    
      await persistencePort.finalizeRun(
      run: run,
      summary: SummaryMetricsPayload(
        stats: metrics,
        createdAt: DateTime.now(),
      ),
    );

    return run.runId;
    }

  Future<List<RunRecord>> listRunsForScenario(String scenarioId) {
    return runRepository.listRunsByScenario(scenarioId);
  }

  Future<RunRecord?> getRun(int runId) {
    return runRepository.getRun(runId);
  }

}
