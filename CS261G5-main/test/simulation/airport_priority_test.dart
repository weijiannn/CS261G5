import 'package:flutter_test/flutter_test.dart';
import 'package:air_traffic_sim/simulation/implementations/airport.dart';
import 'package:air_traffic_sim/simulation/implementations/aircraft.dart';
import 'package:air_traffic_sim/simulation/enums/emergency_status.dart';

void main() {
  group('Airport Holding Pattern Tests', () {
    test('Holding pattern prioritizes emergency aircraft', () {
      final airport = Airport([]); // Empty runways for this test
      
      final normalAircraft = InboundAircraft(
        id: '1', scheduledTime: 10, actualTime: 10, fuelLevel: 100,
      );
      
      final emergencyAircraft = InboundAircraft(
        id: '2', scheduledTime: 20, actualTime: 20, fuelLevel: 50,
        status: EmergencyStatus.mechanical,
      );

      // Add normal first, then emergency
      airport.addToHolding(normalAircraft);
      airport.addToHolding(emergencyAircraft);

      // The emergency aircraft should be popped first despite a later scheduled time
      final firstOut = airport.firstInHolding;
      expect(firstOut.getId, '2');
      expect(firstOut.isEmergency(), isTrue);
    });
  });
}