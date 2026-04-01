import 'package:flutter_test/flutter_test.dart';
import 'package:air_traffic_sim/simulation/concretes/temp_real_stats.dart';

void main() {
  group('TempRealStats Math Tests', () {
    test('Calculates exponential moving average correctly for landings', () {
      final stats = TempRealStats();
      
      stats.updateLandingMovingAverage(10);
      expect(stats.emAverageLandingDelay, 10.0);

      stats.updateLandingMovingAverage(20);
      expect(stats.emAverageLandingDelay, 11.0);
    });
  });
}