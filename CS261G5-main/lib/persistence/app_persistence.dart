import 'dart:io';

import 'package:air_traffic_sim/persistence/database.dart';
import 'package:air_traffic_sim/persistence/repositories/run_repository.dart';
import 'package:air_traffic_sim/persistence/repositories/scenario_repository.dart';
import 'package:air_traffic_sim/persistence/repositories/sqlite/sqlite_persistence_store.dart';

/// Shared place that sets up saved-data tools for the app.
class AppPersistence {
  final DatabaseProvider provider;
  final SqlitePersistenceStore store;

  AppPersistence._({
    required this.provider,
    required this.store,
  });

  static AppPersistence? _instance;

  static AppPersistence get instance {
    return _instance ??= (() {
      final provider = DatabaseProvider(_resolveDatabasePath());
      return AppPersistence._(
        provider: provider,
        store: SqlitePersistenceStore(provider),
      );
    })();
  }

  static String _resolveDatabasePath() {
    if (Platform.environment.containsKey('FLUTTER_TEST')) {
      return ':memory:';
    }

    final homeDirectory =
        Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'];
    if (homeDirectory == null || homeDirectory.isEmpty) {
      return 'air_traffic_sim.db';
    }

    final appDirectory = Directory('$homeDirectory/.air_traffic_sim');
    if (!appDirectory.existsSync()) {
      appDirectory.createSync(recursive: true);
    }

    return '${appDirectory.path}/air_traffic_sim.db';
  }

  void close() => provider.dispose();

  ScenarioRepository get scenarioRepository => store.scenarioRepository;

  RunRepository get runRepository => store.runRepository;
}
