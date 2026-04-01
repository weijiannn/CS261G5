import 'dart:convert';
import 'package:sqlite3/sqlite3.dart';

/// Ensures the SQLite database has all tables/indexes needed by the app.
void initializeDatabase(Database db) {
  db.execute('PRAGMA foreign_keys = ON;');

  db.execute('''
    CREATE TABLE IF NOT EXISTS scenarios (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      description TEXT,
      config_json TEXT,
      notes TEXT,
      generation_model TEXT NOT NULL DEFAULT 'Uniform',
      created_at TEXT NOT NULL
    );

    CREATE TABLE IF NOT EXISTS runs (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      scenario_id TEXT NOT NULL,
      average_landing_delay REAL NOT NULL CHECK (average_landing_delay >= 0),
      average_hold_time REAL NOT NULL DEFAULT 0 CHECK (average_hold_time >= 0),
      section_average_landing_delay_list TEXT NOT NULL DEFAULT '[]',
      average_departure_delay REAL NOT NULL CHECK (average_departure_delay >= 0),
      average_wait_time REAL NOT NULL DEFAULT 0 CHECK (average_wait_time >= 0),
      section_average_departure_delay_list TEXT NOT NULL DEFAULT '[]',
      max_landing_delay REAL NOT NULL CHECK (max_landing_delay >= 0),
      max_departure_delay REAL NOT NULL CHECK (max_departure_delay >= 0),
      max_inbound_queue INTEGER NOT NULL CHECK (max_inbound_queue >= 0),
      max_outbound_queue INTEGER NOT NULL CHECK (max_outbound_queue >= 0),
      total_cancellations INTEGER NOT NULL CHECK (total_cancellations >= 0),
      total_diversions INTEGER NOT NULL CHECK (total_diversions >= 0),
      total_landing_aircraft INTEGER NOT NULL DEFAULT 0 CHECK (total_landing_aircraft >= 0),
      total_departing_aircraft INTEGER NOT NULL DEFAULT 0 CHECK (total_departing_aircraft >= 0),
      runway_utilisation REAL NOT NULL DEFAULT 0 CHECK (runway_utilisation >= 0),
      created_at TEXT NOT NULL,
      FOREIGN KEY (scenario_id) REFERENCES scenarios(id) ON DELETE CASCADE
    );

    CREATE INDEX IF NOT EXISTS idx_runs_scenario_created
      ON runs (scenario_id, created_at DESC);
  ''');

  _ensureScenarioColumns(db);
  _backfillScenarioConfigPayload(db);
  _backfillScenarioGenerationModel(db);
}

void _ensureScenarioColumns(Database db) {
  final columns = db
      .select('PRAGMA table_info(scenarios);')
      .map((row) => row['name'] as String)
      .toSet();

  if (!columns.contains('config_json')) {
    db.execute('ALTER TABLE scenarios ADD COLUMN config_json TEXT;');
  }

  if (!columns.contains('notes')) {
    db.execute('ALTER TABLE scenarios ADD COLUMN notes TEXT;');
  }

  if (!columns.contains('generation_model')) {
    db.execute("ALTER TABLE scenarios ADD COLUMN generation_model TEXT NOT NULL DEFAULT 'Uniform';");
  }
}

void _backfillScenarioConfigPayload(Database db) {
  final rows = db.select(
    '''
    SELECT id, description, config_json
    FROM scenarios
    WHERE (config_json IS NULL OR TRIM(config_json) = '')
      AND description IS NOT NULL
      AND TRIM(description) != ''
    ''',
  );

  for (final row in rows) {
    final description = row['description'] as String;
    final configJson = _extractConfigPayloadFromLegacyDescription(description);
    db.execute(
      'UPDATE scenarios SET config_json = ? WHERE id = ?',
      [configJson, row['id'] as String],
    );
  }
}

String _extractConfigPayloadFromLegacyDescription(String description) {
  final trimmed = description.trim();
  if (trimmed.isEmpty) {
    return description;
  }

  try {
    final decoded = jsonDecode(trimmed);
    if (decoded is Map<String, dynamic>) {
      final scenarioPayload = decoded['scenario'];
      if (scenarioPayload is Map<String, dynamic>) {
        return jsonEncode(scenarioPayload);
      }

      final detailsPayload = decoded['details'];
      if (detailsPayload is Map<String, dynamic>) {
        final nestedScenario = detailsPayload['scenario'];
        if (nestedScenario is Map<String, dynamic>) {
          return jsonEncode(nestedScenario);
        }
        return jsonEncode(detailsPayload);
      }

      if (_looksLikeScenarioConfig(decoded)) {
        return jsonEncode(decoded);
      }
    }
  } catch (_) {
    return description;
  }

  return description;
}

bool _looksLikeScenarioConfig(Map<String, dynamic> payload) {
  const scenarioKeys = {
    'runwayCount',
    'duration',
    'durationMinutes',
    'inboundRate',
    'outboundRate',
    'runways',
    'emergencyProbability',
    'maxWaitTime',
    'minFuelThreshold',
  };

  return payload.keys.any(scenarioKeys.contains);
}

void _backfillScenarioGenerationModel(Database db) {
  final rows = db.select(
    '''
    SELECT id, config_json
    FROM scenarios
    WHERE config_json IS NOT NULL
      AND TRIM(config_json) != ''
      AND (
        generation_model IS NULL
        OR TRIM(generation_model) = ''
        OR generation_model = 'Uniform'
      )
    ''',
  );

  for (final row in rows) {
    final inferred = _extractGenerationModel(row['config_json'] as String?);
    db.execute(
      'UPDATE scenarios SET generation_model = ? WHERE id = ?',
      [inferred, row['id'] as String],
    );
  }
}

String _extractGenerationModel(String? configJson) {
  if (configJson == null || configJson.trim().isEmpty) {
    return 'Uniform';
  }

  try {
    final decoded = jsonDecode(configJson);
    if (decoded is Map<String, dynamic>) {
      final value = decoded['generationModel'];
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
  } catch (_) {
    return 'Uniform';
  }

  return 'Uniform';
}
