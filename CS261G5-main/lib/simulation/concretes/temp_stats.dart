/// Wrapper class for temporary aggregation of metrics duration the simulation run.
class TempStats {
  /// 1-1 with [SimulationStats] attributes.
  int maxLandingDelay = 0;
  int maxDepartureDelay = 0;
  int maxInboundQueue = 0;
  int maxOutboundQueue = 0;
  int totalCancellations = 0;
  int totalDiversions = 0;
  int landingAircraftCount = 0;
  int departingAircraftCount = 0;
  List<double> sectionAverageLandingDelayList = List<double>.empty(growable: true);
  List<double> sectionAverageDepartureDelayList = List<double>.empty(growable: true);
  /// Distinct from [SimulationStats] attributes.
  int totalLandingDelay = 0;
  int totalSectionLandingDelay = 0;
  int totalHoldTime = 0;
  int totalDepartureDelay = 0;
  int totalSectionDepartureDelay = 0;
  int totalWaitTime = 0;
  int sectionLandingAircraftCount = 0;
  int sectionDepartingAircraftCount = 0;
  int totalRunwayUsage = 0;
  int maximumPossibleRunwayUsage = 0;

  int get totalAircraft => landingAircraftCount + departingAircraftCount + totalDiversions + totalCancellations;

  // Variables to handle section delay.
  int _counter = 0;           // Number of intervals in current section.
  static const int _sectionSize = 10; // The section size.

  /// Updates the section average accumulation.
  void updateSectionAverage() {
      if (++_counter >= _sectionSize) { // If end of section has been reached.
        // Add the section's delays to the lists.
        sectionAverageLandingDelayList.add(
          sectionLandingAircraftCount == 0
              ? 0.0
              : totalSectionLandingDelay / sectionLandingAircraftCount,
        );
        sectionAverageDepartureDelayList.add(
          sectionDepartingAircraftCount == 0
              ? 0.0
              : totalSectionDepartureDelay / sectionDepartingAircraftCount,
        );
        // Reset the summations and counts.
        totalSectionDepartureDelay = 0;
        totalSectionLandingDelay = 0;
        sectionDepartingAircraftCount = 0;
        sectionLandingAircraftCount = 0;
        // Reset the counter.
        _counter = 0;
      }

    }
}
