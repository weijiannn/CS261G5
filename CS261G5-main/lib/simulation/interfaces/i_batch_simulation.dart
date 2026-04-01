import 'package:air_traffic_sim/simulation/concretes/simulation_stats.dart';

/// Interface for any simulation which runs from start to finish without user intervention.
abstract class IBatchSimulation {
  /// Master method for starting the simulation.
  SimulationStats run();
}