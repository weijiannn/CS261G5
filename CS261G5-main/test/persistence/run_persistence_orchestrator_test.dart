// Integration checks for the run persistence orchestrator.
import 'dart:io';

import 'package:air_traffic_sim/persistence/database.dart';
import 'package:air_traffic_sim/persistence/models/scenario_record.dart';
import 'package:air_traffic_sim/persistence/repositories/run_repository.dart';
import 'package:air_traffic_sim/persistence/repositories/scenario_repository.dart';
import 'package:air_traffic_sim/persistence/repositories/sqlite/sqlite_persistence_store.dart';
import 'package:air_traffic_sim/simulation/concretes/simulation_stats.dart';
import 'package:air_traffic_sim/simulation/orchestration/run_persistence_orchestrator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RunPersistenceOrchestrator', () {
    late _OrchestratorTestHarness harness;

    setUp(() {
      harness = _OrchestratorTestHarness.create();
    });

    tearDown(() {
      harness.dispose();
    });

    test('persists run records with metrics and timestamps', () async {
      const scenarioId = 'scenario-orchestrator-happy';
      await harness.createScenario(scenarioId);

      final runId = await harness.orchestrator.persistRunLifecycle(
        scenarioId: scenarioId,
        metrics: const SimulationStats(
          averageLandingDelay: 1.2,
          averageHoldTime: 1.2,
          sectionAverageLandingDelayList: [],
          averageDepartureDelay: 1.2,
          averageWaitTime: 1.2,
          sectionAverageDepartureDelayList: [],
          maxLandingDelay: 1,
          maxDepartureDelay: 1,
          maxInboundQueue: 2,
          maxOutboundQueue: 3,
          totalCancellations: 0,
          totalDiversions: 1,
          totalLandingAircraft: 2,
          totalDepartingAircraft: 2,
          runwayUtilisation: 0.5,
        ),
      );

      final runs = await harness.runRepository.listRunsByScenario(scenarioId);

      expect(runs, hasLength(1));
      expect(runs.single.id, runId);
      expect(runs.single.scenarioId, scenarioId);
      expect(runs.single.stats.averageLandingDelay, 1.2);
      expect(runs.single.stats.totalLandingAircraft, 2);
      expect(runs.single.createdAt.isUtc, isTrue);

      // Double-check directly in SQL.
      final rawRunById = harness.provider.database
          .select('SELECT id FROM runs WHERE id = ?', [runId]);
      expect(rawRunById, hasLength(1));
    });

  });
}

// Shared setup for orchestrator persistence tests.
class _OrchestratorTestHarness {
  final Directory tempDir;
  final DatabaseProvider provider;
  final ScenarioRepository scenarioRepository;
  final RunRepository runRepository;
  final RunPersistenceOrchestrator orchestrator;

  _OrchestratorTestHarness._({
    required this.tempDir,
    required this.provider,
    required this.scenarioRepository,
    required this.runRepository,
    required this.orchestrator,
  });

  factory _OrchestratorTestHarness.create() {
    final tempDir = Directory.systemTemp.createTempSync('sqlite-orchestrator-test-');
    final dbPath = '${tempDir.path}/ephemeral.db';
    final provider = DatabaseProvider(dbPath);

    final store = SqlitePersistenceStore(provider);

    return _OrchestratorTestHarness._(
      tempDir: tempDir,
      provider: provider,
      scenarioRepository: store.scenarioRepository,
      runRepository: store.runRepository,
      orchestrator: RunPersistenceOrchestrator(
        runRepository: store.runRepository,
      ),
    );
  }

  Future<void> createScenario(String id) {
    return scenarioRepository.upsertScenario(
      ScenarioRecord(
        id: id,
        name: 'Scenario $id',
        description: 'orchestrator test scenario',
        createdAt: DateTime.utc(2026, 2, 1, 0, 0, 0),
      ),
    );
  }

  void dispose() {
    provider.dispose();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  }
}
