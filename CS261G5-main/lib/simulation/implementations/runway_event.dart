import 'package:air_traffic_sim/simulation/enums/runway_status.dart';
import 'package:air_traffic_sim/simulation/interfaces/i_runway_event.dart'; 

class RunwayEvent implements IRunwayEvent {
  final int _runwayId;
  int startTime;
  int _duration;
  final RunwayStatus _eventType;

  RunwayEvent({
    required int runwayId,
    required this.startTime,
    required int duration,
    required RunwayStatus eventType,
  })  : _runwayId = runwayId,
        _duration = duration,
        _eventType = eventType {
    
    // Enforce the interface constraint: cannot be available or occupied
    if (_eventType == RunwayStatus.available || _eventType.name == 'occupied') {
      throw ArgumentError(
        'A RunwayEvent cannot have a status of ${_eventType.name}. '
        'Must be an event like inspection, snow clearance, closure, etc.'
      );
    }
  }

  @override
  int get getRunwayId => _runwayId;

  @override
  int get getStartTime => startTime;

  @override
  int get getDuration => _duration;
  set setDur(int newDur) => _duration = newDur;

  @override
  RunwayStatus get getEventType => _eventType;
}