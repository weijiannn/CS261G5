import 'dart:collection';
import 'package:air_traffic_sim/simulation/concretes/poisson_sim_controller.dart';
import 'package:air_traffic_sim/simulation/concretes/uniform_sim_controller.dart';
import 'package:air_traffic_sim/simulation/implementations/rate_parameters.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Simulation Controllers Rate Validation', () {
    RateParameters createParamsWithRates(int inbound, int outbound) {
      return RateParameters(
        runways: [],
        emergencyProbability: 0.1,
        events: Queue(),
        maxWaitTime: 60,
        minFuelThreshold: 30,
        duration: 1440,
        inboundRate: inbound,
        outboundRate: outbound,
      );
    }

    test('Poisson Controller throws ArgumentError on out-of-bounds rates', () {
      final badInboundParams = createParamsWithRates(1001, 60); // Max is 1000
      final badOutboundParams = createParamsWithRates(60, -10); // Min is 1

      expect(() => PoissonSimulationController(badInboundParams), throwsArgumentError);
      expect(() => PoissonSimulationController(badOutboundParams), throwsArgumentError);
    });

    test('Uniform Controller throws ArgumentError on out-of-bounds rates', () {
      final badInboundParams = createParamsWithRates(1500, 60);
      
      expect(() => UniformSimulationController(badInboundParams), throwsArgumentError);
    });
  });
}