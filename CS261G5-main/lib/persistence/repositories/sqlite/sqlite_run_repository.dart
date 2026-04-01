import 'dart:convert';

import 'package:air_traffic_sim/persistence/database.dart';
import 'package:air_traffic_sim/persistence/models/run_record.dart';
import 'package:air_traffic_sim/persistence/repositories/run_repository.dart';
import 'package:air_traffic_sim/persistence/repositories/sqlite/sqlite_row_mappers.dart';
import 'package:air_traffic_sim/simulation/concretes/simulation_stats.dart';
import 'package:sqlite3/sqlite3.dart';

/// SQLite-backed implementation for persisting aggregate simulation metrics.
class SqliteRunRepository implements RunRepository {
  final DatabaseAccessor databaseAccessor;

  const SqliteRunRepository(this.databaseAccessor);

  Database get _db => databaseAccessor.database;

  @override
  Future<T> inTransaction<T>(Future<T> Function(Database transaction) operation) async {
    _db.execute('BEGIN TRANSACTION');

    try {
      final result = await operation(_db);
      _db.execute('COMMIT');
      return result;
    } catch (_) {
      _db.execute('ROLLBACK');
      rethrow;
    }
  }

  /// Inserts one summary row for a run.
  @override
  Future<int> insertRun({
    required Database transaction,
    required String scenarioId,
    required SimulationStats stats,
  }) async {
    transaction.execute(
      '''
      INSERT INTO runs (
        scenario_id, average_landing_delay, average_hold_time, section_average_landing_delay_list,
        average_departure_delay, average_wait_time, section_average_departure_delay_list,
        max_landing_delay, max_departure_delay, max_inbound_queue,
        max_outbound_queue, total_cancellations, total_diversions,
        total_landing_aircraft, total_departing_aircraft, runway_utilisation,
        created_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      ''',
      [
        scenarioId,
        stats.averageLandingDelay,
        stats.averageHoldTime,
        jsonEncode(stats.sectionAverageLandingDelayList),
        stats.averageDepartureDelay,
        stats.averageWaitTime,
        jsonEncode(stats.sectionAverageDepartureDelayList),
        stats.maxLandingDelay,
        stats.maxDepartureDelay,
        stats.maxInboundQueue,
        stats.maxOutboundQueue,
        stats.totalCancellations,
        stats.totalDiversions,
        stats.totalLandingAircraft,
        stats.totalDepartingAircraft,
        stats.runwayUtilisation,
        toUtcText(DateTime.now().toUtc()),
      ],
    );
    return transaction.select('SELECT last_insert_rowid() AS id').first['id'] as int;
  }

  /// Updates one summary row for a run.
  ///
  /// Filters for matching id and updates all fields.
  @override
  Future<void> updateRun({
    required Database transaction,
    required int id,
    required SimulationStats stats,
    required DateTime updatedAt,
  }) async {
    transaction.execute(
      '''
      UPDATE runs SET
        average_landing_delay = ?,
        average_hold_time = ?,
        section_average_landing_delay_list = ?,
        average_departure_delay = ?,
        average_wait_time = ?,
        section_average_departure_delay_list = ?,
        max_landing_delay = ?,
        max_departure_delay = ?,
        max_inbound_queue = ?,
        max_outbound_queue = ?,
        total_cancellations = ?,
        total_diversions = ?,
        total_landing_aircraft = ?,
        total_departing_aircraft = ?,
        runway_utilisation = ?,
        created_at = ?
      WHERE id = ?
      ''',
      [
        stats.averageLandingDelay,
        stats.averageHoldTime,
        jsonEncode(stats.sectionAverageLandingDelayList),
        stats.averageDepartureDelay,
        stats.averageWaitTime,
        jsonEncode(stats.sectionAverageDepartureDelayList),
        stats.maxLandingDelay,
        stats.maxDepartureDelay,
        stats.maxInboundQueue,
        stats.maxOutboundQueue,
        stats.totalCancellations,
        stats.totalDiversions,
        stats.totalLandingAircraft,
        stats.totalDepartingAircraft,
        stats.runwayUtilisation,
        toUtcText(updatedAt),
        id,
      ],
    );
  }

  @override
  Future<int> trimRunsForScenario({
    required Database transaction,
    required String scenarioId,
    required int maxRuns,
  }) async {
    if (maxRuns < 0) {
      throw ArgumentError.value(maxRuns, 'maxRuns', 'must be non-negative');
    }

    transaction.execute(
      '''
      DELETE FROM runs
      WHERE scenario_id = ?
        AND id IN (
          SELECT id
          FROM runs
          WHERE scenario_id = ?
          ORDER BY created_at DESC
          LIMIT -1 OFFSET ?
        )
      ''',
      [scenarioId, scenarioId, maxRuns],
    );

    return transaction.updatedRows;
  }

  /// Loads summaries for all runs under [scenarioId], newest first.
  @override
  Future<List<RunRecord>> listRunsByScenario(String scenarioId) async {
    final rows = databaseAccessor.database.select(
      '''
      SELECT id, scenario_id,
             average_landing_delay, average_hold_time, section_average_landing_delay_list,
             average_departure_delay, average_wait_time, section_average_departure_delay_list,
             max_landing_delay, max_departure_delay, max_inbound_queue,
             max_outbound_queue, total_cancellations, total_diversions,
             total_landing_aircraft, total_departing_aircraft, runway_utilisation,
             created_at
      FROM runs
      WHERE scenario_id = ?
      ORDER BY created_at DESC
      ''',
      [scenarioId],
    );

    return rows.map(toRunRecord).toList(growable: false);
  }

  /// Loads the summary for a specific run.
  @override
  Future<RunRecord?> getRun(int runId) async {
    final rows = databaseAccessor.database.select(
      '''
      SELECT id, scenario_id,
             average_landing_delay, average_hold_time, section_average_landing_delay_list,
             average_departure_delay, average_wait_time, section_average_departure_delay_list,
             max_landing_delay, max_departure_delay, max_inbound_queue,
             max_outbound_queue, total_cancellations, total_diversions,
             total_landing_aircraft, total_departing_aircraft, runway_utilisation,
             created_at
      FROM runs
      WHERE id = ?
      ''',
      [runId],
    );

    if (rows.isEmpty) {
      return null;
    }

    return toRunRecord(rows.first);
  }
}
