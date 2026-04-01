import 'dart:collection';

import 'package:air_traffic_sim/simulation/concretes/simulation_stats.dart';
import 'package:air_traffic_sim/simulation/exceptions/corrupt_csv_exception.dart';
import 'package:air_traffic_sim/simulation/implementations/report.dart';
import 'package:air_traffic_sim/simulation/implementations/simulation_inputs.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Importing and exporting scenario data', () {
    final inputs = SimulationInputs(
      runways: const [],
      emergencyProbability: 0.1,
      events: Queue(),
      maxWaitTime: 10,
      minFuelThreshold: 5,
      duration: 60,
      outboundRate: 8,
      inboundRate: 6,
    );

    test('Export valid data to a CSV string', () {
      final stats = SimulationStats(
        averageLandingDelay: 1.1,
        averageDepartureDelay: 1.2,
        averageHoldTime: 1.3,
        averageWaitTime: 1.4,
        sectionAverageDepartureDelayList: List<double>.filled(3, 1.5, growable: true),
        sectionAverageLandingDelayList: List<double>.filled(3, 1.6, growable: true),
        maxLandingDelay: 1,
        maxDepartureDelay: 2,
        maxInboundQueue: 3,
        maxOutboundQueue: 4,
        totalCancellations: 0,
        totalDiversions: 6,
        totalLandingAircraft: 5,
        totalDepartingAircraft: 7,
        runwayUtilisation: 0.5,
      );
      final report = Report(stats: stats, inputs: inputs);
      final csv = report.exportCSV();

      expect(csv, contains('"Average Landing Delay","1.1"'));
      expect(csv, contains('"Inbound Rate","6"'));
    });

    test('Import valid data from a CSV string', () {
      final report = Report(stats: SimulationStats.empty(), inputs: inputs);
      report.importCSV(report.exportCSV());

      expect(report.getStats.averageLandingDelay, 0.0);
      expect(report.getInputs.getInboundRate, 6);
    });

    test('Import invalid data from a CSV string', () {
      const csv = 'bad,csv';
      final report = Report(stats: SimulationStats.empty(), inputs: inputs);
      expect(() => report.importCSV(csv), throwsA(isA<CorruptCsvException>()));
    });
  });
}
