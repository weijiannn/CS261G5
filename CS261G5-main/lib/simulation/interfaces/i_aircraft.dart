import 'package:air_traffic_sim/simulation/enums/emergency_status.dart';

/// Interface for all aircraft.
abstract class IAircraft {
  /// Returns whether the aircraft has an emergency of any kind.
  bool isEmergency();

  /// Getters for a general aircraft (not all need be implemented).
  
  /// All aircraft must have these.
  
  String get getId;
  int get getScheduledTime;
  int get getActualTime;

  /// Landing aircraft must have these.
  
  int get getInitFuelLevel;
  EmergencyStatus get getStatus;
  void consumeFuel(int fuel);

  /// General aircraft information.
  
  String get getOperator;
  String get getOrigin;
  String get getDestination;
  int get getAltitude;
}