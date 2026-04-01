import 'package:air_traffic_sim/simulation/enums/emergency_status.dart';
import 'package:air_traffic_sim/simulation/implementations/aircraft.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Aircraft Tests', () {
    test('InboundAircraft consumes fuel correctly', () {
      final aircraft = InboundAircraft(
        id: 'A1', scheduledTime: 0, actualTime: 0, fuelLevel: 100,
      );

      aircraft.consumeFuel(10);
      expect(aircraft.getInitFuelLevel, 90);
    });

    test('InboundAircraft identifies emergencies', () {
      final normalAircraft = InboundAircraft(
        id: 'A1', scheduledTime: 0, actualTime: 0, fuelLevel: 100, status: EmergencyStatus.none
      );
      final emergencyAircraft = InboundAircraft(
        id: 'A2', scheduledTime: 0, actualTime: 0, fuelLevel: 100, status: EmergencyStatus.fuel
      );

      expect(normalAircraft.isEmergency(), isFalse);
      expect(emergencyAircraft.isEmergency(), isTrue);
    });

    test('OutboundAircraft never has an emergency', () {
      final outbound = OutboundAircraft(id: 'D1', scheduledTime: 0, actualTime: 0);
      expect(outbound.isEmergency(), isFalse);
    });
  });
}