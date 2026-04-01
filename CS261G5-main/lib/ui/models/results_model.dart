class SimulationResults {
  final double averageLandingDelay;
  final double averageHoldTime;
  final double averageDepartureDelay;
  final double averageWaitTime;

  final int maximumLandingDelay;
  final int maximumDepartureDelay;

  final int maximumInboundQueueSize;
  final int maximumOutboundQueueSize;

  final int totalCancellations;
  final int totalDiversions;

  final int totalLandingAircraft;
  final int totalDepartingAircraft;

  final double runwayUtilisationPercentage;

  final List<double> landingDelaySeries;
  final List<double> departureDelaySeries;

  final Map<String, dynamic> inputConfig;

  const SimulationResults({
    required this.averageLandingDelay,
    required this.averageHoldTime,
    required this.averageDepartureDelay,
    required this.averageWaitTime,
    required this.maximumLandingDelay,
    required this.maximumDepartureDelay,
    required this.maximumInboundQueueSize,
    required this.maximumOutboundQueueSize,
    required this.totalCancellations,
    required this.totalDiversions,
    required this.totalLandingAircraft,
    required this.totalDepartingAircraft,
    required this.runwayUtilisationPercentage,
    required this.inputConfig,
    this.landingDelaySeries = const [],
    this.departureDelaySeries = const [],
  });
}