import 'package:air_traffic_sim/simulation/enums/emergency_status.dart';
import 'package:air_traffic_sim/simulation/interfaces/i_aircraft.dart';

class OutboundAircraft implements IAircraft {
  final String _id;
  final int _scheduledTime;
  final int _actualTime;

  OutboundAircraft({
    required String id,
    required int scheduledTime,
    required int actualTime,
  })  : _id = id,
        _scheduledTime = scheduledTime,
        _actualTime = actualTime;

  @override
  String get getId => _id;

  @override
  int get getScheduledTime => _scheduledTime;

  @override
  int get getActualTime => _actualTime;

  // Outbound aircrafts in this specific architecture do not generate emergencies.
  @override
  bool isEmergency() => false;

  // --- Unimplemented / Not Applicable for Base Outbound ---
  
  @override
  int get getInitFuelLevel => throw UnimplementedError("Fuel level not tracked for Outbound Aircraft");

  @override
  EmergencyStatus get getStatus => throw UnimplementedError("No emergencies for Outbound Aircraft");

  @override
  String get getOperator => throw UnimplementedError();

  @override
  String get getOrigin => throw UnimplementedError();

  @override
  String get getDestination => throw UnimplementedError();

  @override
  int get getAltitude => throw UnimplementedError("Altitude not tracked for Outbound Aircraft");

  @override
  void consumeFuel(int amount) => throw UnimplementedError("Outbound aircraft do not track fuel");
}


class InboundAircraft extends OutboundAircraft {
  int _fuelLevel;
  EmergencyStatus _status;

  InboundAircraft({
    required super.id,
    required super.scheduledTime,
    required super.actualTime,
    required int fuelLevel,
    EmergencyStatus status = EmergencyStatus.none,
  })  : _fuelLevel = fuelLevel,
        _status = status;

  @override
  int get getInitFuelLevel => _fuelLevel;

  @override
  EmergencyStatus get getStatus => _status;

  @override
  bool isEmergency() => _status != EmergencyStatus.none;

  @override
  void consumeFuel(int amount) => _fuelLevel -= amount;

  void setEmergencyStatus(EmergencyStatus newStatus) => _status = newStatus;
}


class RAircraft extends InboundAircraft {
  final String _operator;
  final String _origin;
  final String _destination;
  int _altitude;

  RAircraft({
    required super.id,
    required super.scheduledTime,
    required super.actualTime,
    required super.fuelLevel,
    super.status,
    required String flightOperator,
    required String origin,
    required String destination,
    required int altitude,
  })  : _operator = flightOperator,
        _origin = origin,
        _destination = destination,
        _altitude = altitude;

  @override
  String get getOperator => _operator;

  @override
  String get getOrigin => _origin;

  @override
  String get getDestination => _destination;

  @override
  int get getAltitude => _altitude;

  void updateAltitude(int newAltitude) => _altitude = newAltitude;
}