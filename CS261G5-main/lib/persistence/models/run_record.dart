import 'package:air_traffic_sim/simulation/concretes/simulation_stats.dart';

class RunRecord {
  final int id;
  final String scenarioId;
  final SimulationStats stats;
  final DateTime createdAt;

  const RunRecord({
    required this.id,
    required this.scenarioId,
    required this.stats,
    required this.createdAt,
  });
}
