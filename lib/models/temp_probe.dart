import 'package:hive/hive.dart';
import 'temp_reading.dart';

part 'temp_probe.g.dart';

@HiveType(typeId: 1)
class TempProbe extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String nickname;

  @HiveField(3)
  int colorValue;

  @HiveField(4)
  double? targetInternal;

  @HiveField(5)
  double? targetAmbient;

  @HiveField(6)
  List<TempReading> history;

  @HiveField(7)
  double batteryPercent;

  @HiveField(8)
  String modelType; // 'TP' or 'I' series

  @HiveField(9)
  DateTime lastSeen;

  @HiveField(10)
  bool active;

  TempProbe({
    required this.id,
    required this.name,
    this.nickname = '',
    this.colorValue = 0xFFFF9F0A, // Default orange
    this.targetInternal,
    this.targetAmbient,
    List<TempReading>? history,
    this.batteryPercent = 100.0,
    this.modelType = 'TP',
    DateTime? lastSeen,
    this.active = true,
  })  : history = history ?? [],
        lastSeen = lastSeen ?? DateTime.now();

  String get displayName => nickname.isNotEmpty ? nickname : name;

  TempReading? get latestReading =>
      history.isNotEmpty ? history.last : null;

  void addReading(TempReading reading) {
    history.add(reading);
    if (history.length > 10000) {
      history.removeAt(0);
    }
    lastSeen = DateTime.now();
  }
}
