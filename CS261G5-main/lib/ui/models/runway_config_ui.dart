import 'package:air_traffic_sim/simulation/enums/runway_mode.dart';
import 'package:air_traffic_sim/simulation/enums/runway_status.dart';
import 'package:air_traffic_sim/simulation/implementations/runway.dart';
import 'package:air_traffic_sim/simulation/implementations/runway_event.dart';
import 'package:air_traffic_sim/simulation/interfaces/i_runway.dart';
import 'package:air_traffic_sim/simulation/interfaces/i_runway_event.dart';
import 'package:flutter/material.dart';

class RunwayEventUI {
  String type;
  TextEditingController startController;
  TextEditingController durationController;

  RunwayEventUI({
    String? type,
  })  : type = type ?? RunwayStatus.inspection.name,
        startController = TextEditingController(),
        durationController = TextEditingController();
}

class RunwayConfigUI {
  String mode;

  TextEditingController runwayIdController;

  List<RunwayEventUI> events;

  bool isInvalid = false;

  RunwayConfigUI({
    this.mode = "Landing",
    String? runwayId,
    List<RunwayEventUI>? events,
  })  : runwayIdController =
            TextEditingController(text: runwayId ?? ""),
        events = events ?? [];

  bool isValid() {
    final runwayId = runwayIdController.text;

    if (!RegExp(r'^\d{2}$').hasMatch(runwayId)) return false;

    for (final event in events) {
      final start = int.tryParse(event.startController.text);
      final duration = int.tryParse(event.durationController.text);

      if (event.type.isEmpty) return false;
      if (start == null || start < 0) return false;
      if (duration == null || duration <= 0) return false;
    }

    return true;
  }

  /// Converts the runway configurations into a runway object.
  IRunway toRunway() {
    int id = int.parse(runwayIdController.text);
    if (mode == RunwayMode.landing.name) {
      return LandingRunway(id: id);
    }
    else if (mode == RunwayMode.takeOff.name) {
      return TakeOffRunway(id: id);
    }
    else {
      return MixedRunway(id: id);
    }
  }

  /// Converts the runway's events into a list of events.
  List<IRunwayEvent> getEvents() {
    int id = int.parse(runwayIdController.text);
    return events.map((event) {
      return RunwayEvent(
        runwayId: id,
        startTime: int.parse(event.startController.text),
        duration: int.parse(event.durationController.text),
        eventType: RunwayStatus.fromString(event.type)
      );
    }).toList();
  }
}
