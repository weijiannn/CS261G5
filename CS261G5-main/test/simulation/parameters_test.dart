import 'dart:collection';
import 'package:air_traffic_sim/simulation/implementations/parameters.dart';
import 'package:air_traffic_sim/simulation/implementations/runway.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Parameters Validation', () {
    test('Throws ArgumentError if runway IDs are not unique', () {
      final duplicateRunways = [
        LandingRunway(id: 1),
        TakeOffRunway(id: 1), // Duplicate ID
      ];

      expect(
        () => Parameters(
          runways: duplicateRunways,
          emergencyProbability: 0.05,
          events: Queue(),
          maxWaitTime: 60,
          minFuelThreshold: 30,
          duration: 1440,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('Creates successfully with unique runway IDs', () {
      final uniqueRunways = [
        LandingRunway(id: 1),
        TakeOffRunway(id: 2),
      ];

      expect(
        () => Parameters(
          runways: uniqueRunways,
          emergencyProbability: 0.05,
          events: Queue(),
          maxWaitTime: 60,
          minFuelThreshold: 30,
          duration: 1440,
        ),
        returnsNormally,
      );
    });
  });
}