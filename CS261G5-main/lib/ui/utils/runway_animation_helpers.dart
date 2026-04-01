import 'package:air_traffic_sim/ui/screens/real_time.dart';

typedef RunwayAnimationTrigger = void Function(Duration simDuration);

/// Lightweight registry used to trigger runway animations by ID from
/// outside the widget tree.
class RunwayAnimationManager {
  final Map<int, RunwayAnimationTrigger> _startTakeoffTriggers =
      <int, RunwayAnimationTrigger>{};
  final Map<int, RunwayAnimationTrigger> _startLandingTriggers =
      <int, RunwayAnimationTrigger>{};
  final Map<int, RunwayAnimationTrigger> _stopTriggers =
      <int, RunwayAnimationTrigger>{};

  Duration simDuration = const Duration(milliseconds: defaultTPeriodms);

  void registerRunway({
    required int runwayId,
    required RunwayAnimationTrigger startTakeoff,
    required RunwayAnimationTrigger startLanding,
    required RunwayAnimationTrigger stop,
  }) {
    _startTakeoffTriggers[runwayId] = startTakeoff;
    _startLandingTriggers[runwayId] = startLanding;
    _stopTriggers[runwayId] = stop;
  }

  void unregisterRunway(int runwayId) {
    _startTakeoffTriggers.remove(runwayId);
    _startLandingTriggers.remove(runwayId);
    _stopTriggers.remove(runwayId);
  }

  /// Start a take-off animation on the given runway, if registered.
  void startTakeoffAnimation(int runwayId) {
    final trigger = _startTakeoffTriggers[runwayId];
    if (trigger != null) {
      trigger(simDuration);
    }
  }

  /// Start a landing animation on the given runway, if registered.
  void startLandingAnimation(int runwayId) {
    final trigger = _startLandingTriggers[runwayId];
    if (trigger != null) {
      trigger(simDuration);
    }
  }

  /// Stop any active animation on the given runway, if registered.
  void stopRunwayAnimation(int runwayId) {
    final trigger = _stopTriggers[runwayId];
    if (trigger != null) {
      trigger(const Duration());
    }
  }
}

