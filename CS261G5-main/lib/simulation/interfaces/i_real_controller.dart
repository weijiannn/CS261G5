import 'package:air_traffic_sim/simulation/concretes/temp_real_stats.dart';
import 'package:air_traffic_sim/simulation/interfaces/i_airport.dart';
import 'package:air_traffic_sim/simulation/interfaces/i_simulation_controller.dart';

abstract class IRealTimeController extends ISimulationController{
  /// Gets the current simulation stats for the real-time dashboard.
  TempRealStats get getCurrRealStats;
  /// Aborts a runway event with the given ID and duration, stopping it if it is currently active.
  /// Returns true if the event has verifiably not yet started and false otherwise.
  bool abortRunwayEvent(IAirport airport,{required int start, required int runwayId, required int duration});
}