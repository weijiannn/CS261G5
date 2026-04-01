import 'package:air_traffic_sim/simulation/concretes/temp_real_stats.dart';
import 'package:air_traffic_sim/simulation/enums/runway_mode.dart';
import 'package:air_traffic_sim/simulation/enums/runway_status.dart';
import 'package:air_traffic_sim/simulation/implementations/aircraft.dart';
import 'package:air_traffic_sim/simulation/implementations/rate_parameters.dart';
import 'package:air_traffic_sim/simulation/implementations/runway.dart';
import 'package:air_traffic_sim/simulation/implementations/runway_event.dart';
import 'package:air_traffic_sim/simulation/interfaces/i_aircraft.dart';
import 'package:air_traffic_sim/ui/screens/real_time.dart';

class DashboardRunway extends AbstractRunway{
  final String name;
  final RunwayMode operatingMode;
  bool _isTakeOff = true;

  DashboardRunway({
    required this.name,
    required this.operatingMode,
    required super.id
  });
  
  String get idAsString => "RWY-${super.id}";

  @override
  void assignAircraft(IAircraft aircraft){
    if ((operatingMode == RunwayMode.landing && aircraft is! InboundAircraft) ||
        (operatingMode == RunwayMode.takeOff && aircraft is InboundAircraft)) {
      throw ArgumentError('Aircraft type does not match runway mode');
    }
    
    if (operatingMode == RunwayMode.mixed){
      _isTakeOff = aircraft is InboundAircraft;
    }

    super.assignAircraft(aircraft);
  }

  @override
  RunwayMode mode({bool emergency=false, bool takeOffEmpty=false, bool holdingEmpty=false}) {
    if (operatingMode == RunwayMode.mixed){
      // Emergency logic: always prioritize landing if needed
      if (emergency || takeOffEmpty) {
        return RunwayMode.landing;
      } else if (holdingEmpty || _isTakeOff) {
        return RunwayMode.takeOff;
      }
      return RunwayMode.landing;
    }
    
    return operatingMode;
  }
}

/// Event instance used by the dashboard.
class SimulationEvent extends RunwayEvent {
  final String id;
  DateTime dtStartTime;
  Duration duration;

  /// Event end time. If null, it is derived from [startTime] + [duration].
  ///
  /// When cancelling an active event we explicitly change [duration] to
  /// the elapsed time since the event started, to allow for persistence symmetry with ended events.
  SimulationEvent({
    required this.id,
    required super.runwayId,
    required super.eventType,
    required this.dtStartTime,
    required this.duration,
  }) : super(startTime:_toSimulationMinutes(dtStartTime), duration: duration.inMinutes);

  /// Underlying simulation event type.
  RunwayStatus get type => getEventType;

  DateTime get endTime => dtStartTime.add(duration);
  int get endTimeInMinutes => startTime + getDuration;

  set dur(Duration duration){
    this.duration = duration;
    super.setDur = duration.inMinutes;
  }

  @override
  set startTime(int newStartTime) {
    super.startTime = newStartTime;
    dtStartTime = defaultClockStartTime.add(Duration(minutes: newStartTime));
  }

  static int _toSimulationMinutes(DateTime time) {
    return time.difference(defaultClockStartTime).inMinutes;
  }
}

/// Metric entry rendered inside the Live Metrics card.
class LiveMetricEntry {
  final String label;
  final String value;
  final List<double>? sparklinePoints;

  const LiveMetricEntry({
    required this.label,
    required this.value,
    this.sparklinePoints,
  });
}

/// Helper to project the configuration inputs into user-friendly metrics.
List<LiveMetricEntry> buildInputMetricsFromConfiguration({
  required int inboundRate,
  required int outboundRate,
  required double emergencyProb,
  required int maxOutboundWait,
  required int fuelDiversionThreshold,
  required String distribution
}) {
  final emergencyLabel = '${(emergencyProb*100).toStringAsFixed(1)}%';

  return <LiveMetricEntry>[
    LiveMetricEntry(
      label: 'Distribution',
      value: distribution
    ),
    LiveMetricEntry(
      label: 'Inbound Rate',
      value: '$inboundRate aircraft/hour',
    ),
    LiveMetricEntry(
      label: 'Outbound Rate',
      value: '$outboundRate aircraft/hour',
    ),
    LiveMetricEntry(
      label: 'Emergency Probability',
      value: emergencyLabel,
    ),
    LiveMetricEntry(
      label: 'Max Outbound Wait',
      value: '${maxOutboundWait.toString()} min',
    ),
    LiveMetricEntry(
      label: 'Fuel Diversion Threshold',
      value: '${fuelDiversionThreshold.toString()} min',
    ),
  ];
}

