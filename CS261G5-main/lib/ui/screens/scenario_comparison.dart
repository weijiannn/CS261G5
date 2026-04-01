import "dart:convert";

import "package:air_traffic_sim/persistence/app_persistence.dart";
import "package:air_traffic_sim/persistence/models/scenario_record.dart";
import "package:air_traffic_sim/ui/app_shell.dart";
import "package:air_traffic_sim/ui/widgets/scenario_picker_overlay.dart";
import "package:air_traffic_sim/ui/widgets/section_average_graph.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";

typedef ScenarioPicker = Future<ScenarioRecord?> Function(BuildContext context);

class ScenarioScreen extends StatefulWidget {
  final void Function(int index, {Object? arguments}) onNavigate;

  const ScenarioScreen({
    super.key,
    required this.onNavigate,
    this.pickScenario = showScenarioPickerOverlay,
  });

  final ScenarioPicker pickScenario;

  @override
  State<ScenarioScreen> createState() => _ScenarioScreenState();
}

class _ScenarioScreenState extends State<ScenarioScreen> {
  final List<ScenarioRecord> _selectedScenarios = <ScenarioRecord>[];

  ScenarioRecord? _scenario1;
  ScenarioRecord? _scenario2;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _loadScenario(int slot) async {
    final scenario = await widget.pickScenario(context);
    if (scenario == null) return;

    final hydratedScenario = await _hydrateScenarioIfNeeded(scenario);

    setState(() {
      final existingIndex = _selectedScenarios.indexWhere(
        (item) => item.id == hydratedScenario.id,
      );

      if (existingIndex == -1) {
        _selectedScenarios.add(hydratedScenario);
      }

      if (slot == 1) {
        _scenario1 = hydratedScenario;
      } else {
        _scenario2 = hydratedScenario;
      }
    });
  }

