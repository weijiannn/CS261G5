import 'dart:collection';
import 'package:flutter_test/flutter_test.dart';
import 'package:air_traffic_sim/simulation/abstracts/generative_controller.dart';
import 'package:air_traffic_sim/simulation/mixins/uniform_generator.dart';
import 'package:air_traffic_sim/simulation/interfaces/i_rate_parameters.dart';
import 'package:air_traffic_sim/simulation/implementations/rate_parameters.dart';

// Create a mock controller to test the mixin
class MockUniformController extends GenerativeController with UniformGenerator {
  MockUniformController(IRateParameters p) : super(p);
  
  // Expose init for testing
  void testInit(int inb, int outb) => init(inb, outb);
}

void main() {
  group('UniformGenerator Boundary Tests', () {
    test('Throws ArgumentError when rates are out of bounds', () {
      
      final dummyParams = RateParameters(
        runways: [],
        emergencyProbability: 0.0,
        events: Queue(),
        maxWaitTime: 10,
        minFuelThreshold: 10,
        duration: 60,
        inboundRate: 10,
        outboundRate: 10,
      );

      final generator = MockUniformController(dummyParams);

      expect(() => generator.testInit(1000, 50), throwsArgumentError);
      
      expect(() => generator.testInit(50, -1), throwsArgumentError);
    });
  });
}