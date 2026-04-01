import 'dart:collection';

import 'package:air_traffic_sim/simulation/enums/emergency_status.dart';
import 'package:air_traffic_sim/simulation/enums/runway_mode.dart';
import 'package:air_traffic_sim/simulation/enums/runway_status.dart';
import 'package:air_traffic_sim/simulation/interfaces/i_aircraft.dart';
import 'package:air_traffic_sim/simulation/interfaces/i_airport.dart';
import 'package:air_traffic_sim/simulation/interfaces/i_parameters.dart';
import 'package:air_traffic_sim/simulation/interfaces/i_rate_parameters.dart';
import 'package:air_traffic_sim/simulation/interfaces/i_runway.dart';
import 'package:air_traffic_sim/simulation/interfaces/i_runway_event.dart';

class FakeAircraft implements IAircraft {
  FakeAircraft({
    this.id = 'TEST',
    this.scheduledTime = 0,
    int? actualTime,
    this.fuelLevel = 100,
    this.status = EmergencyStatus.none,
    this.operator = 'TEST',
    this.origin = 'AAA',
    this.destination = 'BBB',
    this.altitude = 0,
    this.isEmergencyOverride,
  }) : actualTime = actualTime ?? scheduledTime;

  final String id;

  final int scheduledTime;

  final int actualTime;

  int fuelLevel;

  final EmergencyStatus status;

  final String operator;

  final String origin;

  final String destination;

  final int altitude;

  final bool? isEmergencyOverride;

  @override
  String get getId => id;

  @override
  int get getScheduledTime => scheduledTime;

  @override
  int get getActualTime => actualTime;

  @override
  int get getInitFuelLevel => fuelLevel;

  @override
  EmergencyStatus get getStatus => status;

  @override
  String get getOperator => operator;

  @override
  String get getOrigin => origin;

  @override
  String get getDestination => destination;

  @override
  int get getAltitude => altitude;

  @override
  bool isEmergency() => isEmergencyOverride ?? status != EmergencyStatus.none;

  @override
  void consumeFuel(int fuel) {
    fuelLevel -= fuel;
  }
}

class FakeRunway implements IRunway {
  FakeRunway({
    this.id = 1,
    this.length = 3000,
    this.bearing = 90,
    RunwayStatus status = RunwayStatus.available,
    this.normalMode = RunwayMode.takeOff,
    this.nextAvailable = 0,
  }) : _status = status;

  @override
  final int id;

  @override
  final int length;

  @override
  final int bearing;

  RunwayStatus _status;

  @override
  int nextAvailable;

  final RunwayMode normalMode;
  IAircraft? assignedAircraft;
  int openCallCount = 0;
  final List<int> closedDurations = [];
  final List<RunwayStatus> closedStatuses = [];

  @override
  RunwayStatus get status => _status;

  @override
  bool get isAvailable => _status == RunwayStatus.available;

  @override
  RunwayMode mode({bool emergency = false, bool takeOffEmpty = false, bool holdingEmpty = false}) =>
      emergency ? RunwayMode.landing : normalMode;

  @override
  void assignAircraft(IAircraft aircraft) {
    assignedAircraft = aircraft;
    _status = RunwayStatus.occupied;
  }

  @override
  void closeRunway(int duration, RunwayStatus newStatus) {
    closedDurations.add(duration);
    closedStatuses.add(newStatus);
    nextAvailable += duration;
    _status = newStatus;
  }

  @override
  void open([int setback = 0]) {
    openCallCount++;
    _status = RunwayStatus.available;
  }
  
  @override
  RunwayStatus updateStatus() {
    // TODO: implement updateStatus
    throw UnimplementedError();
  }
}

class FakeAirport implements IAirport {
  FakeAirport({
    List<IRunway>? runways,
  }) : _runways = runways ?? [];

  final List<IRunway> _runways;
  final List<IAircraft> _holding = [];
  final List<IAircraft> _takeOff = [];

  @override
  void addToHolding(IAircraft aircraft) {
    _holding.add(aircraft);
  }

  @override
  void addToTakeOff(IAircraft aircraft) {
    _takeOff.add(aircraft);
  }

  @override
  int useRunway(int id, bool emergency) => 0;

  @override
  List<IAircraft> divert(int fuelThreshold) => [];

  @override
  List<IAircraft> cancel(int waitTime) => [];

