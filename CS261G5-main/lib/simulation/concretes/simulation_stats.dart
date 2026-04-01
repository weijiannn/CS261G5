import 'package:air_traffic_sim/simulation/concretes/temp_stats.dart';
import 'package:air_traffic_sim/simulation/implementations/rate_parameters.dart';

/// Stores the metrics of a simulation
class SimulationStats {
  // Output metrics.
  final double averageLandingDelay;
  final double averageHoldTime;
  final List<double> sectionAverageLandingDelayList;
  final double averageDepartureDelay;
  final double averageWaitTime;
  final List<double> sectionAverageDepartureDelayList;
  final int maxLandingDelay;
  final int maxDepartureDelay;
  final int maxInboundQueue;
  final int maxOutboundQueue;
  final int totalCancellations;
  final int totalDiversions;
  final int totalLandingAircraft;
  final int totalDepartingAircraft;
  final double runwayUtilisation;

  int get totalAircraft => totalLandingAircraft + totalDepartingAircraft + totalDiversions + totalCancellations;

  const SimulationStats({
    required this.averageLandingDelay, 
    required this.averageHoldTime,
    required this.sectionAverageLandingDelayList,
    required this.averageDepartureDelay, 
    required this.averageWaitTime,
    required this.sectionAverageDepartureDelayList,
    required this.maxLandingDelay,
    required this.maxDepartureDelay,
    required this.maxInboundQueue,
    required this.maxOutboundQueue,
    required this.totalCancellations,
    required this.totalDiversions,
    required this.totalLandingAircraft,
    required this.totalDepartingAircraft,
    required this.runwayUtilisation,
  });

  SimulationStats.aggr(TempStats s, RateParameters params) :
    // Output metrics.
    averageLandingDelay = s.landingAircraftCount > 0 ? s.totalLandingDelay / s.landingAircraftCount : 0,
    averageHoldTime = (s.landingAircraftCount + s.totalDiversions) > 0 ? s.totalHoldTime / (s.landingAircraftCount + s.totalDiversions) : 0,
    sectionAverageLandingDelayList = s.sectionAverageLandingDelayList,
    averageDepartureDelay = s.departingAircraftCount > 0 ? s.totalDepartureDelay / s.departingAircraftCount : 0,
    averageWaitTime = (s.departingAircraftCount + s.totalCancellations) > 0 ? s.totalWaitTime / (s.departingAircraftCount + s.totalCancellations) : 0,
    sectionAverageDepartureDelayList = s.sectionAverageDepartureDelayList,
    maxLandingDelay = s.maxLandingDelay,
    maxDepartureDelay = s.maxDepartureDelay,
    maxInboundQueue = s.maxInboundQueue,
    maxOutboundQueue = s.maxOutboundQueue,
    totalCancellations = s.totalCancellations,
    totalDiversions = s.totalDiversions,
    totalDepartingAircraft = s.departingAircraftCount,
    totalLandingAircraft = s.landingAircraftCount,
    runwayUtilisation = s.maximumPossibleRunwayUsage > 0 ? s.totalRunwayUsage / s.maximumPossibleRunwayUsage : 0;
  

  factory SimulationStats.empty() {
    return SimulationStats(
      // Output metrics.
      averageLandingDelay: 0.0, 
      averageHoldTime: 0.0,
      sectionAverageLandingDelayList: List<double>.empty(growable: true),
      averageDepartureDelay: 0.0, 
      averageWaitTime: 0.0,
      sectionAverageDepartureDelayList: List<double>.empty(growable: true),
      maxLandingDelay: 0, 
      maxDepartureDelay: 0,
      maxInboundQueue: 0,
      maxOutboundQueue: 0,
      totalCancellations: 0,
      totalDiversions: 0,
      totalDepartingAircraft: 0, 
      totalLandingAircraft: 0,
      runwayUtilisation: 0,
    );
  }
}