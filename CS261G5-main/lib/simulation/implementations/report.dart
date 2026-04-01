
import 'dart:collection';

import 'package:air_traffic_sim/simulation/interfaces/i_rate_parameters.dart';
import 'package:air_traffic_sim/simulation/implementations/simulation_inputs.dart';
import 'package:air_traffic_sim/simulation/concretes/simulation_stats.dart';
import 'package:air_traffic_sim/simulation/exceptions/corrupt_csv_exception.dart';
import 'package:air_traffic_sim/simulation/interfaces/i_report.dart';
import 'package:air_traffic_sim/simulation/implementations/runway.dart';

class Report extends IReport {

  SimulationStats _stats;
  IRateParameters _inputs;

  Report({required SimulationStats stats, required IRateParameters inputs}) : _stats = stats, _inputs = inputs;

  @override
  SimulationStats get getStats => _stats;

  @override
  IRateParameters get getInputs => _inputs;

  @override
  String exportCSV() {
    final rows = [
      ["Metric", "Value"],
      ["Average Landing Delay", _stats.averageLandingDelay.toString()],
      ["Average Hold Time", _stats.averageHoldTime.toString()],
      ["Average Departure Delay", _stats.averageDepartureDelay.toString()],
      ["Average Wait Time", _stats.averageWaitTime.toString()],
      ["Maximum Landing Delay", _stats.maxLandingDelay.toString()],
      ["Maximum Departure Delay", _stats.maxDepartureDelay.toString()],
      ["Maximum Inbound Queue Size", _stats.maxInboundQueue.toString()],
      ["Maximum Outbound Queue Size", _stats.maxOutboundQueue.toString()],
      ["Total Cancellations", _stats.totalCancellations.toString()],
      ["Total Diversions", _stats.totalDiversions.toString()],
      ["Total Landing Aircraft", _stats.totalLandingAircraft.toString()],
      ["Total Departing Aircraft", _stats.totalDepartingAircraft.toString()],
      ["Runway Utilisation Percentage", _stats.runwayUtilisation.toString()],
      ["Section Average Landing Delays", _stats.sectionAverageLandingDelayList.join(", ")],
      ["Section Average Departure Delays", _stats.sectionAverageDepartureDelayList.join(", ")],
      ["", ""],
      ["Input Configuration", ""],
      ["Inbound Rate", _inputs.getInboundRate.toString()],
      ["Outbound Rate", _inputs.getOutboundRate.toString()],
      ["Landing Runways", _inputs.getRunways.whereType<LandingRunway>().length.toString()],
      ["Takeoff Runways", _inputs.getRunways.whereType<TakeOffRunway>().length.toString()],
      ["Mixed Runways", _inputs.getRunways.whereType<MixedRunway>().length.toString()],
      ["Emergency Probability", _inputs.getEmergencyProbability.toString()],
      ["Max Wait Time", _inputs.getMaxWaitTime.toString()],
      ["Min Fuel Threshold", _inputs.getMinFuelThreshold.toString()],
      ["Duration", _inputs.getDuration.toString()],
    ];
    // Escape all quotation marks, join the contents of each row with commas, join rows together with commas
    return rows.map((row) => row.map(_escapeCsv).join(",")).join("\n");
  }

  String _escapeCsv(String value) {
    final escaped = value.replaceAll('"', '""');
    return '"$escaped"';
  }

  bool _isEmptyRow(List<String> row) => row.every((value) => value.trim().isEmpty);

  List<double> _parseDoubleList(String value) {
    if (value.trim().isEmpty) {
      return [];
    }
    return value.split(',').map((v) => double.parse(v.trim())).toList();
  }

