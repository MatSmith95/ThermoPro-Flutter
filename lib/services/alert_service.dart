import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/temp_probe.dart';

enum AlertType {
  targetReached,
  stalling,
  batteryLow,
  probeLost,
  temperatureDropping,
}

class ProbeAlertState {
  bool targetReachedFired = false;
  bool stallingFired = false;
  bool batteryLowFired = false;
  bool probeLostFired = false;
  bool droppingFired = false;
  double? lastTemp;
  DateTime lastSeenAt = DateTime.now();

  void reset() {
    targetReachedFired = false;
    stallingFired = false;
    batteryLowFired = false;
    probeLostFired = false;
    droppingFired = false;
    lastTemp = null;
    lastSeenAt = DateTime.now();
  }
}

class AlertService {
  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  final Map<String, ProbeAlertState> _alertStates = {};
  Timer? _probeCheckTimer;

  bool _initialized = false;
  bool _notificationsEnabled = true;

  Future<void> init() async {
    if (_initialized) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(initSettings);
    _initialized = true;

    // Check for lost probes every 30 seconds
    _probeCheckTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      // This will be called externally with probe list
    });
  }

  void setNotificationsEnabled(bool enabled) {
    _notificationsEnabled = enabled;
  }

  void check(TempProbe probe) {
    if (!_initialized || !_notificationsEnabled) return;

    final reading = probe.latestReading;
    if (reading == null) return;

    final state = _alertStates.putIfAbsent(probe.id, () => ProbeAlertState());
    state.lastSeenAt = DateTime.now();

    // 1. Target reached
    if (probe.targetInternal != null && reading.internalTemp >= probe.targetInternal!) {
      if (!state.targetReachedFired) {
        state.targetReachedFired = true;
        _sendNotification(
          AlertType.targetReached,
          'Target Reached!',
          '${probe.displayName} hit ${reading.internalTemp.toStringAsFixed(1)}°C (target: ${probe.targetInternal!.toStringAsFixed(1)}°C)',
        );
      }
    } else {
      state.targetReachedFired = false;
    }

    // 2. Battery low (< 15%)
    if (probe.batteryPercent < 15) {
      if (!state.batteryLowFired) {
        state.batteryLowFired = true;
        _sendNotification(
          AlertType.batteryLow,
          'Battery Low',
          '${probe.displayName} battery at ${probe.batteryPercent.toStringAsFixed(0)}%',
        );
      }
    } else if (probe.batteryPercent >= 30) {
      state.batteryLowFired = false;
    }

    // 3. Temperature stalling (< 0.5°C rise in 10 minutes)
    if (probe.history.length >= 10) {
      final tenMinutesAgo = DateTime.now().subtract(const Duration(minutes: 10));
      final recentHistory = probe.history.where((r) => r.timestamp.isAfter(tenMinutesAgo)).toList();

      if (recentHistory.length >= 5) {
        final oldest = recentHistory.first;
        final newest = recentHistory.last;
        final rise = newest.internalTemp - oldest.internalTemp;

        if (probe.targetInternal != null && reading.internalTemp < probe.targetInternal!) {
          if (rise < 0.5 && !state.stallingFired) {
            state.stallingFired = true;
            _sendNotification(
              AlertType.stalling,
              'Temperature Stalling',
              '${probe.displayName} only rose ${rise.toStringAsFixed(1)}°C in 10 mins. Currently ${reading.internalTemp.toStringAsFixed(1)}°C',
            );
          } else if (rise >= 1.0) {
            state.stallingFired = false;
          }
        }
      }
    }

    // 4. Temperature dropping (> 2°C drop in 5 minutes)
    if (probe.history.length >= 5) {
      final fiveMinutesAgo = DateTime.now().subtract(const Duration(minutes: 5));
      final recentHistory = probe.history.where((r) => r.timestamp.isAfter(fiveMinutesAgo)).toList();

      if (recentHistory.length >= 3) {
        final oldest = recentHistory.first;
        final newest = recentHistory.last;
        final drop = oldest.internalTemp - newest.internalTemp;

        if (drop >= 2 && !state.droppingFired) {
          state.droppingFired = true;
          _sendNotification(
            AlertType.temperatureDropping,
            'Temperature Dropping',
            '${probe.displayName} dropped ${drop.toStringAsFixed(1)}°C in 5 mins. Now at ${reading.internalTemp.toStringAsFixed(1)}°C',
          );
        } else if (drop < 1) {
          state.droppingFired = false;
        }
      }
    }

    state.lastTemp = reading.internalTemp;
  }

  void checkProbesLost(List<TempProbe> probes) {
    if (!_initialized || !_notificationsEnabled) return;

    const fiveMinutes = Duration(minutes: 5);
    final now = DateTime.now();

    for (var probe in probes) {
      final state = _alertStates[probe.id];
      if (state == null) continue;

      final timeSinceLastSeen = now.difference(state.lastSeenAt);

      if (timeSinceLastSeen > fiveMinutes && !state.probeLostFired) {
        state.probeLostFired = true;
        _sendNotification(
          AlertType.probeLost,
          'Probe Lost',
          '${probe.displayName}: No data for ${timeSinceLastSeen.inMinutes} minutes',
        );
      } else if (timeSinceLastSeen < const Duration(minutes: 1)) {
        state.probeLostFired = false;
      }
    }
  }

  void setProbeTarget(String probeId, double? targetTemp) {
    final state = _alertStates[probeId];
    if (state != null) {
      state.targetReachedFired = false;
      state.stallingFired = false;
    }
  }

  void resetProbe(String probeId) {
    _alertStates[probeId]?.reset();
  }

  Future<void> _sendNotification(AlertType type, String title, String body) async {
    if (!_initialized) return;

    const androidDetails = AndroidNotificationDetails(
      'tempspike_alerts',
      'Temperature Alerts',
      channelDescription: 'Notifications for temperature probe alerts',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      type.index,
      title,
      body,
      details,
    );
  }

  void dispose() {
    _probeCheckTimer?.cancel();
  }
}
