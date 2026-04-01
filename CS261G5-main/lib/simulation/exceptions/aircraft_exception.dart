/// Extend for any specific exceptions regarding aircraft.
abstract class AircraftException implements Exception {
  String? cause;
  int schedule;
  AircraftException(this.schedule, [this.cause]);
}