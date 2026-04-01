import 'package:air_traffic_sim/persistence/models/run_record.dart';
import 'package:air_traffic_sim/simulation/concretes/simulation_stats.dart';
import 'package:sqlite3/sqlite3.dart';

abstract class RunRepository {
  Future<T> inTransaction<T>(Future<T> Function(Database transaction) operation);

  /// Returns all summaries for runs belonging to [scenarioId], newest first.
  Future<List<RunRecord>> listRunsByScenario(String scenarioId);
  /// Returns the summary for [runId] or null when no summary has been published.
  Future<RunRecord?> getRun(int runId);

  /// Inserts or updates one metrics summary for [runId] within [transaction].
  Future<int> insertRun({
    required Database transaction,
    required String scenarioId,
    required SimulationStats stats,
  });

  Future<void> updateRun({
    required Database transaction,
    required int id,
    required SimulationStats stats,
    required DateTime updatedAt,
  });

  /// Deletes all but the newest [maxRuns] run records for [scenarioId].
  ///
  /// Returns number of deleted run rows.
  Future<int> trimRunsForScenario({
    required Database transaction,
    required String scenarioId,
    required int maxRuns,
  });

}
