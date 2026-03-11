import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/temp_probe.dart';
import 'temperature_display.dart';

class ProbeCard extends StatelessWidget {
  final TempProbe probe;

  const ProbeCard({super.key, required this.probe});

  @override
  Widget build(BuildContext context) {
    final reading = probe.latestReading;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () {
          context.push('/probe/${probe.id}');
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      probe.displayName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _buildBatteryIndicator(),
                ],
              ),
              const SizedBox(height: 16),
              if (reading != null) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: TemperatureDisplay(
                        temperature: reading.internalTemp,
                        label: 'Internal',
                        large: true,
                      ),
                    ),
                    Expanded(
                      child: TemperatureDisplay(
                        temperature: reading.ambientTemp,
                        label: 'Ambient',
                        large: false,
                      ),
                    ),
                  ],
                ),
                if (probe.targetInternal != null) ...[
                  const SizedBox(height: 16),
                  _buildTargetProgress(),
                ],
              ] else
                const Text(
                  'No data',
                  style: TextStyle(color: Colors.grey),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBatteryIndicator() {
    final batteryLevel = probe.batteryPercent;
    Color batteryColor;

    if (batteryLevel > 50) {
      batteryColor = Colors.green;
    } else if (batteryLevel > 20) {
      batteryColor = Colors.orange;
    } else {
      batteryColor = Colors.red;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          batteryLevel > 80
              ? Icons.battery_full
              : batteryLevel > 50
                  ? Icons.battery_5_bar
                  : batteryLevel > 20
                      ? Icons.battery_3_bar
                      : Icons.battery_1_bar,
          color: batteryColor,
          size: 20,
        ),
        const SizedBox(width: 4),
        Text(
          '${batteryLevel.toStringAsFixed(0)}%',
          style: TextStyle(
            color: batteryColor,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildTargetProgress() {
    final reading = probe.latestReading;
    if (reading == null || probe.targetInternal == null) {
      return const SizedBox.shrink();
    }

    final current = reading.internalTemp;
    final target = probe.targetInternal!;
    final progress = (current / target).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Target: ${target.toStringAsFixed(1)}°C',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            Text(
              '${(progress * 100).toStringAsFixed(0)}%',
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFFFF9F0A),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: Colors.grey[800],
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFF9F0A)),
          ),
        ),
      ],
    );
  }
}
