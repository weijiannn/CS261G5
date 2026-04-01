import 'package:air_traffic_sim/simulation/enums/emergency_status.dart';
import 'package:air_traffic_sim/simulation/implementations/aircraft.dart';

RAircraft buildLandingAircraft({
  required String id,
  required int scheduledTime,
  int? actualTime,
  int fuelLevel = 10,
  EmergencyStatus status = EmergencyStatus.none,
  String flightOperator = 'TEST',
  String origin = 'AAA',
  String destination = 'BBB',
  int altitude = 3000,
}) {
  return RAircraft(
    id: id,
    scheduledTime: scheduledTime,
    actualTime: actualTime ?? scheduledTime,
    fuelLevel: fuelLevel,
    status: status,
    flightOperator: flightOperator,
    origin: origin,
    destination: destination,
    altitude: altitude,
  );
}

OutboundAircraft buildTakeoffAircraft({
  required String id,
  required int scheduledTime,
  int? actualTime,
}) {
  return OutboundAircraft(
    id: id,
    scheduledTime: scheduledTime,
    actualTime: actualTime ?? scheduledTime,
  );
}
