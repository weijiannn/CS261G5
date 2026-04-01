import 'package:air_traffic_sim/persistence/schema.dart';
import 'package:sqlite3/sqlite3.dart';

/// Base interface that gives repositories access to the database.
abstract interface class DatabaseAccessor {
  Database get database;
}

// Opens and owns a SQLite database connection at a file [path].
class DatabaseProvider implements DatabaseAccessor {
  Database? _database;

  DatabaseProvider(String path) : _database = _openAndInitialize(path);

  static Database _openAndInitialize(String path) {
    final database = sqlite3.open(path);
    initializeDatabase(database);
    return database;
  }

  @override
  Database get database {
    final database = _database;
    if (database == null) {
      throw StateError('DatabaseProvider has already been disposed.');
    }
    return database;
  }

  void dispose() {
    _database?.dispose();
    _database = null;
  }
}
