import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:csv/csv.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../models/cook_session.dart';
import '../models/temp_probe.dart';
import '../models/temp_reading.dart';

class SessionController extends ChangeNotifier {
  late Box<CookSession> _sessionBox;
  final Map<String, CookSession> _sessions = {};
  CookSession? _activeSession;

  List<CookSession> get sessions => _sessions.values.toList()
    ..sort((a, b) => b.startTime.compareTo(a.startTime));
  CookSession? get activeSession => _activeSession;

  Future<void> init() async {
    // Register adapters if not already registered
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(ProbeHistoryAdapter());
    }
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(ProbeSettingsAdapter());
    }
    if (!Hive.isAdapterRegistered(4)) {
      Hive.registerAdapter(CookSessionAdapter());
    }

    _sessionBox = await Hive.openBox<CookSession>('sessions');

    // Load saved sessions
    for (var session in _sessionBox.values) {
      _sessions[session.id] = session;
      if (session.isActive) {
        _activeSession = session;
      }
    }

    notifyListeners();
  }

  void startSession(String name, List<TempProbe> probes) {
    // End current active session if exists
    if (_activeSession != null) {
      endSession(_activeSession!.id);
    }

    final sessionId = DateTime.now().millisecondsSinceEpoch.toString();
    final probeHistories = probes.map((probe) {
      return ProbeHistory(
        probeId: probe.id,
        probeName: probe.displayName,
        readings: List.from(probe.history),
      );
    }).toList();

    final probeSettings = probes.map((probe) {
      return ProbeSettings(
        probeId: probe.id,
        targetInternal: probe.targetInternal,
        targetAmbient: probe.targetAmbient,
        colorValue: probe.colorValue,
      );
    }).toList();

    final session = CookSession(
      id: sessionId,
      name: name,
      startTime: DateTime.now(),
      probeHistories: probeHistories,
      probeSettings: probeSettings,
    );

    _sessions[sessionId] = session;
    _activeSession = session;
    _sessionBox.put(sessionId, session);

    notifyListeners();
  }

  void endSession(String sessionId) {
    final session = _sessions[sessionId];
    if (session != null) {
      session.endTime = DateTime.now();
      session.save();

      if (_activeSession?.id == sessionId) {
        _activeSession = null;
      }

      notifyListeners();
    }
  }

  void deleteSession(String sessionId) {
    _sessions.remove(sessionId);
    _sessionBox.delete(sessionId);

    if (_activeSession?.id == sessionId) {
      _activeSession = null;
    }

    notifyListeners();
  }

  Future<void> exportSessionToCsv(CookSession session) async {
    final rows = <List<dynamic>>[
      ['Session', session.name],
      ['Start Time', session.startTime.toIso8601String()],
      ['End Time', session.endTime?.toIso8601String() ?? 'In Progress'],
      ['Duration', session.duration.toString()],
      [],
      ['Timestamp', 'Probe', 'Internal Temp (°C)', 'Ambient Temp (°C)', 'Battery (%)'],
    ];

    for (var probeHistory in session.probeHistories) {
      for (var reading in probeHistory.readings) {
        rows.add([
          reading.timestamp.toIso8601String(),
          probeHistory.probeName,
          reading.internalTemp.toStringAsFixed(2),
          reading.ambientTemp.toStringAsFixed(2),
          reading.battery.toStringAsFixed(1),
        ]);
      }
    }

    final csv = const ListToCsvConverter().convert(rows);
    final directory = await getTemporaryDirectory();
    final filePath = '${directory.path}/${session.name}_${session.id}.csv';
    final file = File(filePath);
    await file.writeAsString(csv);

    await Share.shareXFiles(
      [XFile(filePath)],
      subject: 'ThermoPro Session: ${session.name}',
    );
  }

  void dispose() {
    _sessionBox.close();
    super.dispose();
  }
}
