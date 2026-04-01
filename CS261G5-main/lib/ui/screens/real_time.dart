import 'dart:async';

import 'package:air_traffic_sim/simulation/concretes/real_time_poisson_sim_cl.dart';
import 'package:air_traffic_sim/simulation/concretes/real_time_uniform_sim_cl.dart';
import 'package:air_traffic_sim/simulation/concretes/real_time_generative_sim.dart';
import 'package:air_traffic_sim/simulation/interfaces/i_real_simulation.dart';

import 'package:air_traffic_sim/simulation/concretes/temp_real_stats.dart';
import 'package:air_traffic_sim/ui/models/realtime_dashboard_models.dart';
import 'package:air_traffic_sim/ui/app_shell.dart';
import 'package:air_traffic_sim/ui/utils/realtime_event_utils.dart';
import 'package:air_traffic_sim/ui/utils/runway_animation_helpers.dart';
import 'package:air_traffic_sim/ui/widgets/controls_card.dart';
import 'package:air_traffic_sim/ui/widgets/dashboard_layout.dart';
import 'package:air_traffic_sim/ui/widgets/live_metrics_panel.dart';
import 'package:air_traffic_sim/ui/widgets/queue_panel.dart';
import 'package:air_traffic_sim/ui/widgets/runway_event_dialog.dart';
import 'package:air_traffic_sim/ui/widgets/runways_panel.dart';
import 'package:air_traffic_sim/ui/widgets/speed_slider.dart';
import 'package:flutter/material.dart';

const int defaultTPeriodms = 1000;
final DateTime defaultClockStartTime = DateTime(2000, 1, 1, 0, 0);

void eventSort(List<SimulationEvent> events) {
  events.sort((a, b) {
    int comparison = a.getStartTime.compareTo(b.getStartTime);
    if (comparison == 0) {
      // If two events start at the same time, prioritize the longer one first to minimize necessary adjustments.
      comparison = b.endTimeInMinutes.compareTo(a.endTimeInMinutes);
    }
    return comparison;
  });
}

/// Corrects the start time of [event] to ensure it does not overlap with any other events on the same runway.
/// Assumes [events] is sorted by start time (ascending), then by end time (descending). 
/// Modifies [events] in place to insert the new [event] at the correct position. [event] must not already be in [events].
void addEventWithOverlapCorrection(List<SimulationEvent> events,SimulationEvent event) {
  int i = 0;
  int newStart = event.getStartTime;
  // Find appropriate position to insert
  while (i < events.length && (newStart > events[i].getStartTime || (newStart == events[i].getStartTime && event.endTimeInMinutes < events[i].endTimeInMinutes))){
    if(event.getRunwayId == events[i].getRunwayId && event.getStartTime < events[i].endTimeInMinutes){
      newStart = events[i].endTimeInMinutes;
    } 
    i++;
  }

  event.startTime = newStart;
  events.insert(i, event);
  i++;
  newStart = event.endTimeInMinutes; // Update newStart to the end of the inserted event for subsequent checks

  while (i < events.length && events[i].getStartTime < newStart) {
    if (events[i].getRunwayId == event.getRunwayId) {
      events[i].startTime = newStart;
      newStart = events[i].endTimeInMinutes; // Update newStart to the end
    }
    i++;
  }
}

class RealTimeScreen extends StatefulWidget {
  final void Function(int index, {Object? arguments}) onNavigate;
  late final RealTimeScreenArguments args;

  RealTimeScreen({
    super.key,
    required this.onNavigate,
    required RealTimeScreenArguments? Function() getArgs,
  }){
    args = getArgs() ?? RealTimeScreenArguments(
      runways: [],
      events: [],
      inboundRate: 0,
      outboundRate: 0,
      emergencyProbability: 0,
      maxWaitTime: 1,
      minFuelThreshold: 1,
      distribution: "Uniform"
    );
  }

  @override
  State<RealTimeScreen> createState() => _RealTimeScreenState();
}

class _RealTimeScreenState extends State<RealTimeScreen> {
  late final TempRealStats _stats;
  final RunwayAnimationManager _animationManager = RunwayAnimationManager();

  late DateTime _currentSimTime;
  double _speedMultiplier = 1.0;
  Timer? _timer;

  late final IRealSimulation _simulation;

