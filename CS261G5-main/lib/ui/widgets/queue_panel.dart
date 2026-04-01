import 'package:flutter/material.dart';

import 'package:air_traffic_sim/ui/models/realtime_dashboard_models.dart';
import 'package:air_traffic_sim/ui/utils/realtime_event_utils.dart';

class QueuesAndLogsPanel extends StatelessWidget {
  final int inbQueueSize;
  final int outbQueueSize;
  final int emergencies;
  final List<SimulationEvent> events;
  final DateTime now;
  final void Function(SimulationEvent) onCancelEvent;

  const QueuesAndLogsPanel({
    super.key,
    required this.inbQueueSize,
    required this.outbQueueSize,
    required this.emergencies,
    required this.events,
    required this.now,
    required this.onCancelEvent,
  });

  @override
  Widget build(BuildContext context) {
    final upcomingAndActive = filterUpcomingAndActiveEvents(events, now);
    final pastEvents = filterPastEvents(events, now);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      color: const Color(0xFF276FBF),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Queues & Logs',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFFFFFFFF),
              ),
            ),
            const SizedBox(height: 16),
            QueueSummaryCard(
              inbQueueSize: inbQueueSize,
              outbQueueSize: outbQueueSize,
              emergencies: emergencies,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Column(
                children: [
                  Expanded(
                    child: EventLogCard(
                      title: 'Upcoming / Active Events',
                      events: upcomingAndActive,
                      now: now,
                      showActions: true,
                      onCancelEvent: onCancelEvent,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: EventLogCard(
                      title: 'Past Events',
                      events: pastEvents,
                      now: now,
                      showActions: false,
                      onCancelEvent: (_) {},
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class QueueSummaryCard extends StatelessWidget {
  final int inbQueueSize;
  final int outbQueueSize;
  final int emergencies;

  const QueueSummaryCard({
    super.key,
    required this.inbQueueSize,
    required this.outbQueueSize,
    required this.emergencies,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: const Color(0xFF183059),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _QueueSummaryBlock(
              title: 'Inbound / Landing',
              queueSize: inbQueueSize,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _QueueSummaryBlock(
              title: 'Outbound / Departure',
              queueSize: outbQueueSize,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _EmergencySummaryBlock(
              emergencies: emergencies,
            ),
          ),
        ],
      ),
    );
  }
}

class _QueueSummaryBlock extends StatelessWidget {
  final String title;
  final int queueSize;

  const _QueueSummaryBlock({
    required this.title,
    required this.queueSize,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFFFFFFFF),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Queue Size',
          style: textTheme.bodySmall?.copyWith(
            color: const Color(0xCCFFFFFF),
          ),
        ),
        Text(
          queueSize.toString(),
          style: textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: const Color(0xFFFFFFFF),
          ),
        ),
      ],
    );
  }
}

class _EmergencySummaryBlock extends StatelessWidget {
  final int emergencies;

  const _EmergencySummaryBlock({
    required this.emergencies,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Landing Emergencies',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFFFFFFFF),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Active',
          style: textTheme.bodySmall?.copyWith(
            color: const Color(0xCCFFFFFF),
          ),
        ),
        Text(
          emergencies.toString(),
          style: textTheme.headlineMedium?.copyWith(
            color: Colors.redAccent,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class EventLogCard extends StatelessWidget {
  final String title;
  final List<SimulationEvent> events;
  final DateTime now;
  final bool showActions;
  final void Function(SimulationEvent) onCancelEvent;

  const EventLogCard({
    super.key,
    required this.title,
    required this.events,
    required this.now,
    required this.showActions,
    required this.onCancelEvent,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: const Color(0xFF183059),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            '',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFFFFFFFF),
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFFFFFFFF),
            ),
          ),
          const SizedBox(height: 8),
          _EventHeaderRow(showActions: showActions),
          const SizedBox(height: 4),
          Expanded(
            child: ListView.separated(
              itemCount: events.length,
              separatorBuilder: (_, _) => const SizedBox(height: 2),
              itemBuilder: (context, index) {
                final event = events[index];
                final active = isEventActive(event, now);

                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: active
                        ? Colors.green.withValues(alpha: 0.25)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Table(
                    columnWidths: const {
                      0: FlexColumnWidth(2),
                      1: FlexColumnWidth(3),
                      2: FlexColumnWidth(2),
                      3: FlexColumnWidth(2),
                    },
                    children: [
                      TableRow(
                        children: [
                          Text(
                            _formatTime(event.dtStartTime),
                            style: textTheme.bodySmall?.copyWith(
                              color: const Color(0xFFFFFFFF),
                            ),
                          ),
                          Text(
                            event.type.name,
                            style: textTheme.bodySmall?.copyWith(
                              color: const Color(0xFFFFFFFF),
                            ),
                          ),
                          Text(
                            _formatDuration(event.duration),
                            style: textTheme.bodySmall?.copyWith(
                              color: const Color(0xFFFFFFFF),
                            ),
                          ),
                          if (showActions)
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () => onCancelEvent(event),
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.redAccent,
                                ),
                                child: const Text('Cancel'),
                              ),
                            )
                          else
                            const SizedBox(),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    if (minutes == 0) {
      return '${duration.inSeconds}s';
    }
    return '$minutes min';
  }
}

class _EventHeaderRow extends StatelessWidget {
  final bool showActions;

  const _EventHeaderRow({required this.showActions});

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelSmall?.copyWith(
          color: const Color(0xCCFFFFFF),
          fontWeight: FontWeight.bold,
        );

    return Table(
      columnWidths: const {
        0: FlexColumnWidth(2),
        1: FlexColumnWidth(3),
        2: FlexColumnWidth(2),
        3: FlexColumnWidth(2),
      },
      children: [
        TableRow(
          children: [
            Text('Time', style: style),
            Text('Type', style: style),
            Text('Duration', style: style),
            if (showActions)
              Align(
                alignment: Alignment.centerRight,
                child: Text('Action', style: style),
              )
            else
              const SizedBox(),
          ],
        ),
      ],
    );
  }
}