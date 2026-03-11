import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/temp_probe.dart';
import '../models/temp_reading.dart';

enum TimeRange {
  fiveMin('5 min', Duration(minutes: 5)),
  fifteenMin('15 min', Duration(minutes: 15)),
  oneHour('1 hr', Duration(hours: 1)),
  all('All', null);

  final String label;
  final Duration? duration;

  const TimeRange(this.label, this.duration);
}

class ChartPanel extends StatefulWidget {
  final List<TempProbe> availableProbes;
  final int panelIndex;

  const ChartPanel({
    super.key,
    required this.availableProbes,
    required this.panelIndex,
  });

  @override
  State<ChartPanel> createState() => _ChartPanelState();
}

class _ChartPanelState extends State<ChartPanel> {
  String? _selectedProbeId;
  TimeRange _selectedRange = TimeRange.fifteenMin;

  @override
  void initState() {
    super.initState();
    if (widget.availableProbes.isNotEmpty) {
      _selectedProbeId = widget.availableProbes.first.id;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            if (_selectedProbeId != null)
              Expanded(child: _buildChart())
            else
              const Expanded(
                child: Center(
                  child: Text(
                    'No probes available',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Expanded(
          child: DropdownButton<String>(
            value: _selectedProbeId,
            isExpanded: true,
            hint: const Text('Select probe'),
            items: widget.availableProbes.map((probe) {
              return DropdownMenuItem(
                value: probe.id,
                child: Text(probe.displayName),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedProbeId = value;
              });
            },
          ),
        ),
        const SizedBox(width: 16),
        DropdownButton<TimeRange>(
          value: _selectedRange,
          items: TimeRange.values.map((range) {
            return DropdownMenuItem(
              value: range,
              child: Text(range.label),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _selectedRange = value;
              });
            }
          },
        ),
      ],
    );
  }

  Widget _buildChart() {
    final probe = widget.availableProbes.firstWhere(
      (p) => p.id == _selectedProbeId,
    );

    List<TempReading> readings = probe.history;

    if (_selectedRange.duration != null) {
      final cutoff = DateTime.now().subtract(_selectedRange.duration!);
      readings = readings.where((r) => r.timestamp.isAfter(cutoff)).toList();
    }

    if (readings.isEmpty) {
      return const Center(
        child: Text(
          'No data available for this time range',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    final internalSpots = <FlSpot>[];
    final ambientSpots = <FlSpot>[];

    final startTime = readings.first.timestamp.millisecondsSinceEpoch.toDouble();

    for (var reading in readings) {
      final x = (reading.timestamp.millisecondsSinceEpoch - startTime) / 1000.0;
      internalSpots.add(FlSpot(x, reading.internalTemp));
      ambientSpots.add(FlSpot(x, reading.ambientTemp));
    }

    double minY = double.infinity;
    double maxY = double.negativeInfinity;

    for (var reading in readings) {
      if (reading.internalTemp < minY) minY = reading.internalTemp;
      if (reading.internalTemp > maxY) maxY = reading.internalTemp;
      if (reading.ambientTemp < minY) minY = reading.ambientTemp;
      if (reading.ambientTemp > maxY) maxY = reading.ambientTemp;
    }

    final padding = (maxY - minY) * 0.1;
    minY -= padding;
    maxY += padding;

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey[800]!,
              strokeWidth: 1,
            );
          },
          getDrawingVerticalLine: (value) {
            return FlLine(
              color: Colors.grey[800]!,
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: _getBottomInterval(readings),
              getTitlesWidget: (value, meta) {
                final minutes = (value / 60).floor();
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    '${minutes}m',
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 10,
                    ),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  '${value.toStringAsFixed(0)}°',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 10,
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Colors.grey[800]!, width: 1),
        ),
        minX: 0,
        maxX: internalSpots.last.x,
        minY: minY,
        maxY: maxY,
        lineBarsData: [
          LineChartBarData(
            spots: internalSpots,
            isCurved: true,
            color: const Color(0xFFFF9F0A),
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: const Color(0xFFFF9F0A).withOpacity(0.1),
            ),
          ),
          LineChartBarData(
            spots: ambientSpots,
            isCurved: true,
            color: Colors.blue,
            barWidth: 2,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.blue.withOpacity(0.05),
            ),
          ),
        ],
      ),
    );
  }

  double _getBottomInterval(List<TempReading> readings) {
    if (readings.isEmpty) return 60;

    final duration = readings.last.timestamp.difference(readings.first.timestamp);
    final seconds = duration.inSeconds;

    if (seconds < 300) return 60;
    if (seconds < 900) return 120;
    if (seconds < 3600) return 300;
    return 600;
  }
}
