import 'package:air_traffic_sim/ui/models/realtime_dashboard_models.dart';

bool isEventUpcoming(SimulationEvent event, DateTime now) =>
  event.dtStartTime.isAfter(now);

bool isEventActive(SimulationEvent event, DateTime now) =>
    (event.dtStartTime.isBefore(now) || event.dtStartTime.isAtSameMomentAs(now)) && event.endTime.isAfter(now);

bool isEventPast(SimulationEvent event, DateTime now) =>
    event.endTime.isBefore(now) || event.endTime.isAtSameMomentAs(now);

List<SimulationEvent> filterUpcomingAndActiveEvents(
  Iterable<SimulationEvent> events,
  DateTime now,
) {
  return 
    events.where(
      (event) => isEventUpcoming(event, now) || isEventActive(event, now)
    ).toList();
}

List<SimulationEvent> filterPastEvents(
  Iterable<SimulationEvent> events,
  DateTime now,
) {
  return (
    events.where((event) => isEventPast(event, now))
  ).toList();
}

