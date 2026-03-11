import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/temp_probe.dart';
import '../models/temp_reading.dart';
import '../services/ble_service.dart';
import '../services/tempspike_parser.dart';
import '../services/alert_service.dart';
import '../services/prediction_service.dart';

class ProbeController extends ChangeNotifier {
  final BleService _bleService = BleService();
  final AlertService _alertService = AlertService();
  final PredictionService _predictionService = PredictionService();
  final Map<String, TempProbe> _probes = {};
  String _statusMessage = 'Not scanning';
  Timer? _alertCheckTimer;

  late Box<TempProbe> _probeBox;
  StreamSubscription? _scanSubscription;
  StreamSubscription? _statusSubscription;

  bool get isScanning => _bleService.isScanning;
  String get statusMessage => _statusMessage;
  List<TempProbe> get probes => _probes.values.toList();

  Future<void> init() async {
    await Hive.initFlutter();

    // Register adapters
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(TempReadingAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(TempProbeAdapter());
    }

    _probeBox = await Hive.openBox<TempProbe>('probes');

    // Load saved probes
    for (var probe in _probeBox.values) {
      _probes[probe.id] = probe;
    }

    // Initialize alert service
    await _alertService.init();

    // Listen to BLE scan results
    _scanSubscription = _bleService.scanResults.listen(_handleScanResults);
    _statusSubscription = _bleService.status.listen((status) {
      _statusMessage = status;
      notifyListeners();
    });

    // Check alerts every 30 seconds
    _alertCheckTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _alertService.checkProbesLost(_probes.values.toList());
    });

    notifyListeners();
  }

  void _handleScanResults(Map<String, TempSpikeData> results) {
    for (var entry in results.entries) {
      final deviceId = entry.key;
      final data = entry.value;

      // Get or create probe
      TempProbe probe;
      if (_probes.containsKey(deviceId)) {
        probe = _probes[deviceId]!;
      } else {
        // Extract device name from BLE - for now use deviceId
        // In a real scenario, we'd get this from the BLE advertisement
        final modelType = 'TP'; // Default, should be determined from device name
        probe = TempProbe(
          id: deviceId,
          name: deviceId.substring(0, 8), // Short ID
          modelType: modelType,
        );
        _probes[deviceId] = probe;
        _probeBox.put(deviceId, probe);
      }

      // Add new reading
      final reading = TempReading(
        timestamp: DateTime.now(),
        internalTemp: data.internalTemp,
        ambientTemp: data.ambientTemp,
        battery: data.battery,
      );

      probe.addReading(reading);
      probe.batteryPercent = data.battery;
      probe.save();

      // Check alerts for this probe
      _alertService.check(probe);
    }

    notifyListeners();
  }

  Future<void> startScanning() async {
    await _bleService.startScanning();
    notifyListeners();
  }

  Future<void> stopScanning() async {
    await _bleService.stopScanning();
    notifyListeners();
  }

  void updateProbeNickname(String probeId, String nickname) {
    if (_probes.containsKey(probeId)) {
      _probes[probeId]!.nickname = nickname;
      _probes[probeId]!.save();
      notifyListeners();
    }
  }

  void updateProbeTarget(String probeId, double? internal, double? ambient) {
    if (_probes.containsKey(probeId)) {
      _probes[probeId]!.targetInternal = internal;
      _probes[probeId]!.targetAmbient = ambient;
      _probes[probeId]!.save();
      _alertService.setProbeTarget(probeId, internal);
      notifyListeners();
    }
  }

  void updateProbeColor(String probeId, int colorValue) {
    if (_probes.containsKey(probeId)) {
      _probes[probeId]!.colorValue = colorValue;
      _probes[probeId]!.save();
      notifyListeners();
    }
  }

  void clearProbeHistory(String probeId) {
    if (_probes.containsKey(probeId)) {
      _probes[probeId]!.history.clear();
      _probes[probeId]!.save();
      notifyListeners();
    }
  }

  void removeProbe(String probeId) {
    if (_probes.containsKey(probeId)) {
      _probeBox.delete(probeId);
      _probes.remove(probeId);
      notifyListeners();
    }
  }

  TempProbe? getProbe(String probeId) {
    return _probes[probeId];
  }

  PredictionService get predictionService => _predictionService;

  @override
  void dispose() {
    _scanSubscription?.cancel();
    _statusSubscription?.cancel();
    _alertCheckTimer?.cancel();
    _bleService.dispose();
    _alertService.dispose();
    _probeBox.close();
    super.dispose();
  }
}
