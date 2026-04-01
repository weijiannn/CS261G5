import 'package:collection/collection.dart';
import 'package:air_traffic_sim/simulation/enums/runway_mode.dart';
import 'package:air_traffic_sim/simulation/interfaces/i_aircraft.dart';
import 'package:air_traffic_sim/simulation/interfaces/i_runway.dart';
import 'package:air_traffic_sim/simulation/interfaces/i_airport.dart';
import 'package:air_traffic_sim/simulation/exceptions/aircraft_incompatibility_exception.dart';
import 'package:air_traffic_sim/simulation/exceptions/runway_not_found_exception.dart';
import 'package:air_traffic_sim/simulation/exceptions/runway_unavailable_exception.dart';
import 'package:air_traffic_sim/simulation/implementations/aircraft.dart'; 
import 'package:air_traffic_sim/simulation/concretes/sim_clock.dart'; 

class Airport implements IAirport {
  final PriorityQueue<IAircraft> _holdingPattern;
  final QueueList<IAircraft> _takeOffQueue;
  final List<IRunway> _runways;

  Airport(this._runways)
      : _takeOffQueue = QueueList<IAircraft>(),
        _holdingPattern = PriorityQueue<IAircraft>((a, b) {
          bool aEmergency = a.isEmergency();
          bool bEmergency = b.isEmergency();

          if (aEmergency && !bEmergency) return -1;
          if (!aEmergency && bEmergency) return 1;

          return a.getScheduledTime.compareTo(b.getScheduledTime);
        });

  @override
  int get getHoldingCount => _holdingPattern.length;

  @override
  int get getTakeOffCount => _takeOffQueue.length;

  @override
  void addToHolding(IAircraft aircraft) {
    if (aircraft is! InboundAircraft) {
      throw AircraftIncompatibilityException(
          aircraft.getScheduledTime, 
          "Attempted to add a non-landing aircraft to the holding pattern."
      );
    }
    _holdingPattern.add(aircraft);
  }

  @override
  void addToTakeOff(IAircraft aircraft) {
    if (aircraft is! OutboundAircraft) {
      throw AircraftIncompatibilityException(
          aircraft.getScheduledTime, 
          "Attempted to add a non-takeOff aircraft to the take-off queue."
      );
    }
    _takeOffQueue.add(aircraft);
  }

  @override
  IAircraft get firstInHolding => _holdingPattern.removeFirst();
  @override
  IAircraft get firstInTakeOff => _takeOffQueue.removeFirst();

  @override
  bool get isHoldingEmpty => _holdingPattern.isEmpty;

  @override
  bool get isTakeOffEmpty => _takeOffQueue.isEmpty;

  @override
  bool get hasEmergency {
    if (_holdingPattern.isEmpty) return false;
    return _holdingPattern.first.isEmergency();
  }

  @override
  int useRunway(int id, [bool emergency = false]) {
    IRunway? r = getRunway(id);
    
    if (r == null) {
      throw RunwayNotFoundException(id, "Runway with ID $id does not exist.");
    }
    
    if (!r.isAvailable) {
      throw RunwayUnavailableException(id, "Runway with ID $id is not available.");
    }

    RunwayMode mode = r.mode(emergency:emergency,holdingEmpty:isHoldingEmpty,takeOffEmpty:isTakeOffEmpty);
    IAircraft assignedAircraft;

    if (mode == RunwayMode.landing) {
      if (isHoldingEmpty) return 0; 
      assignedAircraft = _holdingPattern.removeFirst();
    } else {
      if (isTakeOffEmpty) return 0;
      assignedAircraft = _takeOffQueue.removeFirst();
    }

    r.assignAircraft(assignedAircraft);
    // Delay calculation
    return SimulationClock.time - assignedAircraft.getScheduledTime; 
  }

  /// For fewer iterations, we decrement fuel levels as we check for diversions.
  @override
  List<IAircraft> divert(int fuelThreshold) {
    List<IAircraft> divertedAircraft = [];
    List<IAircraft> keptAircraft = [];

    while (_holdingPattern.isNotEmpty) {
      IAircraft a = _holdingPattern.removeFirst();

      (a.getActualTime + a.getInitFuelLevel - SimulationClock.time) <= fuelThreshold ? divertedAircraft.add(a) : keptAircraft.add(a);
    }

    _holdingPattern.addAll(keptAircraft);
    return divertedAircraft;
  }

  @override
  List<IAircraft> cancel(int waitTime) {
    List<IAircraft> keptAircraft = [];
    List<IAircraft> cancelledAircraft = [];

    while (_takeOffQueue.isNotEmpty) {
      IAircraft a = _takeOffQueue.removeFirst();

      (SimulationClock.time - a.getActualTime) >= waitTime ? cancelledAircraft.add(a) : keptAircraft.add(a);
    }

    _takeOffQueue.addAll(keptAircraft);
    return cancelledAircraft;
  }

  @override
  void update() {
    // Update Runways (Check for expired closures/maintenance, or wait updates)
    for (var r in _runways) {
      r.updateStatus();
    }
  }

  @override
  IRunway? getRunway(int id) {
    return _runways.firstWhereOrNull((r) => r.id == id);
  }

  @override
  List<IRunway> get getRunways => _runways;
}
