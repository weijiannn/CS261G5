import 'package:flutter/material.dart';

import 'package:air_traffic_sim/simulation/enums/runway_mode.dart';
import 'package:air_traffic_sim/simulation/enums/runway_status.dart';
import 'package:air_traffic_sim/ui/models/realtime_dashboard_models.dart';
import 'package:air_traffic_sim/ui/utils/realtime_event_utils.dart';

/// UI-specific helpers attached to the shared simulation enums.
extension RunwayStatusUi on RunwayStatus {
  Color get borderColor {
    switch (this) {
      case RunwayStatus.available:
        return Colors.greenAccent.shade400;
      case RunwayStatus.occupied:
      case RunwayStatus.wait:
        return Colors.cyanAccent.shade400;
      case RunwayStatus.inspection:
      case RunwayStatus.snowClearance:
      case RunwayStatus.maintenance:
      case RunwayStatus.closure:
        return Colors.redAccent.shade400;
    }
  }

  String get uiLabel {
    switch (this) {
      case RunwayStatus.available:
        return 'AVAILABLE';
      case RunwayStatus.occupied:
        return 'IN USE';
      case RunwayStatus.wait:
        return 'WAITING';
      case RunwayStatus.inspection:
        return 'INSPECTION';
      case RunwayStatus.snowClearance:
        return 'SNOW CLEARANCE';
      case RunwayStatus.maintenance:
        // Surface as a generic "maintenance" window in the UI.
        return 'MAINTENANCE';
      case RunwayStatus.closure:
        return 'CLOSURE';
    }
  }
}

Color borderColorForRunwayStatus(RunwayStatus status) =>
    status.borderColor;

String labelForRunwayStatus(RunwayStatus status) => status.uiLabel;

String labelForRunwayOperatingMode(RunwayMode mode) {
  switch (mode) {
    case RunwayMode.landing:
      return 'LANDING';
    case RunwayMode.takeOff:
      return 'TAKE-OFF';
    case RunwayMode.mixed:
      return 'MIXED';
  }
}

/// Derive a runway's effective status from its events at [now].
RunwayStatus deriveRunwayStatusForRunway({
  required DashboardRunway runway,
  required Iterable<SimulationEvent> events,
  required DateTime now,
}) {
  final runwayEvents =
      events.where((event) => event.getRunwayId == runway.id);

  // If there is any active event for this runway, surface its status;
  // otherwise fall back to the default "available".
  for (final event in runwayEvents) {
    if (isEventActive(event, now)) {
      return event.type;
    }
  }

  return RunwayStatus.available;
}
