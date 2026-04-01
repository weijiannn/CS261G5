import 'i_runway.dart';
import 'i_runway_event.dart';

/// Interface for obtaining entered parameters for a general simulation.
abstract class IParameters {

  /// Getters
  
  List<IRunway> get getRunways;
  double get getEmergencyProbability;
  Iterable<IRunwayEvent> get getEvents;
  int get getMaxWaitTime;
  int get getMinFuelThreshold;
  int get getDuration;

  int get getLandingRunwayCount;
  int get getTakeoffRunwayCount;
  int get getMixedRunwayCount;
}