import 'dart:collection';
import 'dart:math';

import 'package:air_traffic_sim/simulation/concretes/sim_clock.dart';
import 'package:air_traffic_sim/simulation/concretes/simulation_stats.dart';
import 'package:air_traffic_sim/simulation/concretes/temp_real_stats.dart';
import 'package:air_traffic_sim/simulation/concretes/temp_stats.dart';
import 'package:air_traffic_sim/simulation/enums/runway_mode.dart';
import 'package:air_traffic_sim/simulation/implementations/rate_parameters.dart';
import 'package:air_traffic_sim/simulation/interfaces/i_aircraft.dart';
import 'package:air_traffic_sim/simulation/interfaces/i_airport.dart';
import 'package:air_traffic_sim/simulation/interfaces/i_parameters.dart';
import 'package:air_traffic_sim/simulation/interfaces/i_runway.dart';
import 'package:air_traffic_sim/simulation/interfaces/i_runway_event.dart';
import 'package:air_traffic_sim/simulation/interfaces/i_simulation_controller.dart';
import 'package:flutter/material.dart';

abstract class AbstractController implements ISimulationController{
  late final TempRealStats _stats;
  late final IParameters _parameters;

  @protected late final double emergencyProb;

  late final int _maxWaitTime;
  late final int _minFuelThreshold; 

  /// Basic constructor which initialises all constants.
  /// 
  /// [p] represents the parameters entered for a 'rate-controlled' simulation.
  AbstractController(IParameters p){
    _stats = TempRealStats(); // Initialises with all values set to 0.
    _parameters = p;

    emergencyProb = p.getEmergencyProbability;
    if (emergencyProb < 0 || emergencyProb > 1) throw ArgumentError("Emergency probability must be between 0-1 (inclusive).");

    _maxWaitTime = p.getMaxWaitTime;
    if(_maxWaitTime <= 0) throw ArgumentError("Maximum wait time must be greater than 0 (minutes).");

    _minFuelThreshold = p.getMinFuelThreshold;
    if (_minFuelThreshold <= 0) throw ArgumentError("Minimum fuel threshold must be greater than 0");
  }

  /// @inheritdoc
  /// 
  /// Continuously generates and adds aircraft to the holding pattern and take off queue
  /// so long as their entering time has been reached.
  /// Updates the maximum inbound/outbound queue size appropriately in the temporary aggregation. 
  @override
  void includeEnteringAircraft(IAirport airport) {
    // Include entering aircraft.
    while (SimulationClock.time >= nextInbound.getActualTime){
      addToHolding(airport, getNextInbound);
    }
    // Include departing aircraft.
    while (SimulationClock.time >= nextOutbound.getActualTime){
      addToTakeOff(airport, getNextOutbound);
    }
  }

  @protected
  void addToHolding(IAirport airport, IAircraft aircraft){
    airport.addToHolding(aircraft);
  }

  @protected
  void addToTakeOff(IAirport airport, IAircraft aircraft){
    airport.addToTakeOff(aircraft);
  }

  /// @inheritdoc
  /// 
  /// Assumes that the list of runways in [airport] is sorted by their [IRunway.nextAvailable] time
  /// and maintains this sorted order.
  /// 
  /// Updates the maximum and total landing/take-off delays and the total hold/wait times in [_stats].
  @override
  void assignAircrafts(IAirport airport) {
    List<IRunway> r = airport.getRunways;

    // Update aggregation. Get the number of available runways
    _stats.maximumPossibleRunwayUsage += r.where(((runway) => runway.isAvailable)).length;

    int i = 0;    
    // Attempt to land aircraft(s)
    while (!airport.isHoldingEmpty && i < r.length && r[i].isAvailable){
      // Assign if runway is available and supports it.
      if (r[i].mode(emergency:airport.hasEmergency,takeOffEmpty:airport.isTakeOffEmpty) == RunwayMode.landing){
        land(r[i],airport.firstInHolding);
        // Re-sort runways (bubble style).
        sort(r,i);
      } else {
        i++; // Pointer only needs incrementing upon incompatibility.
      }
    }

    i = 0;
    // Attempt to depart aircraft(s)
    while (!airport.isTakeOffEmpty && i < r.length && r[i].isAvailable){
      // Assign if runway is available and supports it.
      if (r[i].mode(holdingEmpty:airport.isHoldingEmpty) == RunwayMode.takeOff){
        depart(r[i],airport.firstInTakeOff);
        // Re-sort runways (bubble style)
        sort(r,i);
      } else {
        i++; // Pointer only needs incrementing upon incompatibility.
      }
    }

    // Update aggregation. This is done after runway assignment to account for immediate assignments on aircraft entries.
    _stats.maxInboundQueue = max<int>(_stats.maxInboundQueue, airport.getHoldingCount);
    _stats.maxOutboundQueue = max<int>(_stats.maxOutboundQueue, airport.getTakeOffCount);
  }

