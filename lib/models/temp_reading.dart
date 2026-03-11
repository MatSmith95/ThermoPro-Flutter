import 'package:hive/hive.dart';

part 'temp_reading.g.dart';

@HiveType(typeId: 0)
class TempReading extends HiveObject {
  @HiveField(0)
  final DateTime timestamp;

  @HiveField(1)
  final double internalTemp;

  @HiveField(2)
  final double ambientTemp;

  @HiveField(3)
  final double battery;

  TempReading({
    required this.timestamp,
    required this.internalTemp,
    required this.ambientTemp,
    required this.battery,
  });

  Map<String, dynamic> toJson() => {
        'timestamp': timestamp.toIso8601String(),
        'internalTemp': internalTemp,
        'ambientTemp': ambientTemp,
        'battery': battery,
      };

  factory TempReading.fromJson(Map<String, dynamic> json) => TempReading(
        timestamp: DateTime.parse(json['timestamp']),
        internalTemp: json['internalTemp'],
        ambientTemp: json['ambientTemp'],
        battery: json['battery'],
      );
}
