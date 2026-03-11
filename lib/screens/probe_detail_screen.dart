import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/probe_controller.dart';
import '../widgets/temperature_display.dart';

class ProbeDetailScreen extends StatefulWidget {
  final String probeId;

  const ProbeDetailScreen({super.key, required this.probeId});

  @override
  State<ProbeDetailScreen> createState() => _ProbeDetailScreenState();
}

class _ProbeDetailScreenState extends State<ProbeDetailScreen> {
  final _nicknameController = TextEditingController();
  double _targetInternal = 70.0;
  double _targetAmbient = 100.0;
  Color _selectedColor = const Color(0xFFFF9F0A);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = context.read<ProbeController>();
      final probe = controller.getProbe(widget.probeId);
      if (probe != null) {
        _nicknameController.text = probe.nickname;
        _targetInternal = probe.targetInternal ?? 70.0;
        _targetAmbient = probe.targetAmbient ?? 100.0;
        _selectedColor = Color(probe.colorValue);
      }
    });
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Probe Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveSettings,
          ),
        ],
      ),
      body: Consumer<ProbeController>(
        builder: (context, controller, child) {
          final probe = controller.getProbe(widget.probeId);
          if (probe == null) {
            return const Center(child: Text('Probe not found'));
          }

          final reading = probe.latestReading;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        if (reading != null) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              TemperatureDisplay(
                                temperature: reading.internalTemp,
                                label: 'Internal',
                                large: true,
                              ),
                              TemperatureDisplay(
                                temperature: reading.ambientTemp,
                                label: 'Ambient',
                                large: true,
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Battery: ${probe.batteryPercent.toStringAsFixed(0)}%',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ] else
                          const Text('No data available'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Settings',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _nicknameController,
                  decoration: const InputDecoration(
                    labelText: 'Nickname',
                    hintText: 'Enter probe nickname',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Target Internal: ${_targetInternal.toStringAsFixed(1)}°C',
                  style: const TextStyle(fontSize: 16),
                ),
                Slider(
                  value: _targetInternal,
                  min: 0,
                  max: 200,
                  divisions: 200,
                  activeColor: const Color(0xFFFF9F0A),
                  onChanged: (value) {
                    setState(() {
                      _targetInternal = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
                Text(
                  'Target Ambient: ${_targetAmbient.toStringAsFixed(1)}°C',
                  style: const TextStyle(fontSize: 16),
                ),
                Slider(
                  value: _targetAmbient,
                  min: 0,
                  max: 300,
                  divisions: 300,
                  activeColor: const Color(0xFFFF9F0A),
                  onChanged: (value) {
                    setState(() {
                      _targetAmbient = value;
                    });
                  },
                ),
                const SizedBox(height: 24),
                const Text(
                  'Color',
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _buildColorOption(const Color(0xFFFF9F0A)),
                    _buildColorOption(Colors.red),
                    _buildColorOption(Colors.blue),
                    _buildColorOption(Colors.green),
                    _buildColorOption(Colors.purple),
                    _buildColorOption(Colors.yellow),
                  ],
                ),
                const SizedBox(height: 24),
                if (reading != null && probe.targetInternal != null)
                  _buildTimeToTarget(probe),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildColorOption(Color color) {
    final isSelected = _selectedColor.value == color.value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedColor = color;
        });
      },
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: isSelected
              ? Border.all(color: Colors.white, width: 3)
              : null,
        ),
        child: isSelected
            ? const Icon(Icons.check, color: Colors.white)
            : null,
      ),
    );
  }

  Widget _buildTimeToTarget(probe) {
    final controller = context.read<ProbeController>();
    final prediction = controller.predictionService.predictTimeToTarget(probe);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Time to Target',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (prediction == null)
              const Text(
                'Prediction will be available after sufficient data',
                style: TextStyle(color: Colors.grey),
              )
            else if (prediction.complete)
              const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green),
                  SizedBox(width: 8),
                  Text(
                    'Target reached!',
                    style: TextStyle(color: Colors.green, fontSize: 16),
                  ),
                ],
              )
            else if (prediction.stalling)
              const Row(
                children: [
                  Icon(Icons.warning, color: Colors.orange),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Temperature is stalling or not rising',
                      style: TextStyle(color: Colors.orange, fontSize: 16),
                    ),
                  ),
                ],
              )
            else if (prediction.minutesRemaining != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Estimated: ${prediction.minutesRemaining} minutes',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFFFF9F0A),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Rate: ${prediction.ratePerMinute?.toStringAsFixed(2)}°C/min',
                    style: const TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  void _saveSettings() {
    final controller = context.read<ProbeController>();
    controller.updateProbeNickname(widget.probeId, _nicknameController.text);
    controller.updateProbeTarget(
      widget.probeId,
      _targetInternal,
      _targetAmbient,
    );
    controller.updateProbeColor(widget.probeId, _selectedColor.value);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Settings saved')),
    );
  }
}
