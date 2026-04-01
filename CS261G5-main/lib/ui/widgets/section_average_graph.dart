import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class SectionAverageGraph extends StatelessWidget {
  /// Title of the Graph
  final String title;

  /// A list of lists containing the average delay for each 10-minute section.
  /// Each inner list represents a separate line on the graph.
  final List<List<double>> multiSectionAverages;

  /// Colors to assign to each line. If there are more lines than colors, 
  /// it will loop back to the start of the list.
  final List<Color> lineColors = const [
    Color(0xFF183059),
    Colors.red,
    Colors.green,
    Colors.orange,
    Colors.purple,
  ];

  const SectionAverageGraph({
    super.key, 
    required this.title,
    required this.multiSectionAverages,
  });

  @override
  Widget build(BuildContext context) {
    // Check if the main list is empty, or if all inner lists are empty
    if ((multiSectionAverages.isEmpty || multiSectionAverages.every((list) => list.isEmpty))) {
      return const Center(
        child: Text("No simulation data available to graph."),
      );
    }

    // Calculate interval to show at most 30 labels on x-axis
    int dataLength = multiSectionAverages[0].length;
    double xAxisInterval = (dataLength / 30).ceil().toDouble();
    if (xAxisInterval < 1) xAxisInterval = 1;

    return Container (
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF276FBF),
        borderRadius: BorderRadius.circular(20),
      ),
      height: 480,
      width: double.infinity,
      child: Column(
        children: [
          Padding( // Title
            padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFFFFFFFF),
              ),
            ),
          ),
          Expanded( // Graph
            child: Padding(
              padding: const EdgeInsets.only(right: 24.0, top: 8.0, bottom: 8.0),
              child: LineChart(
                LineChartData(
            // Tooltips when tapping on points - show x and y values
            backgroundColor: Color(0xFFA2C2E1),
            lineTouchData: LineTouchData(
              handleBuiltInTouches: true,
              touchTooltipData: LineTouchTooltipData(
                getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                  return touchedBarSpots.map((barSpot) {
                    final xValue = (barSpot.x.toInt() + 1) * 10; // Convert to minutes
                    return LineTooltipItem(
                      'Time: $xValue minutes\nDelay: ${barSpot.y.toStringAsFixed(2)} minutes',
                      const TextStyle(color: Colors.white),
                    );
                  }).toList();
                },
              ),
            ),
            
            // Grid styling
            gridData: const FlGridData(show: true, drawVerticalLine: true),
            
            // Explicit bounds to prevent Infinity errors
            minX: 0,
            //maxX: (multiSectionAverages.isNotEmpty ? multiSectionAverages[0].length - 1 : 1).toDouble(),
            minY: 0,
            //maxY: 5,
            
            // Axis Titles & Labels
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              
              // Y-axis (Average Delay)
              leftTitles: AxisTitles(
                axisNameWidget: const Text(
                  'Avg Delay (minutes)', 
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFFFFFFF))
                ),
                axisNameSize: 24,
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 40,
                  getTitlesWidget: (value, meta) {
                    return Padding( 
                      padding: const EdgeInsets.only(left: 8.0),
                      child: Text(value.toStringAsFixed(1), style: const TextStyle(fontSize: 10, color: Color(0xFFFFFFFF)))
                    );
                  },
                ),
              ),
              
              // X-axis (Time Sections)
              bottomTitles: AxisTitles(
                axisNameWidget: const Text(
                  'Simulation Time (minutes)', 
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFFFFFFF))
                ),
                axisNameSize: 24,
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: xAxisInterval, // Show at most 30 labels
                  getTitlesWidget: (value, meta) {
                    // Convert the index (0, 1, 2) into 10-minute increments (10m, 20m, 30m)
                    int minutes = (value.toInt() + 1) * 10;
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text('$minutes', style: const TextStyle(fontSize: 10, color: Color(0xFFFFFFFF))),
                    );
                  },
                ),
              ),
            ),
            
            // Border Styling
            borderData: FlBorderData(
              show: true,
              border: Border.all(color: Colors.grey.withOpacity(0.5)),
            ),
            
            // The actual line data - Mapping over the 2D list
            lineBarsData: multiSectionAverages.asMap().entries.map((entry) {
              int lineIndex = entry.key;
              List<double> dataPoints = entry.value;
              
              // Assign a color from our list, looping if necessary
              Color lineColor = lineColors[lineIndex % lineColors.length];

              return LineChartBarData(
                // Map the inner list of doubles into FlSpot coordinates
                spots: dataPoints.asMap().entries.map((pointEntry) {
                  return FlSpot(pointEntry.key.toDouble(), pointEntry.value);
                }).toList(),
                
                isCurved: false, // Straight lines
                color: lineColor,
                barWidth: 3,
                isStrokeCapRound: true,
                dotData: const FlDotData(show: true),
                belowBarData: BarAreaData(show: false), // No fill underneath
              );
            }).toList(),
              ),
              ),
            ),
          ),
        ],
      )
    );
  }
}