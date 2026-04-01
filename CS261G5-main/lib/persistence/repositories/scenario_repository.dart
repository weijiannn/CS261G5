import 'package:air_traffic_sim/persistence/models/scenario_record.dart';

abstract class ScenarioRepository {
  Future<void> upsertScenario(ScenarioRecord scenario);

  Future<ScenarioRecord?> getScenarioById(String id);

  Future<List<ScenarioRecord>> listScenarios();

  /// Deletes one scenario and all related runs/logs.
  Future<void> deleteScenarioById(String id);

  /// Deletes every saved scenario.
  Future<int> deleteAllScenarios();
}
