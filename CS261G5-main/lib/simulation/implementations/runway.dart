import 'package:air_traffic_sim/simulation/enums/runway_mode.dart';
import 'package:air_traffic_sim/simulation/enums/runway_status.dart';
import 'package:air_traffic_sim/simulation/interfaces/i_aircraft.dart';
import 'package:air_traffic_sim/simulation/interfaces/i_runway.dart';
import 'package:air_traffic_sim/simulation/concretes/sim_clock.dart';
import 'aircraft.dart';

/// Abstract base class handling shared runway logic.
abstract class AbstractRunway implements IRunway {
  final int _id;
  static const int occupationTime = 1;
  static const int wakeSeparationTime = 3;
  
  RunwayStatus _status = RunwayStatus.available;
  int _nextAvailable = 0;
  int _landingFinishes = 0 - wakeSeparationTime;

  AbstractRunway({
    required int id,
  }) : _id = id;

  @override
  int get id => _id;

  @override
  RunwayStatus get status => _status;

  @override
  RunwayStatus updateStatus(){
    if (isAvailable) {
      _status = RunwayStatus.available;
    } else if (_status == RunwayStatus.occupied && SimulationClock.time >= _landingFinishes) {
      _status = RunwayStatus.wait;
    } 
    // We do not automatically update to occupied status when a runway becomes unavailable, as it may be closed for maintenance or other reasons rather than occupied by a landing. Instead, we rely on the specific event that makes the runway unavailable to set the appropriate status.
    return _status;
  }
  
  @override
  int get nextAvailable => _nextAvailable;

  @override
  bool get isAvailable => _nextAvailable <= SimulationClock.time;

  @override
  void assignAircraft(IAircraft aircraft) {
    if (!isAvailable) {
      throw StateError("Runway $_id is not available for assignment.");
    }
    _status = RunwayStatus.occupied;
    // Occupation is always exactly 1 minute regardless of speed/length
    _landingFinishes = SimulationClock.time + occupationTime;
    _nextAvailable = _landingFinishes + wakeSeparationTime;
  }

  @override
  void closeRunway(int duration, RunwayStatus newStatus) {
    if (duration <= occupationTime + wakeSeparationTime) {
      throw ArgumentError("Closure duration must be strictly greater than ${occupationTime + wakeSeparationTime}.");
    }

    if ([RunwayStatus.available, RunwayStatus.occupied, RunwayStatus.wait].contains(newStatus)) {
      throw ArgumentError(
        "A runway cannot be closed with the status $newStatus."
      );
    }
    
    if (isAvailable){
      _nextAvailable = SimulationClock.time + duration;
    } else if (_nextAvailable > _landingFinishes + wakeSeparationTime) { // If already closed for a future time, just extend the closure
      _nextAvailable += duration;
    } else if (SimulationClock.time < _landingFinishes) { // If currently landing, finish landing before closure 
      _nextAvailable = _landingFinishes + duration;
    } else { // Otherwise, just set next available to current time plus duration
      _nextAvailable = SimulationClock.time + duration;
    }

    _status = newStatus;
  }

  /// In the case of cancelled events, setback determine how far back the next available time should be pushed. 
  /// This is to allow for some flexibility in how we want to handle cancellations - for example, 
  /// if a runway was supposed to be closed for 5 minutes but the event is cancelled after 2 minutes have already passed,
  /// [setback] should still be 5 to allow for past resetting and make the runway available immediately.
  /// 
  /// If an event is cancelled, but there was a landing and we are in the wake separation period, the runway does
  /// not become available immediately, as the wake separation time must still be observed.
  /// In this case, setback is ignored and the runway becomes available after the remaining wake separation time has passed.
  @override
  void open([int setback = 0]) {
    if (_status == RunwayStatus.occupied || _status == RunwayStatus.wait) {
      throw StateError("Runway $_id is currently occupied by a landing, cannot open until landing is finished.");
    } else if (setback <= 0) {
      throw ArgumentError("Setback must be strictly greater than 0.");
    } else if (isAvailable && setback > 0) {
      throw StateError("Runway is already available, cannot setback.");
    }
    // We only set back in scenarios where it is useful, to prevent potential race conditions.
    if (_nextAvailable > SimulationClock.time) {
      _nextAvailable -= setback;
    }
    // Only open if the current time has actually reached or passed the next available time
    if (SimulationClock.time >= _nextAvailable) {
      if (SimulationClock.time < _landingFinishes + wakeSeparationTime) {
        // Ensure that the runway does not become available until the wake separation time has passed
        _status = RunwayStatus.wait;
        _nextAvailable = _landingFinishes + wakeSeparationTime;
      } else {
        _status = RunwayStatus.available;
      }
    }
  }

  /// The mode method is left abstract for the specific subclasses to implement.
  @override
  RunwayMode mode({bool emergency = false, bool takeOffEmpty = false, bool holdingEmpty = false});

  /// Abstracted away
  @override
  int get bearing => throw UnimplementedError();
  @override
  int get length => throw UnimplementedError();
}


/// Concrete implementation for a runway dedicated solely to landing.
class LandingRunway extends AbstractRunway {
  LandingRunway({required super.id});

  @override
  RunwayMode mode({bool emergency = false, bool takeOffEmpty = false, bool holdingEmpty = false}) => RunwayMode.landing;
}


/// Concrete implementation for a runway dedicated solely to take-offs.
class TakeOffRunway extends AbstractRunway {
  TakeOffRunway({required super.id});

  @override
  RunwayMode mode({bool emergency = false, bool takeOffEmpty = false, bool holdingEmpty = false}) => RunwayMode.takeOff;
}


/// Concrete implementation for a mixed-use runway that alternates modes.
class MixedRunway extends AbstractRunway {
  // Defaults to landing first, but this will self-correct after the first assignment
  bool _isLandingNext = true; 

  MixedRunway({required super.id});

  @override
  RunwayMode mode({bool emergency = false, bool takeOffEmpty = false, bool holdingEmpty = false}) {
    // Emergency logic: always prioritize landing if needed
    if (emergency || takeOffEmpty) {
      return RunwayMode.landing;
    } else if (holdingEmpty || !_isLandingNext) {
      return RunwayMode.takeOff;
    }
    return RunwayMode.landing;
  }

  @override
  void assignAircraft(IAircraft aircraft) {
    super.assignAircraft(aircraft); 
    
    if (aircraft is InboundAircraft) {
      _isLandingNext = false;
    } else {
      _isLandingNext = true;
    }
  }
}