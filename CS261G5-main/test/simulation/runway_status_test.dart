import 'package:air_traffic_sim/simulation/enums/runway_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RunwayStatus Enum Tests', () {
    test('fromString converts exact strings to enums', () {
      expect(RunwayStatus.fromString("Available"), RunwayStatus.available);
      expect(RunwayStatus.fromString("Occupied"), RunwayStatus.occupied);
      expect(RunwayStatus.fromString("Snow Clearance"), RunwayStatus.snowClearance);
    });

    test('fromString throws error on unknown string', () {
      expect(
        () => RunwayStatus.fromString("Aliens Invaded"), 
        throwsArgumentError
      );
    });

    test('allNames returns correct list size', () {
      expect(RunwayStatus.allNames.length, 7);
    });
  });
}