  @override
  void importCSV(String str) {
    int rowIndex = 0;
    try {
      List<List<String>> rows = _parseCSV(str);

      if (rows.isEmpty) throw Exception("CSV is empty");

      int dataRowIndex = 1; // Skip the header row.

      // Parse the output metrics.
      double averageLandingDelay = double.parse(rows[dataRowIndex++][1]);
      double averageHoldTime = double.parse(rows[dataRowIndex++][1]);
      double averageDepartureDelay = double.parse(rows[dataRowIndex++][1]);
      double averageWaitTime = double.parse(rows[dataRowIndex++][1]);
      int maxLandingDelay = int.parse(rows[dataRowIndex++][1]);
      int maxDepartureDelay = int.parse(rows[dataRowIndex++][1]);
      int maxInboundQueue = int.parse(rows[dataRowIndex++][1]);
      int maxOutboundQueue = int.parse(rows[dataRowIndex++][1]);
      int totalCancellations = int.parse(rows[dataRowIndex++][1]);
      int totalDiversions = int.parse(rows[dataRowIndex++][1]);
      int totalLandingAircraft = int.parse(rows[dataRowIndex++][1]);
      int totalDepartingAircraft = int.parse(rows[dataRowIndex++][1]);
      double runwayUtilisation = double.parse(rows[dataRowIndex++][1]);

      // Parse the list of section average landing delays.
      List<double> sectionAverageLandingDelayList = _parseDoubleList(rows[dataRowIndex][1]);
      dataRowIndex++;

      // Skip any empty rows.
      while (dataRowIndex < rows.length && _isEmptyRow(rows[dataRowIndex])) {
        dataRowIndex++;
      }

      // Parse the list of section average departure delays.
      List<double> sectionAverageDepartureDelayList = _parseDoubleList(rows[dataRowIndex][1]);
      dataRowIndex++;

      // Skip any empty rows.
      while (dataRowIndex < rows.length &&
          (_isEmptyRow(rows[dataRowIndex]))) {
        dataRowIndex++;
      }
      dataRowIndex++; // Skip the "Input Configuration" row.

      // Parse the input configuration.
      int inboundRate = int.parse(rows[dataRowIndex++][1]);
      int outboundRate = int.parse(rows[dataRowIndex++][1]);
      int landingRunways = int.parse(rows[dataRowIndex++][1]);
      int takeoffRunways = int.parse(rows[dataRowIndex++][1]);
      int mixedRunways = int.parse(rows[dataRowIndex++][1]);
      double emergencyProbability = double.parse(rows[dataRowIndex++][1]);
      int maxWaitTime = int.parse(rows[dataRowIndex++][1]);
      int minFuelThreshold = int.parse(rows[dataRowIndex++][1]);
      int duration = int.parse(rows[dataRowIndex++][1]);

      _stats = SimulationStats(
        averageLandingDelay: averageLandingDelay,
        averageHoldTime: averageHoldTime,
        averageDepartureDelay: averageDepartureDelay,
        averageWaitTime: averageWaitTime,
        maxLandingDelay: maxLandingDelay,
        maxDepartureDelay: maxDepartureDelay,
        maxInboundQueue: maxInboundQueue,
        maxOutboundQueue: maxOutboundQueue,
        totalCancellations: totalCancellations,
        totalDiversions: totalDiversions,
        totalLandingAircraft: totalLandingAircraft,
        totalDepartingAircraft: totalDepartingAircraft,
        runwayUtilisation: runwayUtilisation,
        sectionAverageLandingDelayList: sectionAverageLandingDelayList,
        sectionAverageDepartureDelayList: sectionAverageDepartureDelayList,
      );

      _inputs = SimulationInputs(
        runways: [
          ...List.generate(landingRunways, (index) => LandingRunway(id: index + 1)),
          ...List.generate(takeoffRunways, (index) => TakeOffRunway(id: landingRunways + index + 1)),
          ...List.generate(mixedRunways, (index) => MixedRunway(id: landingRunways + takeoffRunways + index + 1)),
        ],
        emergencyProbability: emergencyProbability,
        events: Queue.from(const []),
        maxWaitTime: maxWaitTime,
        minFuelThreshold: minFuelThreshold,
        duration: duration,
        outboundRate: outboundRate,
        inboundRate: inboundRate,
      );
    } catch (e) {
      throw CorruptCsvException(rowIndex, "CSV file is corrupted: $e");
    }
  }

  /// Parses CSV string into a 2D list of strings.
  List<List<String>> _parseCSV(String csvStr) {
    List<List<String>> rows = [];
    List<String> currentRow = [];
    String currentValue = "";
    bool inString = false;

    for (int i = 0; i < csvStr.length; i++) {
      String char = csvStr[i];

      if (char == '"') {
        if (inString && i + 1 < csvStr.length && csvStr[i + 1] == '"') { // If at an escaped quotation mark, add it to the string.
          currentValue += '"';
          i++;
        } else {
          inString = !inString; // Change whether inside a string or not.
        }
      } else if (char == ',' && !inString) { // End of current value. Add to current row.
        currentRow.add(currentValue);
        currentValue = "";
      } else if ((char == '\n' || char == '\r') && !inString) {   // At the end of the row.
        if (currentValue.isNotEmpty || currentRow.isNotEmpty) {   // If row was not empty.
          currentRow.add(currentValue); // Add current value.
          currentValue = "";
          rows.add(currentRow); // Add the current row to processed rows.
          currentRow = [];
        }
      } else {
        currentValue += char;
      }
    }

    // Add the final value and row.
    if (currentValue.isNotEmpty) {
      currentRow.add(currentValue);
    }
    if (currentRow.isNotEmpty) {
      rows.add(currentRow);
    }

    return rows;
  }
}
