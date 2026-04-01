import 'package:air_traffic_sim/simulation/enums/runway_status.dart';

abstract class IRunwayEvent {

  /// Getters
  
  int get getRunwayId;
  int get getStartTime;
  int get getDuration;
  /// Should not be [RunwayStatus.available] or [RunwayStatus.occupied].
  RunwayStatus get getEventType;
}