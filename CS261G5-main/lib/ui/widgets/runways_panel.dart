import 'package:flutter/material.dart';
import 'package:air_traffic_sim/ui/models/realtime_dashboard_models.dart';
import 'package:air_traffic_sim/ui/utils/runway_animation_helpers.dart';
import 'package:air_traffic_sim/ui/utils/runway_style_utils.dart';


class RunwaysPanel extends StatelessWidget {
  final List<DashboardRunway> runways;
  final RunwayAnimationManager animationManager;
  final void Function(DashboardRunway) onRunwayTap;
  final double speedMultiplier;

  const RunwaysPanel({
    super.key,
    required this.runways,
    required this.animationManager,
    required this.onRunwayTap,
    required this.speedMultiplier,
  });

  @override
  Widget build(BuildContext context) {
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
              'Runways',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFFFFFFFF),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.only(right: 12),
                itemCount: runways.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final runway = runways[index];
                  return _RunwayCard(
                    runway: runway,
                    animationManager: animationManager,
                    onTap: () => onRunwayTap(runway),
                    speedMultiplier: speedMultiplier,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _RunwayAnimationType { none, takeoff, landing }

class _RunwayCard extends StatefulWidget {
  final DashboardRunway runway;
  final RunwayAnimationManager animationManager;
  final VoidCallback onTap;
  final double speedMultiplier;

  const _RunwayCard({
    required this.runway,
    required this.animationManager,
    required this.onTap,
    required this.speedMultiplier,
  });

  @override
  State<_RunwayCard> createState() => _RunwayCardState();
}

class _RunwayCardState extends State<_RunwayCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Animation<Alignment> _alignment;
  _RunwayAnimationType _activeAnimation = _RunwayAnimationType.none;
  Duration _simDuration = const Duration(minutes: 1);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        setState(() {
          _activeAnimation = _RunwayAnimationType.none;
        });
      }
    });

    widget.animationManager.registerRunway(
      runwayId: widget.runway.id,
      startTakeoff: (duration) =>
          _startAnim(_RunwayAnimationType.takeoff, duration),
      startLanding: (duration) =>
          _startAnim(_RunwayAnimationType.landing, duration),
      stop: _stopAnim,
    );

    _alignment =
        const AlwaysStoppedAnimation<Alignment>(Alignment(-0.8, 0.4));
  }

  Duration _durationForSpeed(Duration simDuration, double speedMultiplier) {
    if (simDuration.inMilliseconds <= 0) {
      return const Duration(seconds: 3);
    }
    final clamped = speedMultiplier.clamp(0.25, 4.0);
    final realSeconds = simDuration.inSeconds / clamped;
    return Duration(milliseconds: (realSeconds * 1000).round());
  }

  void _startAnim(_RunwayAnimationType type, Duration simDuration) {
    if (!mounted) return;

    _simDuration = simDuration;

    setState(() {
      _activeAnimation = type;
      if (type == _RunwayAnimationType.takeoff) {
        _alignment = AlignmentTween(
          begin: const Alignment(-0.8, 0.45),
          end: const Alignment(0.8, -0.6),
        ).animate(
          CurvedAnimation(parent: _controller, curve: Curves.easeIn),
        );
      } else {
        _alignment = AlignmentTween(
          begin: const Alignment(0.8, -0.6),
          end: const Alignment(-0.8, 0.45),
        ).animate(
          CurvedAnimation(parent: _controller, curve: Curves.easeOut),
        );
      }
    });

    _controller
      ..duration = _durationForSpeed(_simDuration, widget.speedMultiplier)
      ..reset()
      ..forward();
  }

  void _stopAnim(Duration _) {
    if (!mounted) return;
    _controller.stop();
    setState(() => _activeAnimation = _RunwayAnimationType.none);
  }

  @override
  void didUpdateWidget(covariant _RunwayCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.speedMultiplier != widget.speedMultiplier &&
        _activeAnimation != _RunwayAnimationType.none &&
        _controller.isAnimating) {
      final progress = _controller.value;
      _controller
        ..duration =
            _durationForSpeed(_simDuration, widget.speedMultiplier)
        ..forward(from: progress);
    }
  }

  @override
  void dispose() {
    widget.animationManager.unregisterRunway(widget.runway.id);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final borderColor = borderColorForRunwayStatus(widget.runway.status);
    final statusLabel = labelForRunwayStatus(widget.runway.status);
    final modeLabel =
        '${labelForRunwayOperatingMode(widget.runway.operatingMode)} MODE';

    return InkWell(
      onTap: widget.onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: 2),
          color: Color.fromRGBO(0, 0, 0, 0.8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.runway.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      statusLabel,
                      style: TextStyle(
                        color: borderColor,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      modeLabel,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 4),
            SizedBox(
              height: 56,
              width: double.infinity,
              child: Stack(
                children: [
                  _buildRunwayVisual(),
                  if (_activeAnimation != _RunwayAnimationType.none)
                    AnimatedBuilder(
                      animation: _controller,
                      builder: (context, _) {
                        final isLanding =
                            _activeAnimation == _RunwayAnimationType.landing;

                        Widget icon = Icon(
                          isLanding ? Icons.flight_land : Icons.flight_takeoff,
                          color: Colors.white,
                          size: 28,
                        );

                        if (isLanding) {
                          icon = Transform(
                            alignment: Alignment.center,
                            transform:
                                Matrix4.identity()..scale(-1.0, 1.0, 1.0),
                            child: icon,
                          );
                        }

                        return Align(
                          alignment: _alignment.value,
                          child: icon,
                        );
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRunwayVisual() {
    return Align(
      alignment: const Alignment(0, 0.45),
      child: Container(
        height: 2,
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white10,
          borderRadius: BorderRadius.circular(1),
        ),
      ),
    );
  }
}
