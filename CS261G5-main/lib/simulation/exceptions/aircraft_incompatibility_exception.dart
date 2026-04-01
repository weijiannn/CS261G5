import 'aircraft_exception.dart';

/// Use when there is some incompatibility in landing/taking off aircraft.
class AircraftIncompatibilityException extends AircraftException{
  AircraftIncompatibilityException(super.schedule, [super.cause]);
}