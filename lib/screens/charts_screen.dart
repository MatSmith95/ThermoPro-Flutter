import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/probe_controller.dart';
import '../widgets/chart_panel.dart';

class ChartsScreen extends StatefulWidget {
  const ChartsScreen({super.key});

  @override
  State<ChartsScreen> createState() => _ChartsScreenState();
}

class _ChartsScreenState extends State<ChartsScreen> {
  int _numCharts = 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Charts'),
        actions: [
          PopupMenuButton<int>(
            icon: const Icon(Icons.grid_view),
            initialValue: _numCharts,
            onSelected: (value) {
              setState(() {
                _numCharts = value;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 1, child: Text('1 Chart')),
              const PopupMenuItem(value: 2, child: Text('2 Charts')),
              const PopupMenuItem(value: 3, child: Text('3 Charts')),
              const PopupMenuItem(value: 4, child: Text('4 Charts')),
            ],
          ),
        ],
      ),
      body: Consumer<ProbeController>(
        builder: (context, controller, child) {
          if (controller.probes.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.show_chart, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No probes available',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Start scanning to see charts',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return StreamBuilder(
            stream: Stream.periodic(const Duration(seconds: 2)),
            builder: (context, snapshot) {
              return _buildChartGrid(controller);
            },
          );
        },
      ),
    );
  }

  Widget _buildChartGrid(ProbeController controller) {
    if (_numCharts == 1) {
      return ChartPanel(
        availableProbes: controller.probes,
        panelIndex: 0,
      );
    }

    if (_numCharts == 2) {
      return Column(
        children: [
          Expanded(
            child: ChartPanel(
              availableProbes: controller.probes,
              panelIndex: 0,
            ),
          ),
          Expanded(
            child: ChartPanel(
              availableProbes: controller.probes,
              panelIndex: 1,
            ),
          ),
        ],
      );
    }

    if (_numCharts == 3) {
      return Column(
        children: [
          Expanded(
            child: ChartPanel(
              availableProbes: controller.probes,
              panelIndex: 0,
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: ChartPanel(
                    availableProbes: controller.probes,
                    panelIndex: 1,
                  ),
                ),
                Expanded(
                  child: ChartPanel(
                    availableProbes: controller.probes,
                    panelIndex: 2,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: ChartPanel(
                  availableProbes: controller.probes,
                  panelIndex: 0,
                ),
              ),
              Expanded(
                child: ChartPanel(
                  availableProbes: controller.probes,
                  panelIndex: 1,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: ChartPanel(
                  availableProbes: controller.probes,
                  panelIndex: 2,
                ),
              ),
              Expanded(
                child: ChartPanel(
                  availableProbes: controller.probes,
                  panelIndex: 3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