  @override
  void initState() {
    super.initState();
    // Simulation clock starts from 00:00 and only advances when the
    // simulation is running, instead of mirroring the wall clock.
    _currentSimTime = defaultClockStartTime;

    _simulation = RealTimeGenerativeSimulation(widget.args, 
      widget.args.distribution == 'Poisson' ?
      RealTimePoissonSimulationController(widget.args,_animationManager) :
      RealTimeUniformSimulationController(widget.args,_animationManager)
    );

    _stats = _simulation.getCurrStats();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startSimulationClock() {
    _timer?.cancel();
    final int tPeriod = (defaultTPeriodms /_speedMultiplier.clamp(
      kMinSimulationSpeed,
      kMaxSimulationSpeed,
    )).round();
    _timer = Timer.periodic(Duration(milliseconds: tPeriod), (_) {
      setState(() {
        _currentSimTime = _currentSimTime.add(Duration(minutes: 1));
        _simulation.tick();
      });
    });
  }

  void _onCancelEvent(SimulationEvent event) {
    setState(() {
      _simulation.cancelRunwayEvent(event); // Remove from simulation logic as well.
      if (isEventActive(event, _currentSimTime)) {
        // Mark ended at the current time for persistence symmetry.
        event.dur = _currentSimTime.difference(event.dtStartTime);
      } else {
        widget.args.getEvents.removeWhere((candidate) => candidate == event);
      }
    });
  }

  Future<void> _onRunwayTap(DashboardRunway runway) async {
    final result = await showRunwayEventDialog(
      context,
      runwayName: runway.name,
    );
    if (result == null) return;

    final startTime = _currentSimTime.add(result.offsetFromNow);
    final event = SimulationEvent(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      runwayId: runway.id,
      eventType: result.type,
      dtStartTime: startTime,
      duration: result.duration,
    );

    setState(() {
      addEventWithOverlapCorrection(widget.args.getEvents, event);
      _simulation.addRunwayEvent(event); // Add to simulation logic as well.
    });
  }

  Future<void> _onAddRunwayEvent() async {
    if (widget.args.getRunways.isEmpty) return;

    final runway = await _pickRunwayForNewEvent();
    if (runway == null) return;

    final result = await showRunwayEventDialog(
      context,
      runwayName: runway.name,
    );
    if (result == null) return;
    final startTime = _currentSimTime.add(result.offsetFromNow);

    final event = SimulationEvent(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      runwayId: runway.id,
      eventType: result.type,
      dtStartTime: startTime,
      duration: result.duration,
    );

    setState(() {
      addEventWithOverlapCorrection(widget.args.getEvents, event);
      _simulation.addRunwayEvent(event); // Add to simulation logic as well.
    });
  }

  Future<DashboardRunway?> _pickRunwayForNewEvent() async {
    final ScrollController scrollController = ScrollController();

    return showDialog<DashboardRunway>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(
                  color: Color(0xFFFFFFFF),
                  width: 2,
                ),
              ),
          backgroundColor: const Color(0xFF183059),
          title: const Text('Select Runway'),
          content: SizedBox(
            width: 320,
            height: 200,
            child: ListView.separated(
              controller: scrollController,
              itemCount: widget.args.getRunways.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final runway = widget.args.getRunways[index];
                return ListTile(
                  title: Text(runway.name, style: TextStyle(color: Color(0xFFFFFFFF))),
                  onTap: () => Navigator.of(context).pop(runway),
                );
              },
            ),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF276FBF),
                foregroundColor: Color(0xFFFFFFFF),
              ),
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    ).then((value) {
      scrollController.dispose(); // Clean up happens here
      return value;
    });
  }

  void _handleStart() {
    _startSimulationClock();
  }

  void _handlePause() {
    _timer?.cancel();
    for (final runway in widget.args.getRunways) {
      _animationManager.stopRunwayAnimation(runway.id);
    }
  }

  void _handleBack() {
    _handlePause();
    widget.onNavigate(AppTab.configuration);
  }

  void _handleSpeedChanged(double value) {
    setState(() {
      _speedMultiplier = value;
      _startSimulationClock(); // Restart timer with new speed.
    });
  }

  String _formatSimTime(DateTime time) {
    final local = time.toLocal();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final inputConfig = widget.args;

    final inputMetrics = buildInputMetricsFromConfiguration(
      distribution: widget.args.distribution,
      inboundRate: inputConfig.getInboundRate,
      outboundRate: inputConfig.getOutboundRate,
      emergencyProb: inputConfig.getEmergencyProbability,
      maxOutboundWait: inputConfig.getMaxWaitTime,
      fuelDiversionThreshold: inputConfig.getMinFuelThreshold,
    );
    final outputMetrics = buildLiveMetricsFromTempRealStats(_stats);

    return Scaffold(
      backgroundColor: const Color(0xFF183059),
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Real-Time Screen'),
        foregroundColor: const Color(0xFFFFFFFF),
        backgroundColor: const Color(0xFF276FBF),
        shape: const Border(
          bottom: BorderSide(
            color: Color(0xFF183059),
            width: 5,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: DashboardLayout(
          leftColumn: QueuesAndLogsPanel(
            inbQueueSize: _stats.currInboundQueueLength,
            outbQueueSize: _stats.currOutboundQueueLength,
            emergencies: _stats.currEmergencyCount,
            events: widget.args.getEvents,
            now: _currentSimTime,
            onCancelEvent: _onCancelEvent,
          ),
          centerColumn: RunwaysPanel(
            runways: widget.args.getRunways,
            animationManager: _animationManager,
            onRunwayTap: _onRunwayTap,
            speedMultiplier: _speedMultiplier,
          ),
          rightColumn: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ControlsCard(
                onStart: _handleStart,
                onPause: _handlePause,
                onBack: _handleBack,
              ),
              const SizedBox(height: 16),
              SimulationSpeedCard(
                speedMultiplier: _speedMultiplier,
                onSpeedChanged: _handleSpeedChanged,
                onAddRunwayEvent: _onAddRunwayEvent,
                simulationTimeLabel: _formatSimTime(_currentSimTime),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: LiveMetricsCard(
                  inputMetrics: inputMetrics,
                  outputMetrics: outputMetrics,
                  landingDelayOverTime: [_stats.sectionAverageLandingDelayList],
                  takeoffDelayOverTime: [_stats.sectionAverageDepartureDelayList],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
