import 'package:air_traffic_sim/simulation/abstracts/abstract_simulation.dart';
import 'package:air_traffic_sim/simulation/concretes/priority_queue.dart';
import 'package:air_traffic_sim/simulation/concretes/sim_clock.dart';
import 'package:air_traffic_sim/simulation/concretes/temp_real_stats.dart';
import 'package:air_traffic_sim/simulation/implementations/airport.dart';
import 'package:air_traffic_sim/simulation/interfaces/i_parameters.dart';
import 'package:air_traffic_sim/simulation/interfaces/i_real_controller.dart';
import 'package:air_traffic_sim/simulation/interfaces/i_real_simulation.dart';
import 'package:air_traffic_sim/simulation/interfaces/i_runway_event.dart';
import 'package:collection/collection.dart';

class AbstractRealTimeSimulation extends AbstractSimulation implements IRealSimulation {
  @override
  IRealTimeController get controller => super.controller as IRealTimeController;

  late final PriorityQueueWrapper<IRunwayEvent> events;

  AbstractRealTimeSimulation(IParameters param) {
    SimulationClock.reset();
    
    events = PriorityQueueWrapper<IRunwayEvent>(
      (a, b) => a.getStartTime.compareTo(b.getStartTime)
    )..addAll(param.getEvents);

    airport = Airport(param.getRunways.sorted((r1,r2){
      return r1.nextAvailable.compareTo(r2.nextAvailable);
    }));
  }

  @override
  void addRunwayEvent(IRunwayEvent event) {
    events.add(event);
  }

  @override
  void cancelRunwayEvent(IRunwayEvent event) {
    if(controller.abortRunwayEvent(airport, start: event.getStartTime, runwayId: event.getRunwayId, duration: event.getDuration)){
      events.remove(event);
    }
  }

  @override
  TempRealStats getCurrStats() {
    return controller.getCurrRealStats;
  }

  @override
  void tick() {
    controller.enactFlightChanges(airport);
    controller.startRunwayEvents(events,airport);
    controller.includeEnteringAircraft(airport);
    controller.assignAircrafts(airport);
    controller.updateSimClock();
  }
}