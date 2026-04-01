import 'package:air_traffic_sim/simulation/abstracts/generative_controller.dart';

mixin UniformGenerator on GenerativeController {
  late final double _inb;
  late final double _outb;

  static const int _maxRate = 999;
  static const int _minRate = 0;

  double _nInboundSchedule = 0.0;
  double _nOutboundSchedule = 0.0;

  /// Initializes the uniform generator with the given rates, and generates the first schedules.
  /// Throws an ArgumentError if either rate is out of bounds (0-1000 inclusive).
  /// SHOULD ONLY BE CALLED ONCE IN THE CONSTRUCTOR OF THE CONTROLLER.
  void init(int inboundRate, int outboundRate){
    if (inboundRate < _minRate || inboundRate > _maxRate) throw ArgumentError("Inbound rate must be between $_minRate-$_maxRate (inclusive).");
    // This ensures that a plane is generated with a time that is never reached.
    if (inboundRate == 0) {
      _inb = 0;
      _nInboundSchedule = GenerativeController.maxD;
    } else {
      _inb = 60.0 / inboundRate;
    }

    if (outboundRate < _minRate || outboundRate > _maxRate) throw ArgumentError("Outbound rate must be between $_minRate-$_maxRate (inclusive).");
    // This ensures that a plane is generated with a time that is never reached.
    if (outboundRate == 0) {
      _outb = 0;
      _nOutboundSchedule = GenerativeController.maxD;
    } else {
      _outb = 60.0 / outboundRate;
    }

    generateInbounds();
    generateOutbounds();
  }

  /// Generates uniformly distributed schedule times (not limited by integers).
  @override
  int get genInbSchedule {
    int sched = _nInboundSchedule.round();
    _nInboundSchedule += _inb;

    return sched;
  }
  
  /// Generates uniformly distributed schedule times (not limited by integers).
  @override
  int get genOutSchedule {
    int sched = _nOutboundSchedule.round();
    _nOutboundSchedule += _outb;

    return sched;
  }
}