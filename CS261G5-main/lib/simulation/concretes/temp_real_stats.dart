import 'package:air_traffic_sim/simulation/concretes/temp_stats.dart';

class TempRealStats extends TempStats {
  static const double alpha = 0.1; // Smoothing factor 0<=[alpha]<=1. Higher value increases weighting of new values .
  double? _emAverageLandingDelay;
  double? _emAverageDepatureDelay;

  int currInboundQueueLength = 0;
  int currOutboundQueueLength = 0;
  int currEmergencyCount = 0;

  // Return 0 if null. Used to set first value to the average.
  double get emAverageLandingDelay => _emAverageLandingDelay ?? 0.0;
  double get emAverageDepartureDelay => _emAverageDepatureDelay ?? 0.0;


  /// updates exponential moving average for landing aircraft
  void updateLandingMovingAverage(int delay) {
    if (_emAverageLandingDelay != null) { // if not the first data point, apply the exponential moving average
      _emAverageLandingDelay = alpha * delay + (1 - alpha) * emAverageLandingDelay;
    } else {
      _emAverageLandingDelay = delay.toDouble();
    }
  }
  /// updates exponential moving average for departing aircraft
  void updateDepartureMovingAverage(int delay) {
    if (_emAverageDepatureDelay != null) { // if not the first data point, apply the exponential moving average
      _emAverageDepatureDelay = alpha * delay + (1 - alpha) * emAverageDepartureDelay;
    } else {
      _emAverageDepatureDelay = delay.toDouble();
    }
  }
}