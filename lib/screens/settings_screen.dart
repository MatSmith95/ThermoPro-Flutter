import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/probe_controller.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _useFahrenheit = false;
  bool _notificationsEnabled = true;
  double _batteryThreshold = 15.0;
  double _stallThreshold = 0.5;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          _buildSection('Temperature'),
          SwitchListTile(
            title: const Text('Use Fahrenheit'),
            subtitle: const Text('Display temperatures in °F instead of °C'),
            value: _useFahrenheit,
            activeColor: const Color(0xFFFF9F0A),
            onChanged: (value) {
              setState(() {
                _useFahrenheit = value;
              });
            },
          ),
          const Divider(),
          _buildSection('Notifications'),
          SwitchListTile(
            title: const Text('Enable Alerts'),
            subtitle: const Text('Receive notifications for probe events'),
            value: _notificationsEnabled,
            activeColor: const Color(0xFFFF9F0A),
            onChanged: (value) {
              setState(() {
                _notificationsEnabled = value;
              });
            },
          ),
          const Divider(),
          _buildSection('Alert Thresholds'),
          ListTile(
            title: const Text('Battery Low Alert'),
            subtitle: Text('Alert when battery drops below ${_batteryThreshold.toStringAsFixed(0)}%'),
          ),
          Slider(
            value: _batteryThreshold,
            min: 5,
            max: 30,
            divisions: 25,
            activeColor: const Color(0xFFFF9F0A),
            label: '${_batteryThreshold.toStringAsFixed(0)}%',
            onChanged: (value) {
              setState(() {
                _batteryThreshold = value;
              });
            },
          ),
          ListTile(
            title: const Text('Stall Detection Threshold'),
            subtitle: Text('Alert if temp rises less than ${_stallThreshold.toStringAsFixed(1)}°C in 10 minutes'),
          ),
          Slider(
            value: _stallThreshold,
            min: 0.1,
            max: 2.0,
            divisions: 19,
            activeColor: const Color(0xFFFF9F0A),
            label: '${_stallThreshold.toStringAsFixed(1)}°C',
            onChanged: (value) {
              setState(() {
                _stallThreshold = value;
              });
            },
          ),
          const Divider(),
          _buildSection('About'),
          const ListTile(
            title: Text('App Version'),
            subtitle: Text('1.0.0'),
          ),
          const ListTile(
            title: Text('ThermoPro Flutter'),
            subtitle: Text('A cross-platform app for monitoring TempSpike temperature probes'),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Consumer<ProbeController>(
              builder: (context, controller, child) {
                return OutlinedButton.icon(
                  onPressed: () {
                    _showClearDataDialog(context, controller);
                  },
                  icon: const Icon(Icons.delete_forever, color: Colors.red),
                  label: const Text(
                    'Clear All Probe Data',
                    style: TextStyle(color: Colors.red),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Color(0xFFFF9F0A),
        ),
      ),
    );
  }

  void _showClearDataDialog(BuildContext context, ProbeController controller) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Data'),
        content: const Text(
          'This will delete all probe history and settings. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              for (var probe in controller.probes) {
                controller.clearProbeHistory(probe.id);
              }
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('All probe data cleared')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }
}
