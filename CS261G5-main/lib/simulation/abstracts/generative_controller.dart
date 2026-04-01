import 'dart:math';

import 'package:air_traffic_sim/simulation/abstracts/abstract_controller.dart';
import 'package:air_traffic_sim/simulation/concretes/sim_clock.dart';
import 'package:air_traffic_sim/simulation/enums/emergency_status.dart';
import 'package:air_traffic_sim/simulation/implementations/aircraft.dart';
import 'package:air_traffic_sim/simulation/interfaces/i_aircraft.dart';
import 'package:air_traffic_sim/simulation/interfaces/i_rate_parameters.dart';
import 'package:collection/collection.dart';

import 'package:flutter/material.dart';

int compareAircraftForGen(IAircraft a, IAircraft b) => a.getActualTime.compareTo(b.getActualTime);

/// Abstract controller class defining a template for how to handle a 'generative simulation'
/// i.e, one in which aircraft are dynamically generated as they enter.
/// 
/// Inheriting subclasses should make use of the priority queues and override the generation methods
/// depending on how generation is done.
abstract class GenerativeController extends AbstractController{
  static const double _sd = 5.0;
  static const double _thresholdDistance = 8.58 * _sd;

  static const double maxD = 9223372036854774784.0;

  @protected
  late final PriorityQueue<IAircraft> inbounds;
  @protected
  late final PriorityQueue<IAircraft> outbounds;

  int _inbSched = 0;
  int _outbSched = 0;

  int _ids = 0;

  GenerativeController(IRateParameters super.p) {
    inbounds = PriorityQueue<IAircraft>(compareAircraftForGen);
    outbounds = PriorityQueue<IAircraft>(compareAircraftForGen);
  }

  @override
  void updateSimClock() {
    super.updateSimClock();
    generateInbounds();
    generateOutbounds();
  }

  @override
  IAircraft get nextInbound => inbounds.first;
  @override
  IAircraft get nextOutbound => outbounds.first;

  @override
  IAircraft get getNextInbound => inbounds.removeFirst();
  @override
  IAircraft get getNextOutbound => outbounds.removeFirst();

  @protected
  static int genFuel(Random rng) => rng.nextInt(40) + 20;

  @protected
  /// Generates a normally distributed random number following N([mean],[sd]).
  static double normalRn(Random rng, double mean, double sd){
    // Generate two uniform random numbers 0 < r < 1
    double r1; double r2;
    do {r1 = rng.nextDouble();} while (r1 == 0.0);
    do {r2 = rng.nextDouble();} while (r2 == 0.0);

    return  (sqrt(-2.0 * log(r1)) * sin(2.0 * pi * r2)) * sd + mean;
  } 

  @protected
  /// Generates a random emergency status if the emergency probability [p] > 0 following:
  /// [EmergencyStatus.mechanical] | [EmergencyStatus.health] | [EmergencyStatus.fuel]
  ///            0.7               |          0.25            |           0.05
  static EmergencyStatus genStatus(Random rng, double p){
    if (p == 0.0) return EmergencyStatus.none;

    double r = rng.nextDouble();
    if (r <= p){
      r /= p;
      if (r <= 0.7){
        return EmergencyStatus.mechanical;
      }else if (r <= 0.95){
        return EmergencyStatus.health;
      }else{
        return EmergencyStatus.fuel;
      }
    }

    return EmergencyStatus.none;
  }

  /// Continuously generates inbound aircraft so there are at least ~8.6 standard deviations
  /// of difference between the last aircraft's scheduled time to enter the holding pattern,
  /// and the current simulation time.
  @protected
  void generateInbounds(){
    while (_inbSched < (_thresholdDistance + SimulationClock.time)){
      Random rng = Random();
      // Take the scheduled time.
      _inbSched = genInbSchedule;
      // Get the normally distributed actual time.
      int actual = normalRn(rng,_inbSched.toDouble(),_sd).round();
      if (actual < 0) actual = 0; // Ensure actual time is not negative.
      // Calculate status probability
      EmergencyStatus status = genStatus(rng, emergencyProb);
      inbounds.add(
        InboundAircraft(
          id:(++_ids).toString(), 
          scheduledTime: _inbSched, 
          actualTime: actual, 
          fuelLevel: genFuel(rng),
          status: status)
      );
    }
  }

  /// Continuously generates outbound aircraft so there are at least 6.7 standard deviations 
  /// of difference between the last aircraft's scheduled times to enter the take-off queue,
  /// and the current simulation time.
  @protected
  void generateOutbounds(){
    while (_outbSched < (_thresholdDistance + SimulationClock.time)){
      Random rng = Random();
      // Take the scheduled time.
      _outbSched = genOutSchedule;
      // Get the normally distributed actual time.
      int actual = normalRn(rng,_outbSched.toDouble(),_sd).round();
      if (actual < 0) actual = 0; // Ensure actual time is not negative.
      
      outbounds.add(
        OutboundAircraft(
          id:(++_ids).toString(), 
          scheduledTime:_outbSched, 
          actualTime: actual)
      );
    }
  }

  @protected
  int get genInbSchedule;
  @protected
  int get genOutSchedule;
}