  Future<ScenarioRecord> _hydrateScenarioIfNeeded(ScenarioRecord scenario) async {
    final raw = scenario.configJson;
    if (raw == null || raw.trim().isEmpty) {
      return scenario;
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        return scenario;
      }

      final hasResults =
          decoded["results"] is Map<String, dynamic> ||
          decoded["metricsSummary"] is Map<String, dynamic> ||
          decoded["metrics"] is Map<String, dynamic>;
      if (hasResults) {
        return scenario;
      }

      final runs = await AppPersistence.instance.runRepository.listRunsByScenario(
        scenario.id,
      );
      if (runs.isEmpty) {
        return scenario;
      }

      final stats = runs.first.stats;
      final merged = {
        ...decoded,
        "results": {
          "averageLandingDelay": stats.averageLandingDelay,
          "averageHoldTime": stats.averageHoldTime,
          "averageDepartureDelay": stats.averageDepartureDelay,
          "averageWaitTime": stats.averageWaitTime,
          "maxLandingDelay": stats.maxLandingDelay,
          "maxDepartureDelay": stats.maxDepartureDelay,
          "maxInboundQueue": stats.maxInboundQueue,
          "maxOutboundQueue": stats.maxOutboundQueue,
          "totalCancellations": stats.totalCancellations,
          "totalDiversions": stats.totalDiversions,
          "totalLandingAircraft": stats.totalLandingAircraft,
          "totalDepartingAircraft": stats.totalDepartingAircraft,
          "runwayUtilisation": stats.runwayUtilisation,
          "sectionAverageLandingDelayList": stats.sectionAverageLandingDelayList,
          "sectionAverageDepartureDelayList": stats.sectionAverageDepartureDelayList,
        },
      };

      return ScenarioRecord(
        id: scenario.id,
        name: scenario.name,
        generationModel: scenario.generationModel,
        description: scenario.description,
        configJson: const JsonEncoder.withIndent("  ").convert(merged),
        createdAt: scenario.createdAt,
      );
    } catch (_) {
      return scenario;
    }
  }


  _ScenarioMetrics _metricsFor(ScenarioRecord? scenario) {
    if (scenario == null ||
        scenario.configJson == null ||
        scenario.configJson!.isEmpty) {
      return const _ScenarioMetrics();
    }

    try {
      final decoded = jsonDecode(scenario.configJson!);
      if (decoded is! Map<String, dynamic>) {
        return const _ScenarioMetrics();
      }

      final scenarioConfig = decoded["scenario"];
      final configMap = scenarioConfig is Map<String, dynamic> ? scenarioConfig : decoded;

      final results =
          decoded["results"] ?? decoded["metricsSummary"] ?? decoded["metrics"];
      final nestedResults = configMap["results"] ?? configMap["metricsSummary"] ?? configMap["metrics"];
      final resultMap = results is Map<String, dynamic>
          ? results
          : (nestedResults is Map<String, dynamic> ? nestedResults : configMap);


      num? readNum(Map<String, dynamic> map, List<String> keys) {
        for (final key in keys) {
          final value = map[key];
          if (value is num) return value;
          if (value is String) return num.tryParse(value);
        }
        return null;
      }

      List<double> readDoubleList(
        Map<String, dynamic> map,
        List<String> keys,
      ) {
        for (final key in keys) {
          final value = map[key];
          if (value is List) {
            return value
                .map((e) => e is num ? e.toDouble() : double.tryParse("$e"))
                .whereType<double>()
                .toList();
          }
        }
        return const [];
      }

      List<dynamic> readList(Map<String, dynamic> map, List<String> keys) {
        for (final key in keys) {
          final value = map[key];
          if (value is List) {
            return value;
          }
        }
        return const [];
      }

      num countRunwaysByMode(List<dynamic> runways, List<String> modeNames) {
        final names = modeNames.map((mode) => mode.toLowerCase()).toSet();
        var count = 0;
        for (final runway in runways) {
          if (runway is! Map<String, dynamic>) {
            continue;
          }
          final mode = runway["mode"]?.toString().trim().toLowerCase();
          if (mode != null && names.contains(mode)) {
            count += 1;
          }
        }
        return count;
      }

      final runways = readList(configMap, ["runways"]);
      final emergencyProbability = readNum(configMap, ["emergencyProbability"]);


      return _ScenarioMetrics(
        duration:
            readNum(configMap, ["duration"]) ??
            (() {
              final minutes = readNum(configMap, ["durationMinutes"]);
              if (minutes == null) return null;
              return minutes / 60;
            })(),
        landingRunways:
            readNum(configMap, ["landingRunways"]) ??
            (runways.isEmpty
                ? null
                : countRunwaysByMode(runways, ["landing"])),
        takeoffRunways:
            readNum(configMap, ["takeoffRunways"]) ??
            (runways.isEmpty
                ? null
                : countRunwaysByMode(runways, ["take off", "takeoff"])),
        mixedRunways:
            readNum(configMap, ["mixedRunways"]) ??
            (runways.isEmpty ? null : countRunwaysByMode(runways, ["mixed"])),
        inboundRate: readNum(configMap, ["inboundRate", "inboundFlow"]),
        outboundRate: readNum(configMap, ["outboundRate", "outboundFlow"]),

        emergencyProbability: emergencyProbability == null
            ? null
            : (emergencyProbability <= 1
                ? emergencyProbability * 100
                : emergencyProbability),
        maxWaitTime: readNum(configMap, ["maxWaitTime"]),
        minFuelThreshold: readNum(configMap, ["minFuelThreshold"]),
        averageLandingDelay: readNum(resultMap, ["averageLandingDelay"]),
        averageHoldTime: readNum(resultMap, ["averageHoldTime"]),
        averageDepartureDelay: readNum(resultMap, ["averageDepartureDelay"]),
        averageWaitTime: readNum(resultMap, ["averageWaitTime"]),
        maxLandingDelay: readNum(resultMap, ["maxLandingDelay"]),
        maxDepartureDelay: readNum(resultMap, ["maxDepartureDelay"]),
        maxInboundQueue: readNum(resultMap, ["maxInboundQueue"]),
        maxOutboundQueue: readNum(resultMap, ["maxOutboundQueue"]),
        totalCancellations: readNum(resultMap, ["totalCancellations"]),
        totalDiversions: readNum(resultMap, ["totalDiversions"]),
        totalLandingAircraft: readNum(resultMap, ["totalLandingAircraft"]),
        totalDepartingAircraft: readNum(resultMap, ["totalDepartingAircraft"]),
        runwayUtilisation: () {
          final runwayUtilisation = readNum(resultMap, ["runwayUtilisation"]);
          if (runwayUtilisation == null) return null;
          return runwayUtilisation <= 1 ? runwayUtilisation * 100 : runwayUtilisation;
        }(),
        sectionAverageLandingDelayList: readDoubleList(
          resultMap,
          ["sectionAverageLandingDelayList"],
        ),
        sectionAverageDepartureDelayList: readDoubleList(
          resultMap,
          ["sectionAverageDepartureDelayList"],
        ),
      );
    } catch (_) {
      return const _ScenarioMetrics();
    }
  }

  /*Future<void> _copyToClipboard(BuildContext context, String content) async {
    await Clipboard.setData(ClipboardData(text: content));
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copied to clipboard.')),
    );
  }*/

  /*void _showExportPreview(
    BuildContext context, {
    required String title,
    required String content,
  }) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: SizedBox(
          width: 700,
          height: 400,
          child: SingleChildScrollView(
            child: SelectableText(content),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await _copyToClipboard(context, content);
            },
            child: const Text('Copy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }

  String _buildComparisonCsv() {
    final metrics1 = _metricsFor(_scenario1);
    final metrics2 = _metricsFor(_scenario2);

    final rows = <List<String>>[
      [
        "Metric",
        _scenario1?.name ?? "Scenario 1",
        _scenario2?.name ?? "Scenario 2",
      ],
      [
        "Landing Runways",
        _fmt(metrics1.landingRunways),
        _fmt(metrics2.landingRunways),
      ],
      [
        "Takeoff Runways",
        _fmt(metrics1.takeoffRunways),
        _fmt(metrics2.takeoffRunways),
      ],
      ["Mixed Runways", _fmt(metrics1.mixedRunways), _fmt(metrics2.mixedRunways)],
      ["Duration", _fmt(metrics1.duration), _fmt(metrics2.duration)],
      ["Inbound Rate", _fmt(metrics1.inboundRate), _fmt(metrics2.inboundRate)],
      ["Outbound Rate", _fmt(metrics1.outboundRate), _fmt(metrics2.outboundRate)],
      [
        "Emergency Probability",
        _fmt(metrics1.emergencyProbability),
        _fmt(metrics2.emergencyProbability),
      ],
      ["Max Wait Time", _fmt(metrics1.maxWaitTime), _fmt(metrics2.maxWaitTime)],
      [
        "Min Fuel Threshold",
        _fmt(metrics1.minFuelThreshold),
        _fmt(metrics2.minFuelThreshold),
      ],
      [
        "Average Landing Delay",
        _fmt(metrics1.averageLandingDelay),
        _fmt(metrics2.averageLandingDelay),
      ],
      [
        "Average Hold Time",
        _fmt(metrics1.averageHoldTime),
        _fmt(metrics2.averageHoldTime),
      ],
      [
        "Average Departure Delay",
        _fmt(metrics1.averageDepartureDelay),
        _fmt(metrics2.averageDepartureDelay),
      ],
      [
        "Average Wait Time",
        _fmt(metrics1.averageWaitTime),
        _fmt(metrics2.averageWaitTime),
      ],
      [
        "Maximum Landing Delay",
        _fmt(metrics1.maxLandingDelay),
        _fmt(metrics2.maxLandingDelay),
      ],
      [
        "Maximum Departure Delay",
        _fmt(metrics1.maxDepartureDelay),
        _fmt(metrics2.maxDepartureDelay),
      ],
      [
        "Maximum Inbound Queue Size",
        _fmt(metrics1.maxInboundQueue),
        _fmt(metrics2.maxInboundQueue),
      ],
      [
        "Maximum Outbound Queue Size",
        _fmt(metrics1.maxOutboundQueue),
        _fmt(metrics2.maxOutboundQueue),
      ],
      [
        "Total Cancellations",
        _fmt(metrics1.totalCancellations),
        _fmt(metrics2.totalCancellations),
      ],
      [
        "Total Diversions",
        _fmt(metrics1.totalDiversions),
        _fmt(metrics2.totalDiversions),
      ],
      [
        "Total Landing Aircraft",
        _fmt(metrics1.totalLandingAircraft),
        _fmt(metrics2.totalLandingAircraft),
      ],
      [
        "Total Departing Aircraft",
        _fmt(metrics1.totalDepartingAircraft),
        _fmt(metrics2.totalDepartingAircraft),
      ],
      [
        "Runway Utilisation Percentage",
        _fmtPercent(metrics1.runwayUtilisation?.toDouble()),
        _fmtPercent(metrics2.runwayUtilisation?.toDouble()),
      ],
    ];

    return rows.map((row) => row.map(_escapeCsv).join(",")).join("\n");
  }

  String _buildComparisonJson() {
    final metrics1 = _metricsFor(_scenario1);
    final metrics2 = _metricsFor(_scenario2);

    return const JsonEncoder.withIndent("  ").convert({
      "scenario1": {
        "record": _scenario1 == null
            ? null
            : {
                "id": _scenario1!.id,
                "name": _scenario1!.name,
                "createdAt": _scenario1!.createdAt.toIso8601String(),
                "description": _decodeDescription(_scenario1!.configJson),
              },
        "metrics": {
          "landingRunways": metrics1.landingRunways,
          "takeoffRunways": metrics1.takeoffRunways,
          "mixedRunways": metrics1.mixedRunways,
          "duration": metrics1.duration,
          "inboundRate": metrics1.inboundRate,
          "outboundRate": metrics1.outboundRate,
          "emergencyProbability": metrics1.emergencyProbability,
          "maxWaitTime": metrics1.maxWaitTime,
          "minFuelThreshold": metrics1.minFuelThreshold,
          "averageLandingDelay": metrics1.averageLandingDelay,
          "averageHoldTime": metrics1.averageHoldTime,
          "averageDepartureDelay": metrics1.averageDepartureDelay,
          "averageWaitTime": metrics1.averageWaitTime,
          "maxLandingDelay": metrics1.maxLandingDelay,
          "maxDepartureDelay": metrics1.maxDepartureDelay,
          "maxInboundQueue": metrics1.maxInboundQueue,
          "maxOutboundQueue": metrics1.maxOutboundQueue,
          "totalCancellations": metrics1.totalCancellations,
          "totalDiversions": metrics1.totalDiversions,
          "totalLandingAircraft": metrics1.totalLandingAircraft,
          "totalDepartingAircraft": metrics1.totalDepartingAircraft,
          "runwayUtilisation": metrics1.runwayUtilisation,
          "sectionAverageLandingDelayList":
              metrics1.sectionAverageLandingDelayList,
          "sectionAverageDepartureDelayList":
              metrics1.sectionAverageDepartureDelayList,
        },
      },
      "scenario2": {
        "record": _scenario2 == null
            ? null
            : {
                "id": _scenario2!.id,
                "name": _scenario2!.name,
                "createdAt": _scenario2!.createdAt.toIso8601String(),
                "description": _decodeDescription(_scenario2!.configJson),
              },
        "metrics": {
          "landingRunways": metrics2.landingRunways,
          "takeoffRunways": metrics2.takeoffRunways,
          "mixedRunways": metrics2.mixedRunways,
          "duration": metrics2.duration,
          "inboundRate": metrics2.inboundRate,
          "outboundRate": metrics2.outboundRate,
          "emergencyProbability": metrics2.emergencyProbability,
          "maxWaitTime": metrics2.maxWaitTime,
          "minFuelThreshold": metrics2.minFuelThreshold,
          "averageLandingDelay": metrics2.averageLandingDelay,
          "averageHoldTime": metrics2.averageHoldTime,
          "averageDepartureDelay": metrics2.averageDepartureDelay,
          "averageWaitTime": metrics2.averageWaitTime,
          "maxLandingDelay": metrics2.maxLandingDelay,
          "maxDepartureDelay": metrics2.maxDepartureDelay,
          "maxInboundQueue": metrics2.maxInboundQueue,
          "maxOutboundQueue": metrics2.maxOutboundQueue,
          "totalCancellations": metrics2.totalCancellations,
          "totalDiversions": metrics2.totalDiversions,
          "totalLandingAircraft": metrics2.totalLandingAircraft,
          "totalDepartingAircraft": metrics2.totalDepartingAircraft,
          "runwayUtilisation": metrics2.runwayUtilisation,
          "sectionAverageLandingDelayList":
              metrics2.sectionAverageLandingDelayList,
          "sectionAverageDepartureDelayList":
              metrics2.sectionAverageDepartureDelayList,
        },
      },
    });
  }

  String _escapeCsv(String value) {
    final escaped = value.replaceAll('"', '""');
    return '"$escaped"';
  }

  String _fmt(num? value, {int decimals = 2}) {
    if (value == null) return "-";
    if (value is int) return value.toString();
    return value.toStringAsFixed(decimals);
  }

  String _fmtPercent(double? value) {
    if (value == null) return "-";
    return "${value.toStringAsFixed(1)}%";
  }

  String _decodeDescription(String? configJson) {
    if (configJson == null || configJson.isEmpty) {
      return "No scenario details saved";
    }

    try {
      final decoded = jsonDecode(configJson);
      if (decoded is Map<String, dynamic>) {
        final landingRunways = decoded["landingRunways"]?.toString() ?? "n/a";
        final takeoffRunways = decoded["takeoffRunways"]?.toString() ?? "n/a";
        final mixedRunways = decoded["mixedRunways"]?.toString() ?? "n/a";
        final duration = decoded["duration"]?.toString() ?? "n/a";
        final inboundFlow =
            decoded["inboundRate"]?.toString() ??
            decoded["inboundFlow"]?.toString() ??
            "n/a";
        final outboundFlow =
            decoded["outboundRate"]?.toString() ??
            decoded["outboundFlow"]?.toString() ??
            "n/a";
        return "Landing: $landingRunways | Takeoff: $takeoffRunways | Mixed: $mixedRunways | Duration(h): $duration | In: $inboundFlow/h | Out: $outboundFlow/h";
      }
    } catch (_) {
      return configJson;
    }

    return configJson;
  }

  String _formatScenarioCreatedAt(DateTime createdAt) {
    final local = createdAt.toLocal();
    final twoDigit = (int v) => v.toString().padLeft(2, "0");
    return "${local.year}-${twoDigit(local.month)}-${twoDigit(local.day)} "
        "${twoDigit(local.hour)}:${twoDigit(local.minute)}";
  }*/

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF183059),
      appBar: AppBar(
        centerTitle: true,
        foregroundColor: Color(0xFFFFFFFF),
        backgroundColor: Color(0xFF276FBF),
        title: const Text("Compare Simulations"),
        shape: const Border(
          bottom: BorderSide(
            color: Color(0xFF183059),
            width: 5,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 900) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        height: 700,
                        child: _buildLeftPanel(),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 700,
                        child: _buildRightPanel(),
                      ),
                    ],
                  ),
                ),
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: _buildLeftPanel()),
                const SizedBox(width: 12),
                Expanded(child: _buildRightPanel()),
              ],
            );
          },
        ),
      ),

      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            spacing: 12,
            children: [
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF276FBF),
                    foregroundColor: Color(0xFFFFFFFF),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                onPressed: () {
                  widget.onNavigate(AppTab.results);
                },
                icon: const Icon(Icons.play_arrow),
                label: const Text("Results Screen"),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF276FBF),
                    foregroundColor: Color(0xFFFFFFFF),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                onPressed: () {
                  widget.onNavigate(AppTab.configuration);
                },
                icon: const Icon(Icons.settings),
                label: const Text("Configuration Screen"),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF276FBF),
                    foregroundColor: Color(0xFFFFFFFF),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                onPressed: () {
                  widget.onNavigate(AppTab.mainmenu);
                },
                icon: const Icon(Icons.home),
                label: const Text("Main Menu"),
              ),
            ],
          ),
        ),
      ),

    );
  }

  Widget _buildLeftPanel() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Color(0xFF276FBF),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF183059),
                    foregroundColor: Color(0xFFFFFFFF),
                  ),
                  onPressed: () => _loadScenario(1),
                  child: Text(
                    _scenario1 == null
                        ? "Load Scenario 1"
                        : "Replace Scenario 1",
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF183059),
                    foregroundColor: Color(0xFFFFFFFF),
                  ),
                  onPressed: () => _loadScenario(2),
                  child: Text(
                    _scenario2 == null
                        ? "Load Scenario 2"
                        : "Replace Scenario 2",
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _MetricComparisonTable(
              scenario1: _scenario1,
              scenario2: _scenario2,
              metrics1: _metricsFor(_scenario1),
              metrics2: _metricsFor(_scenario2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRightPanel() {
    final metrics1 = _metricsFor(_scenario1);
    final metrics2 = _metricsFor(_scenario2);

    return Column(
      children: [
        Expanded(
          child: SectionAverageGraph(
            title: "Average Landing Delay Over Time",
            multiSectionAverages: [
				metrics1.sectionAverageLandingDelayList,
				metrics2.sectionAverageLandingDelayList
			]
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: SectionAverageGraph(
            title: "Average Departure Delay Over Time",
            multiSectionAverages: [
				      metrics1.sectionAverageDepartureDelayList,
            	metrics2.sectionAverageDepartureDelayList
			        ]
          ),
        ),
      ],
    );
  }
}

class _ScenarioMetrics {
  const _ScenarioMetrics({
    this.landingRunways,
    this.takeoffRunways,
    this.mixedRunways,
    this.duration,
    this.inboundRate,
    this.outboundRate,
    this.emergencyProbability,
    this.maxWaitTime,
    this.minFuelThreshold,
    this.averageLandingDelay,
    this.averageHoldTime,
    this.averageDepartureDelay,
    this.averageWaitTime,
    this.maxLandingDelay,
    this.maxDepartureDelay,
    this.maxInboundQueue,
    this.maxOutboundQueue,
    this.totalCancellations,
    this.totalDiversions,
    this.totalLandingAircraft,
    this.totalDepartingAircraft,
    this.totalAircraft,
    this.runwayUtilisation,
    this.sectionAverageLandingDelayList = const [],
    this.sectionAverageDepartureDelayList = const [],
  });

  final num? landingRunways;
  final num? takeoffRunways;
  final num? mixedRunways;
  final num? duration;
  final num? inboundRate;
  final num? outboundRate;
  final num? emergencyProbability;
  final num? maxWaitTime;
  final num? minFuelThreshold;
  final num? averageLandingDelay;
  final num? averageHoldTime;
  final num? averageDepartureDelay;
  final num? averageWaitTime;
  final num? maxLandingDelay;
  final num? maxDepartureDelay;
  final num? maxInboundQueue;
  final num? maxOutboundQueue;
  final num? totalCancellations;
  final num? totalDiversions;
  final num? totalLandingAircraft;
  final num? totalDepartingAircraft;
  final num? totalAircraft;
  final num? runwayUtilisation;
  final List<double> sectionAverageLandingDelayList;
  final List<double> sectionAverageDepartureDelayList;
}

class _MetricComparisonTable extends StatelessWidget {
  const _MetricComparisonTable({
    required this.scenario1,
    required this.scenario2,
    required this.metrics1,
    required this.metrics2,
  });

  final ScenarioRecord? scenario1;
  final ScenarioRecord? scenario2;
  final _ScenarioMetrics metrics1;
  final _ScenarioMetrics metrics2;

  @override
  Widget build(BuildContext context) {
    final labelStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w900,
        );

    final rows = <Widget>[
      _MetricRow(
        label: "Landing Runways",
        value1: metrics1.landingRunways,
        value2: metrics2.landingRunways,
        lowerIsBetter: false,
        colorCode: false,
        decimals: 0,
        labelStyle: labelStyle,
      ),
      _MetricRow(
        label: "Takeoff Runways",
        value1: metrics1.takeoffRunways,
        value2: metrics2.takeoffRunways,
        lowerIsBetter: false,
        colorCode: false,
        decimals: 0,
        labelStyle: labelStyle,
      ),
      _MetricRow(
        label: "Mixed Runways",
        value1: metrics1.mixedRunways,
        value2: metrics2.mixedRunways,
        lowerIsBetter: false,
        colorCode: false,
        decimals: 0,
        labelStyle: labelStyle,
      ),
      _MetricRow(
        label: "Duration",
        value1: metrics1.duration,
        value2: metrics2.duration,
        lowerIsBetter: false,
        colorCode: false,
        suffix: " h",
        decimals: 0,
        labelStyle: labelStyle,
      ),
      _MetricRow(
        label: "Inbound Rate",
        value1: metrics1.inboundRate,
        value2: metrics2.inboundRate,
        lowerIsBetter: false,
        colorCode: false,
        suffix: "/h",
        decimals: 0,
        labelStyle: labelStyle,
      ),
      _MetricRow(
        label: "Outbound Rate",
        value1: metrics1.outboundRate,
        value2: metrics2.outboundRate,
        lowerIsBetter: false,
        colorCode: false,
        suffix: "/h",
        decimals: 0,
        labelStyle: labelStyle,
      ),
      _MetricRow(
        label: "Emergency Probability",
        value1: metrics1.emergencyProbability,
        value2: metrics2.emergencyProbability,
        lowerIsBetter: false,
        colorCode: false,
        suffix: "%",
        decimals: 2,
        labelStyle: labelStyle,
      ),
      _MetricRow(
        label: "Maximum Outbound Wait Time",
        value1: metrics1.maxWaitTime,
        value2: metrics2.maxWaitTime,
        lowerIsBetter: true,
        colorCode: false,
        suffix: " min",
        decimals: 0,
        labelStyle: labelStyle,
      ),
      _MetricRow(
        label: "Fuel Diversion Threshold",
        value1: metrics1.minFuelThreshold,
        value2: metrics2.minFuelThreshold,
        lowerIsBetter: false,
        colorCode: false,
        suffix: " min",
        decimals: 0,
        labelStyle: labelStyle,
      ),
      _MetricRow(
        label: "Average Landing Delay",
        value1: metrics1.averageLandingDelay,
        value2: metrics2.averageLandingDelay,
        lowerIsBetter: true,
        colorCode: true,
        suffix: " min",
        decimals: 2,
        labelStyle: labelStyle,
      ),
      _MetricRow(
        label: "Average Hold Time",
        value1: metrics1.averageHoldTime,
        value2: metrics2.averageHoldTime,
        lowerIsBetter: true,
        colorCode: true,
        suffix: " min",
        decimals: 2,
        labelStyle: labelStyle,
      ),
      _MetricRow(
        label: "Average Departure Delay",
        value1: metrics1.averageDepartureDelay,
        value2: metrics2.averageDepartureDelay,
        lowerIsBetter: true,
        colorCode: true,
        suffix: " min",
        decimals: 2,
        labelStyle: labelStyle,
      ),
      _MetricRow(
        label: "Average Wait Time",
        value1: metrics1.averageWaitTime,
        value2: metrics2.averageWaitTime,
        lowerIsBetter: true,
        colorCode: true,
        suffix: " min",
        decimals: 2,
        labelStyle: labelStyle,
      ),
      _MetricRow(
        label: "Maximum Landing Delay",
        value1: metrics1.maxLandingDelay,
        value2: metrics2.maxLandingDelay,
        lowerIsBetter: true,
        colorCode: true,
        suffix: " min",
        decimals: 0,
        labelStyle: labelStyle,
      ),
      _MetricRow(
        label: "Maximum Departure Delay",
        value1: metrics1.maxDepartureDelay,
        value2: metrics2.maxDepartureDelay,
        lowerIsBetter: true,
        colorCode: true,
        suffix: " min",
        decimals: 0,
        labelStyle: labelStyle,
      ),
      _MetricRow(
        label: "Maximum Inbound Queue Size",
        value1: metrics1.maxInboundQueue,
        value2: metrics2.maxInboundQueue,
        lowerIsBetter: true,
        colorCode: true,
        decimals: 0,
        labelStyle: labelStyle,
      ),
      _MetricRow(
        label: "Maximum Outbound Queue Size",
        value1: metrics1.maxOutboundQueue,
        value2: metrics2.maxOutboundQueue,
        lowerIsBetter: true,
        colorCode: true,
        decimals: 0,
        labelStyle: labelStyle,
      ),
      _MetricRow(
        label: "Total Aircraft",
        value1: metrics1.totalAircraft,
        value2: metrics2.totalAircraft,
        lowerIsBetter: false,
        colorCode: false,
        decimals: 0,
        labelStyle: labelStyle,
      ),
      _MetricRow(
        label: "Total Cancellations",
        value1: metrics1.totalCancellations,
        value2: metrics2.totalCancellations,
        lowerIsBetter: true,
        colorCode: true,
        decimals: 0,
        labelStyle: labelStyle,
      ),
      _MetricRow(
        label: "Total Diversions",
        value1: metrics1.totalDiversions,
        value2: metrics2.totalDiversions,
        lowerIsBetter: true,
        colorCode: true,
        decimals: 0,
        labelStyle: labelStyle,
      ),
      _MetricRow(
        label: "Total Landing Aircraft",
        value1: metrics1.totalLandingAircraft,
        value2: metrics2.totalLandingAircraft,
        lowerIsBetter: false,
        colorCode: false,
        decimals: 0,
        labelStyle: labelStyle,
      ),
      _MetricRow(
        label: "Total Departing Aircraft",
        value1: metrics1.totalDepartingAircraft,
        value2: metrics2.totalDepartingAircraft,
        lowerIsBetter: false,
        colorCode: false,
        decimals: 0,
        labelStyle: labelStyle,
      ),
      _MetricRow(
        label: "Runway Utilisation",
        value1: metrics1.runwayUtilisation,
        value2: metrics2.runwayUtilisation,
        lowerIsBetter: false,
        colorCode: true,
        suffix: "%",
        decimals: 1,
        labelStyle: labelStyle,
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Color(0xFFFFFFFF), width: 2),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          const headerHeight = 52.0;
          final rowHeight = (constraints.maxHeight - headerHeight) / rows.length;
          final effectiveRowHeight = rowHeight.clamp(44.0, 1000.0);
          final totalContentHeight =
              headerHeight + (effectiveRowHeight * rows.length);

          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight,
                minWidth: constraints.maxWidth,
              ),
              child: SizedBox(
                height: totalContentHeight < constraints.maxHeight
                    ? constraints.maxHeight
                    : totalContentHeight,
                child: Column(
                  children: [
                    SizedBox(
                      height: headerHeight,
                      child: Container(
                        decoration: const BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: Color(0xFFFFFFFF), width: 2),
                          ),
                        ),
                        child: Row(
                          children: [
                            const _HeaderCell(
                              flex: 2,
                              text: "",
                              alignLeft: true,
                            ),
                            const _VerticalDivider(),
                            _HeaderCell(
                              flex: 1,
                              text: scenario1?.name ?? "Scenario 1",
                            ),
                            const _VerticalDivider(),
                            _HeaderCell(
                              flex: 1,
                              text: scenario2?.name ?? "Scenario 2",
                            ),
                          ],
                        ),
                      ),
                    ),
                    for (final row in rows)
                      SizedBox(
                        height: effectiveRowHeight,
                        child: row,
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({
    required this.label,
    required this.value1,
    required this.value2,
    required this.lowerIsBetter,
    required this.colorCode,
    required this.labelStyle,
    this.suffix = "",
    this.decimals,
  });

  final String label;
  final num? value1;
  final num? value2;
  final bool lowerIsBetter;
  final bool colorCode;
  final TextStyle? labelStyle;
  final String suffix;
  final int? decimals;

  @override
  Widget build(BuildContext context) {
    Color? color1;
    Color? color2;

    if (colorCode && value1 != null && value2 != null && value1 != value2) {
      final value1Better =
          lowerIsBetter ? value1! < value2! : value1! > value2!;
      color1 = value1Better ? Color(0xFF66FF66) : Color(0xFFf9665e);
      color2 = value1Better ? Color(0xFFf9665e) : Color(0xFF66FF66);
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          flex: 2,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(label, style: labelStyle),
            ),
          ),
        ),
        const _VerticalDivider(),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                _formatValue(value1, suffix: suffix, decimals: decimals),
                style: TextStyle(
                  color: color1,
                  fontWeight:
                      color1 == null ? FontWeight.w500 : FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
        const _VerticalDivider(),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                _formatValue(value2, suffix: suffix, decimals: decimals),
                style: TextStyle(
                  color: color2,
                  fontWeight:
                      color2 == null ? FontWeight.w500 : FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _formatValue(num? value, {required String suffix, int? decimals}) {
    if (value == null) return "-";
    if (value is int || decimals == 0) {
      return "${value.toStringAsFixed(0)}$suffix";
    }
    if (decimals != null) {
      return "${value.toStringAsFixed(decimals)}$suffix";
    }
    return "$value$suffix";
  }
}

class _HeaderCell extends StatelessWidget {
  const _HeaderCell({
    required this.flex,
    required this.text,
    this.alignLeft = false,
  });

  final int flex;
  final String text;
  final bool alignLeft;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        child: Text(
          text,
          textAlign: alignLeft ? TextAlign.left : TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  const _VerticalDivider();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: double.infinity,
      child: VerticalDivider(
        width: 2,
        thickness: 2,
        color: Color(0xFFFFFFFF),
      ),
    );
  }
}

/*class _GraphPlaceholder extends StatelessWidget {
  const _GraphPlaceholder({
    required this.title,
    required this.data1,
    required this.data2,
  });

  final String title;
  final List<double> data1;
  final List<double> data2;

  @override
  Widget build(BuildContext context) {
    final hasAnyData = data1.isNotEmpty || data2.isNotEmpty;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Color(0xFFA2C2E1),
      ),
      alignment: Alignment.center,
      padding: const EdgeInsets.all(16),
      child: Text(
        hasAnyData ? "$title chart goes here" : "No data available for $title",
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 22),
      ),
    );
  }
}*/