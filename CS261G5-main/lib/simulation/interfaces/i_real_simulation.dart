import 'package:air_traffic_sim/simulation/concretes/temp_real_stats.dart';
import 'package:air_traffic_sim/simulation/interfaces/i_runway_event.dart';

/// Interface for any real-time simulation. 
/// This is the interface that the real-time dashboard will interact with.
abstract class IRealSimulation {
  /// Advances the simulation by one time step.
  void tick();

  /// Adds a runway event to the simulation.
  void addRunwayEvent(IRunwayEvent event);

  /// Cancels a runway event in the simulation.
  void cancelRunwayEvent(IRunwayEvent event);

  /// Gets the current simulation stats for the real-time dashboard.
  TempRealStats getCurrStats();
}