import 'package:air_traffic_sim/simulation/concretes/sim_clock.dart';
import 'package:air_traffic_sim/simulation/interfaces/i_aircraft.dart';
import 'package:air_traffic_sim/simulation/interfaces/i_airport.dart';
import 'package:air_traffic_sim/simulation/interfaces/i_real_controller.dart';
import 'package:air_traffic_sim/simulation/abstracts/abstract_controller.dart';
import 'package:air_traffic_sim/simulation/concretes/temp_real_stats.dart';
import 'package:air_traffic_sim/simulation/interfaces/i_runway.dart';

mixin RealTimeController on AbstractController, IRealTimeController {
  @override
  TempRealStats get getCurrRealStats => super.getCurrTempStats as TempRealStats;

  @override
  void enactFlightChanges(IAirport airport) {
    TempRealStats s = getCurrRealStats;

    int currCancellations = s.totalCancellations;
    int currDiversions = s.totalDiversions;

    super.enactFlightChanges(airport);
    
    currCancellations = s.totalCancellations - currCancellations;
    currDiversions = s.totalDiversions - currDiversions;

    s.currInboundQueueLength -= currDiversions;
    s.currOutboundQueueLength -= currCancellations;

    airport.update();
  }

  @override
  void addToHolding(IAirport airport, IAircraft aircraft) {
    super.addToHolding(airport, aircraft);
    getCurrRealStats.currInboundQueueLength++;
    if (aircraft.isEmergency()) {
      getCurrRealStats.currEmergencyCount++;
    }
  }

  @override
  void addToTakeOff(IAirport airport, IAircraft aircraft) {
    super.addToTakeOff(airport, aircraft);
    getCurrRealStats.currOutboundQueueLength++;
  }

  @override
  void land(IRunway runway, IAircraft aircraft) {
    super.land(runway, aircraft);
    getCurrRealStats.currInboundQueueLength--;
    if (aircraft.isEmergency()) {
      getCurrRealStats.currEmergencyCount--;
    }
  }

  @override
  void depart(IRunway runway, IAircraft aircraft) {
    super.depart(runway, aircraft);
    getCurrRealStats.currOutboundQueueLength--;   
  }

  @override
  bool abortRunwayEvent(IAirport airport,{required int start, required int runwayId, required int duration}) {
    IRunway? r = airport.getRunway(runwayId);
    if (r == null) {return true;} // Unknown whether it has happened or not
    // Only attempt to cancel if the current time is within the event's active window
    if ((start + duration) <= SimulationClock.time){
      return false; // Event has already happened and cannot be cancelled
    }
    if (SimulationClock.time > start) {
      // Set setback to the remaining time of the event to effectively end it immediately
      r.open(duration);
      return false;
    }
    return true; // Event has not yet started
  }
}