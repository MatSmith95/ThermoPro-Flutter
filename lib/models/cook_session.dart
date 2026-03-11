import 'package:hive/hive.dart';
import 'temp_reading.dart';

part 'cook_session.g.dart';

@HiveType(typeId: 2)
class ProbeHistory extends HiveObject {
  @HiveField(0)
  final String probeId;

  @HiveField(1)
  final String probeName;

  @HiveField(2)
  final List<TempReading> readings;

  ProbeHistory({
    required this.probeId,
    required this.probeName,
    required this.readings,
  });
}

@HiveType(typeId: 3)
class ProbeSettings extends HiveObject {
  @HiveField(0)
  final String probeId;

  @HiveField(1)
  final double? targetInternal;

  @HiveField(2)
  final double? targetAmbient;

  @HiveField(3)
  final int colorValue;

  ProbeSettings({
    required this.probeId,
    this.targetInternal,
    this.targetAmbient,
    required this.colorValue,
  });
}

@HiveType(typeId: 4)
class CookSession extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  final DateTime startTime;

  @HiveField(3)
  DateTime? endTime;

  @HiveField(4)
  final List<ProbeHistory> probeHistories;

  @HiveField(5)
  final List<ProbeSettings> probeSettings;

  CookSession({
    required this.id,
    required this.name,
    required this.startTime,
    this.endTime,
    required this.probeHistories,
    required this.probeSettings,
  });

  bool get isActive => endTime == null;

  Duration get duration {
    final end = endTime ?? DateTime.now();
    return end.difference(startTime);
  }
}
