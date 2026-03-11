import 'package:flutter/material.dart';

class TemperatureDisplay extends StatefulWidget {
  final double temperature;
  final String label;
  final bool large;

  const TemperatureDisplay({
    super.key,
    required this.temperature,
    this.label = '',
    this.large = false,
  });

  @override
  State<TemperatureDisplay> createState() => _TemperatureDisplayState();
}

class _TemperatureDisplayState extends State<TemperatureDisplay> {
  bool _useFahrenheit = false;

  double get displayTemp {
    if (_useFahrenheit) {
      return (widget.temperature * 9 / 5) + 32;
    }
    return widget.temperature;
  }

  String get unit => _useFahrenheit ? '°F' : '°C';

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _useFahrenheit = !_useFahrenheit;
        });
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.label.isNotEmpty)
            Text(
              widget.label,
              style: TextStyle(
                fontSize: widget.large ? 14 : 12,
                color: Colors.grey[400],
              ),
            ),
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                displayTemp.toStringAsFixed(1),
                style: TextStyle(
                  fontSize: widget.large ? 48 : 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                unit,
                style: TextStyle(
                  fontSize: widget.large ? 24 : 14,
                  fontWeight: FontWeight.normal,
                  color: Colors.grey[400],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