  @protected
  void depart(IRunway runway, IAircraft aircraft){
    // Assign
    runway.assignAircraft(aircraft);
    // Update aggregation.
    int delay = aircraft.getScheduledTime - SimulationClock.time;
    if (delay > 0){
      _stats.maxDepartureDelay = max<int>(_stats.maxDepartureDelay,delay);
      _stats.totalDepartureDelay += delay;
      _stats.totalSectionDepartureDelay += delay;
      _stats.updateDepartureMovingAverage(delay);
    }
    _stats.totalWaitTime += max<int>(0,aircraft.getActualTime - SimulationClock.time);
    _stats.totalRunwayUsage++;
    _stats.departingAircraftCount++;
    _stats.sectionDepartingAircraftCount++;
  }

  @protected
  void land(IRunway runway, IAircraft aircraft){
    // Assign
    runway.assignAircraft(aircraft);
    // Update aggregation.
    int delay = aircraft.getScheduledTime - SimulationClock.time;
    if (delay > 0){
      _stats.maxLandingDelay = max<int>(_stats.maxLandingDelay,delay);
      _stats.totalLandingDelay += delay;
      _stats.totalSectionLandingDelay += delay;
      _stats.updateLandingMovingAverage(delay);
    }
    _stats.totalHoldTime += max<int>(0,aircraft.getActualTime - SimulationClock.time);
    _stats.totalRunwayUsage++;
    _stats.landingAircraftCount++;
    _stats.sectionLandingAircraftCount++;
  }

  /// Locally sorts a single out of place runway at index [i].
  void sort(List<IRunway> runways, int i){
    while (++i < runways.length && runways[i-1].nextAvailable > runways[i].nextAvailable){
      IRunway temp = runways[i];
      runways[i] = runways[i-1];
      runways[i-1] = temp;
    }
  }

  void sortAllRunways(List<IRunway> runways){
    runways.sort((r1,r2) => r1.nextAvailable.compareTo(r2.nextAvailable));
  }

  @override
  void startRunwayEvents(Queue<IRunwayEvent> events, IAirport airport){
    List<IRunway> runways = airport.getRunways;

    while (events.isNotEmpty && SimulationClock.time >= events.first.getStartTime){
      IRunwayEvent event = events.removeFirst();
      int index = runways.indexWhere((runway) => runway.id == event.getRunwayId);
      if (index == -1) {
        throw ArgumentError("Runway with ID ${event.getRunwayId} not found for event at time ${event.getStartTime}.");
      }
      runways[index].closeRunway(event.getDuration, event.getEventType);
      sort(runways, index); // Re-sort after runway status change. Use bubble as usually only one runway is affected and is likely near the front.
    }
  }

  @override
  void updateSimClock(){
    SimulationClock.time++; // Simple increment
    _stats.updateSectionAverage();
  }

  @override
  void enactFlightChanges(IAirport airport) {
    int cancellations = airport.cancel(_maxWaitTime).length;
    _stats.totalCancellations += cancellations;
    _stats.totalWaitTime += cancellations * _maxWaitTime; // Account for wait time of cancelled aircraft.

    List<IAircraft> diversions = airport.divert(_minFuelThreshold);
    _stats.totalDiversions += diversions.length;
    if (diversions.isNotEmpty) {
      // Account for hold time of diverted aircraft.
      for (IAircraft a in diversions){
        _stats.totalHoldTime += a.getInitFuelLevel - _minFuelThreshold;
        if (a.isEmergency()){
          _stats.currEmergencyCount--;
        }
      }
    }
  }

  @protected
  IParameters get parameters => _parameters;
  @override
  TempStats get getCurrTempStats => _stats;
  
  @override
  SimulationStats get getCurrStats =>
    _parameters is RateParameters ? 
    SimulationStats.aggr(_stats, _parameters) : 
    SimulationStats.aggr(_stats, RateParameters(runways: 
      _parameters.getRunways, 
      emergencyProbability: _parameters.getEmergencyProbability, 
      events: _parameters.getEvents as Queue<IRunwayEvent>, 
      maxWaitTime: _parameters.getMaxWaitTime, 
      minFuelThreshold: _parameters.getMinFuelThreshold, 
      duration: _parameters.getDuration, 
      outboundRate: 0, 
      inboundRate: 0
  ));

  /// Getters for inspecting the next aircraft (without removal).
  @protected
  IAircraft get nextInbound;
  @protected
  IAircraft get nextOutbound;
  /// Getters for grabbing the next aircraft (with removal).
  @protected
  IAircraft get getNextInbound;
  @protected
  IAircraft get getNextOutbound;

}
