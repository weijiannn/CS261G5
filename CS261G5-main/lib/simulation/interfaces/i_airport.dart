import 'package:air_traffic_sim/simulation/enums/runway_status.dart';
import 'package:air_traffic_sim/simulation/enums/aircraft_type.dart';

import 'i_aircraft.dart';
import 'i_runway.dart';

import 'package:air_traffic_sim/simulation/exceptions/aircraft_incompatibility_exception.dart';

/// Interface defining Airport operations.
abstract class IAirport {
  /// Methods relating to holding pattern and take-off queue checks.

  /// Throws an [AircraftIncompatibilityException] if [aircraft] is not of type [AircraftType.landing].
  void addToHolding(IAircraft aircraft); 

  /// Throws an [AircraftIncompatibilityException] if [aircraft] is not of type [AircraftType.takeOff].
  void addToTakeOff(IAircraft aircraft); 

  /// Attempts to make use of a runway specified by [id] by assigning it an aircraft from the holding pattern/take-off queue 
  /// depending on whether the runway is in [RunwayMode.landing]/[RunwayMode.takeOff] respectively.
  /// [emergency] (optional) should specify whether there exists an aircraft with some emergency status in the holding pattern. 
  /// This is needed for the mixed runway type checks.
  /// 
  /// Throws some [RunwayException] in the case that the runway is not available, or if the runway does not exist.
  /// 
  /// Returns the delay of the aircraft that was assigned (negative if it ended up early).
  int useRunway(int id, bool emergency); 

  /// Searches through and diverts (effectively removing from the queue) all aircraft in the holding pattern with fuel levels 
  /// less than or equal to [fuelThreshold]. [fuelThreshold] must be strictly greater than 0.
  /// 
  /// Returns a list of all diverted aircraft.
  List<IAircraft> divert(int fuelThreshold);

  /// Searches through and cancels (effectively removing from the queue) all aircraft in the take-off queue with delays 
  /// greater than or equal to [waitTime]. [waitTime] must be strictly greater than 0.
  /// 
  /// Returns a list of all cancelled aircraft.
  List<IAircraft> cancel(int waitTime);

  /// Updates the statuses of all aircrafts and runways - e.g. decrements fuel levels, sets altitudes, or sets runways
  /// back to [RunwayStatus.available] once an event is over. 
  /// SHOULD ONLY BE CALLED ONCE PER TICK FOR RELIABLE RESULTS.
  void update();

  /// Getters

  IRunway? getRunway(int id); 
  List<IRunway> get getRunways; 

  /// Returns the next aircraft scheduled to land/take-off, removing them from their
  /// respective queues.
  IAircraft get firstInHolding;
  IAircraft get firstInTakeOff;

  int get getHoldingCount;
  int get getTakeOffCount;

  bool get isHoldingEmpty => (getHoldingCount == 0); 
  bool get isTakeOffEmpty => (getTakeOffCount == 0); 

  bool get hasEmergency;
}