  @override
  void update() {}

  @override
  IRunway? getRunway(int id) {
    for (final runway in _runways) {
      if (runway.id == id) {
        return runway;
      }
    }
    return null;
  }

  @override
  List<IRunway> get getRunways => _runways;

  @override
  IAircraft get firstInHolding {
    if (_holding.isEmpty) {
      throw StateError('No aircraft in holding queue.');
    }
    return _holding.removeAt(0);
  }

  @override
  IAircraft get firstInTakeOff {
    if (_takeOff.isEmpty) {
      throw StateError('No aircraft in takeoff queue.');
    }
    return _takeOff.removeAt(0);
  }

  @override
  int get getHoldingCount => _holding.length;

  @override
  int get getTakeOffCount => _takeOff.length;

  @override
  bool get isHoldingEmpty => _holding.isEmpty;

  @override
  bool get isTakeOffEmpty => _takeOff.isEmpty;

  @override
  bool get hasEmergency => _holding.any((aircraft) => aircraft.isEmergency());
}

class FakeParameters implements IParameters {
  FakeParameters({
    List<IRunway>? runways,
    double emergencyProbability = 0,
    Queue<IRunwayEvent>? events,
    int maxWaitTime = 1,
    int minFuelThreshold = 1,
    int duration = 1,
  })  : _runways = runways ?? const <IRunway>[],
        _emergencyProbability = emergencyProbability,
        _events = events ?? Queue<IRunwayEvent>(),
        _maxWaitTime = maxWaitTime,
        _minFuelThreshold = minFuelThreshold,
        _duration = duration;

  final List<IRunway> _runways;
  final double _emergencyProbability;
  final Queue<IRunwayEvent> _events;
  final int _maxWaitTime;
  final int _minFuelThreshold;
  final int _duration;

  @override
  List<IRunway> get getRunways => _runways;

  @override
  double get getEmergencyProbability => _emergencyProbability;

  @override
  Queue<IRunwayEvent> get getEvents => _events;

  @override
  int get getMaxWaitTime => _maxWaitTime;

  @override
  int get getMinFuelThreshold => _minFuelThreshold;

  @override
  int get getDuration => _duration;
  
  @override
  // TODO: implement getLandingRunwayCount
  int get getLandingRunwayCount => throw UnimplementedError();
  
  @override
  // TODO: implement getMixedRunwayCount
  int get getMixedRunwayCount => throw UnimplementedError();
  
  @override
  // TODO: implement getTakeoffRunwayCount
  int get getTakeoffRunwayCount => throw UnimplementedError();
}

class FakeRateParameters extends FakeParameters implements IRateParameters {
  FakeRateParameters({
    super.runways,
    super.emergencyProbability,
    super.events,
    super.maxWaitTime,
    super.minFuelThreshold,
    super.duration,
    int inboundRate = 1,
    int outboundRate = 1,
    int landingRunwayCount = 0,
    int takeoffRunwayCount = 0,
    int mixedRunwayCount = 0,
  })  : _inboundRate = inboundRate,
        _outboundRate = outboundRate,
        _landingRunwayCount = landingRunwayCount,
        _takeoffRunwayCount = takeoffRunwayCount,
        _mixedRunwayCount = mixedRunwayCount;

  final int _inboundRate;
  final int _outboundRate;
  final int _landingRunwayCount;
  final int _takeoffRunwayCount;
  final int _mixedRunwayCount;

  @override
  int get getOutboundRate => _outboundRate;

  @override
  int get getInboundRate => _inboundRate;

  @override
  int get getLandingRunwayCount => _landingRunwayCount;

  @override
  int get getTakeoffRunwayCount => _takeoffRunwayCount;

  int get getTakeOffRunwayCount => _takeoffRunwayCount;

  @override
  int get getMixedRunwayCount => _mixedRunwayCount;
}

class FakeRunwayEvent implements IRunwayEvent {
  FakeRunwayEvent({
    required this.runwayId,
    required this.startTime,
    required this.duration,
    required this.eventType,
  });

  final int runwayId;
  final int startTime;
  final int duration;
  final RunwayStatus eventType;

  @override
  int get getRunwayId => runwayId;

  @override
  int get getStartTime => startTime;

  @override
  int get getDuration => duration;

  @override
  RunwayStatus get getEventType => eventType;
}
