import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../controllers/probe_controller.dart';
import '../widgets/probe_card.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ThermoPro'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart),
            onPressed: () => context.push('/charts'),
            tooltip: 'Charts',
          ),
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => context.push('/sessions'),
            tooltip: 'Sessions',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push('/settings'),
            tooltip: 'Settings',
          ),
        ],
      ),
      body: Consumer<ProbeController>(
        builder: (context, controller, child) {
          return Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                color: Theme.of(context).colorScheme.surface,
                child: Row(
                  children: [
                    Icon(
                      controller.isScanning
                          ? Icons.bluetooth_searching
                          : Icons.bluetooth_disabled,
                      color: controller.isScanning
                          ? const Color(0xFFFF9F0A)
                          : Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        controller.statusMessage,
                        style: TextStyle(
                          color: controller.isScanning
                              ? Colors.white
                              : Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: controller.probes.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.bluetooth,
                              size: 64,
                              color: Colors.grey[700],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              controller.isScanning
                                  ? 'Scanning for probes...'
                                  : 'No probes found',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[500],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              controller.isScanning
                                  ? 'Make sure your TempSpike is nearby'
                                  : 'Tap the scan button to start',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: controller.probes.length,
                        itemBuilder: (context, index) {
                          final probe = controller.probes[index];
                          return ProbeCard(probe: probe);
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: Consumer<ProbeController>(
        builder: (context, controller, child) {
          return FloatingActionButton.extended(
            onPressed: () {
              if (controller.isScanning) {
                controller.stopScanning();
              } else {
                controller.startScanning();
              }
            },
            icon: Icon(
              controller.isScanning ? Icons.stop : Icons.bluetooth_searching,
            ),
            label: Text(controller.isScanning ? 'Stop' : 'Scan'),
          );
        },
      ),
    );
  }
}