/// Helper to project a [TempRealStats] instance into user-friendly metrics.
List<LiveMetricEntry> buildLiveMetricsFromTempRealStats(
  TempRealStats s,
) {
    final averageLandingDelay = s.landingAircraftCount > 0 ? s.totalLandingDelay / s.landingAircraftCount : 0;
    final averageHoldTime = (s.landingAircraftCount + s.totalDiversions) > 0 ? s.totalHoldTime / (s.landingAircraftCount + s.totalDiversions) : 0;
    final averageDepartureDelay = s.departingAircraftCount > 0 ? s.totalDepartureDelay / s.departingAircraftCount : 0;
    final averageWaitTime = (s.departingAircraftCount + s.totalCancellations) > 0 ? s.totalWaitTime / (s.departingAircraftCount + s.totalCancellations) : 0;
    final runwayUtilisation = s.maximumPossibleRunwayUsage > 0 ? 100 * s.totalRunwayUsage / s.maximumPossibleRunwayUsage : 0;

  return <LiveMetricEntry>[
    LiveMetricEntry(
      label: 'Max Landing Delay',
      value: '${s.maxLandingDelay} min',
    ),
    LiveMetricEntry(
      label: 'Max Departure Delay',
      value: '${s.maxDepartureDelay} min',
    ),
    LiveMetricEntry(
      label: 'Max Inbound Queue Size',
      value: s.maxInboundQueue.toString(),
    ),
    LiveMetricEntry(
      label: 'Max Outbound Queue Size',
      value: s.maxOutboundQueue.toString(),
    ),
    LiveMetricEntry(
      label: 'Average Landing Delay',
      value: '${averageLandingDelay.toStringAsFixed(1)} min',
    ),
    LiveMetricEntry(
      label: 'Weighted Average Landing Delay',
      value: '${s.emAverageLandingDelay.toStringAsFixed(1)} min',
    ),
    LiveMetricEntry(
      label: 'Average Hold Time',
      value: '${averageHoldTime.toStringAsFixed(1)} min',
    ),
    LiveMetricEntry(
      label: 'Average Departure Delay',
      value: '${averageDepartureDelay.toStringAsFixed(1)} min',
    ),
    LiveMetricEntry(
      label: 'Weighted Average Departure Delay',
      value: '${s.emAverageDepartureDelay.toStringAsFixed(1)} min',
    ),
    LiveMetricEntry(
      label: 'Average Wait Time',
      value: '${averageWaitTime.toStringAsFixed(1)} min',
    ),
    LiveMetricEntry(
      label: 'Total Aircraft Count',
      value: s.totalAircraft.toString(),
    ),
    LiveMetricEntry(
      label: 'Total Cancellations',
      value: s.totalCancellations.toString(),
    ),
    LiveMetricEntry(
      label: 'Total Diversions',
      value: s.totalDiversions.toString(),
    ),
    LiveMetricEntry(
      label: 'Landed Aircraft Count',
      value: s.landingAircraftCount.toString(),
    ),
    LiveMetricEntry(
      label: 'Departed Aircraft Count',
      value: s.departingAircraftCount.toString(),
    ),
    LiveMetricEntry(
      label: 'Overall Runway Utilisation',
      value: '${runwayUtilisation.toStringAsFixed(1)}%',
    ),
  ];
}

class RealTimeScreenArguments extends RateParameters{
  String distribution;
  RealTimeScreenArguments({
    required List<DashboardRunway> runways,
    required List<SimulationEvent> events,
    required super.inboundRate,
    required super.outboundRate,
    required super.emergencyProbability,
    required super.maxWaitTime,
    required super.minFuelThreshold,
    required this.distribution
  }) : super(
    runways: runways,
    events: events,
    duration: 0x7FFFFFFFFFFFFFFF
  );

  @override
  List<DashboardRunway> get getRunways => super.getRunways as List<DashboardRunway>;

  @override
  List<SimulationEvent> get getEvents => super.getEvents as List<SimulationEvent>;
}
