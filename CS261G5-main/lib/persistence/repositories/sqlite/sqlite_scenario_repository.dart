import 'package:air_traffic_sim/persistence/database.dart';
import 'package:air_traffic_sim/persistence/models/scenario_record.dart';
import 'package:air_traffic_sim/persistence/repositories/scenario_repository.dart';
import 'package:air_traffic_sim/persistence/repositories/sqlite/sqlite_row_mappers.dart';

class SqliteScenarioRepository implements ScenarioRepository {
  final DatabaseAccessor databaseAccessor;

  const SqliteScenarioRepository(this.databaseAccessor);

  @override
  Future<void> upsertScenario(ScenarioRecord scenario) async {
    databaseAccessor.database.execute(
      '''
      INSERT INTO scenarios (id, name, generation_model, description, config_json, notes, created_at)
      VALUES (?, ?, ?, ?, ?, ?, ?)
      ON CONFLICT(id) DO UPDATE SET
      name = excluded.name,
      generation_model = excluded.generation_model,
      description = excluded.description,
      config_json = excluded.config_json,
      notes = excluded.notes,
      created_at = excluded.created_at
      ''',
      [
        scenario.id,
        scenario.name,
        scenario.generationModel,
        scenario.description,
        scenario.configJson,
        scenario.notes,
        toUtcText(scenario.createdAt),
      ],
    );
  }

  @override
  Future<ScenarioRecord?> getScenarioById(String id) async {
    final rows = databaseAccessor.database.select(
      'SELECT id, name, generation_model, description, config_json, notes, created_at FROM scenarios WHERE id = ?',
      [id],
    );

    if (rows.isEmpty) {
      return null;
    }

    return toScenarioRecord(rows.first);
  }

  @override
  Future<List<ScenarioRecord>> listScenarios() async {
    final rows = databaseAccessor.database.select(
      'SELECT id, name, generation_model, description, config_json, notes, created_at FROM scenarios ORDER BY created_at DESC',
    );

    return rows.map(toScenarioRecord).toList(growable: false);
  }

  @override
  Future<void> deleteScenarioById(String id) async {
    databaseAccessor.database.execute(
      'DELETE FROM scenarios WHERE id = ?',
      [id],
    );
  }

  @override
  Future<int> deleteAllScenarios() async {
    databaseAccessor.database.execute('DELETE FROM scenarios');
    return databaseAccessor.database.updatedRows;
  }
}
