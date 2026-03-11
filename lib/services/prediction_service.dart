import '../models/temp_probe.dart';

class PredictionResult {
  final bool complete;
  final int? minutesRemaining;
  final double? ratePerMinute;
  final double currentTemp;
  final bool stalling;

  PredictionResult({
    required this.complete,
    this.minutesRemaining,
    this.ratePerMinute,
    required this.currentTemp,
    this.stalling = false,
  });
}

class PredictionService {
  PredictionResult? predictTimeToTarget(TempProbe probe) {
    if (probe.targetInternal == null) {
      return null;
    }

    final history = probe.history;
    if (history.length < 10) {
      return null;
    }

    // Get recent history (last 5 minutes)
    final fiveMinutesAgo = DateTime.now().subtract(const Duration(minutes: 5));
    final recentHistory = history.where((r) => r.timestamp.isAfter(fiveMinutesAgo)).toList();

    if (recentHistory.length < 5) {
      return null;
    }

    // Use last 20 readings for better accuracy
    final analysisHistory = history.length > 20 ? history.sublist(history.length - 20) : history;

    // Linear regression
    final n = analysisHistory.length;
    double sumX = 0, sumY = 0, sumXY = 0, sumX2 = 0;

    final baseTime = analysisHistory.first.timestamp.millisecondsSinceEpoch / 1000.0;

    for (var i = 0; i < n; i++) {
      final x = (analysisHistory[i].timestamp.millisecondsSinceEpoch / 1000.0) - baseTime;
      final y = analysisHistory[i].internalTemp;
      sumX += x;
      sumY += y;
      sumXY += x * y;
      sumX2 += x * x;
    }

    final slope = (n * sumXY - sumX * sumY) / (n * sumX2 - sumX * sumX);
    final ratePerMinute = slope * 60;

    final currentTemp = recentHistory.last.internalTemp;
    final target = probe.targetInternal!;

    // Check if stalling (< 0.5°C rise in 10 minutes)
    final tenMinutesAgo = DateTime.now().subtract(const Duration(minutes: 10));
    final tenMinHistory = history.where((r) => r.timestamp.isAfter(tenMinutesAgo)).toList();
    bool stalling = false;

    if (tenMinHistory.length >= 5) {
      final rise = tenMinHistory.last.internalTemp - tenMinHistory.first.internalTemp;
      stalling = rise < 0.5 && currentTemp < target;
    }

    if (currentTemp >= target) {
      return PredictionResult(
        complete: true,
        minutesRemaining: 0,
        ratePerMinute: ratePerMinute,
        currentTemp: currentTemp,
        stalling: false,
      );
    }

    if (ratePerMinute <= 0) {
      return PredictionResult(
        complete: false,
        minutesRemaining: null,
        ratePerMinute: ratePerMinute,
        currentTemp: currentTemp,
        stalling: true,
      );
    }

    final tempRemaining = target - currentTemp;
    final minutesRemaining = (tempRemaining / ratePerMinute).round();

    return PredictionResult(
      complete: false,
      minutesRemaining: minutesRemaining,
      ratePerMinute: ratePerMinute,
      currentTemp: currentTemp,
      stalling: stalling,
    );
  }
}
