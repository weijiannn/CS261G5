import 'package:air_traffic_sim/simulation/enums/runway_mode.dart';
import 'package:air_traffic_sim/simulation/enums/runway_status.dart';

import 'i_aircraft.dart';

/// Interface for runways.
abstract class IRunway {

  /// Returns the mode of the runway, optionally declaring whether an emergency is present to consider.
  RunwayMode mode({bool emergency, bool takeOffEmpty, bool holdingEmpty});

  /// Assigns the [aircraft] to the runway - updating the runway's status to [RunwayStatus.occupied] and
  /// setting the next available time appropriately.
  void assignAircraft(IAircraft aircraft);

  /// Attempts to close this runway for the specified [duration] (>0) with the status [newStatus] which
  /// should not be [RunwayStatus.available] or [RunwayStatus.occupied].
  void closeRunway(int duration, RunwayStatus newStatus);

  /// Sets the status of the runway to [RunwayStatus.available].
  /// Optionally may provide this functionallity based on condition checks.
  void open([int setback = 0]);

  RunwayStatus updateStatus();

  /// Getters 
  
  int get id;
  int get length;
  int get bearing;
  RunwayStatus get status;
  int get nextAvailable;
  bool get isAvailable;
}