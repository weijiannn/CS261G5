import 'package:air_traffic_sim/persistence/database.dart';
import 'package:air_traffic_sim/persistence/repositories/run_repository.dart';
import 'package:air_traffic_sim/persistence/repositories/sqlite/sqlite_run_repository.dart';
import 'package:air_traffic_sim/persistence/repositories/sqlite/sqlite_scenario_repository.dart';

/// Main entry point for SQLite persistence.
///
/// Creates the concrete SQLite repositories used by the app.

class SqlitePersistenceStore {
  final DatabaseAccessor databaseProvider;

  late final SqliteScenarioRepository scenarioRepository;
  late final RunRepository runRepository;

  SqlitePersistenceStore(this.databaseProvider) {
    scenarioRepository = SqliteScenarioRepository(databaseProvider);
    runRepository = SqliteRunRepository(databaseProvider);
  }
}
