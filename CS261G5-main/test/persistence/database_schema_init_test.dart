import 'dart:io';

import 'package:air_traffic_sim/persistence/database.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('database schema bootstrap', () {
    test('DatabaseProvider enables foreign keys', () {
      final dbPath = '${Directory.systemTemp.path}/schema-init-${DateTime.now().microsecondsSinceEpoch}.db';
      final provider = DatabaseProvider(dbPath);
      addTearDown(() {
        provider.dispose();
        final file = File(dbPath);
        if (file.existsSync()) file.deleteSync();
      });

      final fk = provider.database.select('PRAGMA foreign_keys').single['foreign_keys'];
      expect(fk, 1);
    });

    test('runs metric summary values must be non-negative', () {
      final dbPath = '${Directory.systemTemp.path}/schema-constraint-${DateTime.now().microsecondsSinceEpoch}.db';
      final provider = DatabaseProvider(dbPath);
      addTearDown(() {
        provider.dispose();
        final file = File(dbPath);
        if (file.existsSync()) file.deleteSync();
      });

      provider.database.execute(
        "INSERT INTO scenarios (id, name, created_at) VALUES ('s-1', 'Scenario', '2026-01-01T00:00:00.000Z')",
      );

      expect(
        () => provider.database.execute(
          "INSERT INTO runs (scenario_id, created_at, average_landing_delay) VALUES ('s-1', '2026-01-01T00:00:00.000Z', -1)",
        ),
        throwsA(isA<Exception>()),
      );
    });
  });
}
