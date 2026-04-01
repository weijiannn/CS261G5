import 'dart:io';

import 'package:air_traffic_sim/persistence/database.dart';
import 'package:air_traffic_sim/persistence/models/scenario_record.dart';
import 'package:air_traffic_sim/persistence/repositories/sqlite/sqlite_persistence_store.dart';
import 'package:air_traffic_sim/simulation/concretes/simulation_stats.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('sqlite repositories', () {
    late Directory tempDir;
    late DatabaseProvider provider;
    late SqlitePersistenceStore store;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('sqlite-repo-test-');
      provider = DatabaseProvider('${tempDir.path}/test.db');
      store = SqlitePersistenceStore(provider);
    });

    tearDown(() {
      provider.dispose();
      tempDir.deleteSync(recursive: true);
    });

    test('supports scenario/run round-trip', () async {
      final scenario = ScenarioRecord(
        id: 'scenario-1',
        name: 'Scenario One',
        description: '{"runwayCount":1}',
        createdAt: DateTime.utc(2026, 1, 1),
      );

      await store.scenarioRepository.upsertScenario(scenario);
      final listed = await store.scenarioRepository.listScenarios();
      expect(listed.map((s) => s.id), contains('scenario-1'));

      await store.runRepository.inTransaction((tx) async {
        await store.runRepository.insertRun(
          transaction: tx,
          scenarioId: scenario.id,
          stats: SimulationStats.empty(),
        );

      });

      expect((await store.runRepository.listRunsByScenario(scenario.id)), hasLength(1));
    });

    test('supports scenario delete cascade', () async {
      final scenario = ScenarioRecord(
        id: 'scenario-2',
        name: 'Scenario Two',
        createdAt: DateTime.utc(2026, 1, 2),
      );
      await store.scenarioRepository.upsertScenario(scenario);

      await store.runRepository.inTransaction((tx) async {
        await store.runRepository.insertRun(
          transaction: tx,
          scenarioId: scenario.id,
          stats: SimulationStats.empty(),
        );
      });

      await store.scenarioRepository.deleteScenarioById(scenario.id);
      expect(await store.runRepository.listRunsByScenario(scenario.id), isEmpty);
    });
  });
}
