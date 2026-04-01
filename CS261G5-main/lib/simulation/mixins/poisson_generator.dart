import 'dart:math';

import 'package:air_traffic_sim/simulation/abstracts/generative_controller.dart';

mixin PoissonGenerator on GenerativeController {
  late final double _inb;
  late final double _outb;

  static const int _maxRate = 999;
  static const int _minRate = 0;

  double nInboundSchedule = 0.0;
  double nOutboundSchedule = 0.0;

  void init(int inboundRate, int outboundRate){
    if (inboundRate <= _minRate || inboundRate > _maxRate) throw ArgumentError("Inbound rate must be between $_minRate-$_maxRate (inclusive).");
    _inb = inboundRate/60.0; // Convert to minute rates

    if (outboundRate <= _minRate || outboundRate > _maxRate) throw ArgumentError("Outbound rate must be between $_minRate-$_maxRate (inclusive).");
    _outb = outboundRate/60.0; // Convert to minute rates
  }
  /// Generates exponentially distributed schedule times (not limited by integers).
  /// Returns the maximum int-double if the rate is 0.
  @override
  int get genInbSchedule {
    try{
      Random rng = Random(); double p;
      do {p = rng.nextDouble();} while (p == 0.0);
      
      nInboundSchedule -= log(p)/_inb;
      return nInboundSchedule.round();
    }catch(e){
      return GenerativeController.maxD.toInt();
    }
  }
  
  /// Generates exponentially distributed schedule times (not limited by integers).
  /// Returns the maximum int-double if the rate is 0.
  @override
  int get genOutSchedule {
    try{
      Random rng = Random(); double p;
      do {p = rng.nextDouble();} while (p == 0.0);
      
      nOutboundSchedule -= log(p)/_outb;
      return nOutboundSchedule.round();
    }catch(e){
      return GenerativeController.maxD.toInt();
    }
  }
}