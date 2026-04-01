import 'dart:collection';
import 'package:air_traffic_sim/simulation/implementations/report.dart';
import 'package:air_traffic_sim/simulation/concretes/simulation_stats.dart';
import 'package:air_traffic_sim/simulation/implementations/simulation_inputs.dart';
import 'package:air_traffic_sim/simulation/implementations/runway.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Report CSV Exporting', () {
    test('exportCSV correctly maps stats and inputs to CSV format', () {
      final stats = SimulationStats.empty();
      
      final inputs = SimulationInputs(
        runways: [LandingRunway(id: 1), TakeOffRunway(id: 2)],
        emergencyProbability: 0.15,
        events: Queue(),
        maxWaitTime: 60,
        minFuelThreshold: 30,
        duration: 1440,
        inboundRate: 20,
        outboundRate: 25,
      );

      final report = Report(stats: stats, inputs: inputs);
      final csvOutput = report.exportCSV();

      expect(csvOutput, contains('"Metric","Value"'));
      
      expect(csvOutput, contains('"Average Landing Delay","0.0"'));
      expect(csvOutput, contains('"Total Cancellations","0"'));

      expect(csvOutput, contains('"Inbound Rate","20"'));
      expect(csvOutput, contains('"Outbound Rate","25"'));
      expect(csvOutput, contains('"Emergency Probability","0.15"'));
      expect(csvOutput, contains('"Landing Runways","1"'));
      expect(csvOutput, contains('"Takeoff Runways","1"'));
    });
  });
}