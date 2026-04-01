import 'dart:collection';

import 'package:air_traffic_sim/simulation/abstracts/abstract_simulation.dart';
import 'package:air_traffic_sim/simulation/concretes/sim_clock.dart';
import 'package:air_traffic_sim/simulation/implementations/airport.dart';
import 'package:air_traffic_sim/simulation/interfaces/i_batch_simulation.dart';
import 'package:air_traffic_sim/simulation/interfaces/i_parameters.dart';
import 'package:air_traffic_sim/simulation/concretes/simulation_stats.dart';
import 'package:air_traffic_sim/simulation/interfaces/i_runway_event.dart';
import 'package:flutter/widgets.dart';

/// A basic implementation for a simulation.
/// Different simulations will rely on different instantiations of different controllers.
abstract class AbstractBatchSimulation extends AbstractSimulation implements IBatchSimulation {
  @protected
  late final int duration;
  @protected
  late final Queue<IRunwayEvent> events;

  AbstractBatchSimulation(IParameters param){
    events = param.getEvents as Queue<IRunwayEvent>;
    duration = param.getDuration;
    // Store the runways sorted
    airport = Airport(param.getRunways..sort((r1,r2){
      return r1.nextAvailable.compareTo(r2.nextAvailable);
    }));
  }

  /// Public wrapper - only controls the advancing of time steps.
  @override
  SimulationStats run() {
    for (SimulationClock.reset(); SimulationClock.time < duration;){
      step();
    }
    SimulationStats stats = controller.getCurrStats;

    return stats;
  }

  @protected
  void step(){
    controller.enactFlightChanges(airport);
    controller.startRunwayEvents(events, airport);
    controller.includeEnteringAircraft(airport);
    controller.assignAircrafts(airport);
    controller.updateSimClock();
  }
}