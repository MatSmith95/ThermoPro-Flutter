import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'tempspike_parser.dart';

class BleService {
  final _scanResultsController =
      StreamController<Map<String, TempSpikeData>>.broadcast();
  final _statusController = StreamController<String>.broadcast();

  Stream<Map<String, TempSpikeData>> get scanResults =>
      _scanResultsController.stream;
  Stream<String> get status => _statusController.stream;

  final Map<String, TempSpikeData> _latestData = {};
  bool _isScanning = false;
  StreamSubscription? _scanSubscription;

  bool get isScanning => _isScanning;

  Future<void> requestPermissions() async {
    if (await Permission.bluetoothScan.isDenied) {
      await Permission.bluetoothScan.request();
    }
    if (await Permission.bluetoothConnect.isDenied) {
      await Permission.bluetoothConnect.request();
    }
    if (await Permission.location.isDenied) {
      await Permission.location.request();
    }
  }

  Future<void> startScanning() async {
    if (_isScanning) {
      return;
    }

    try {
      await requestPermissions();

      // Check if Bluetooth is available
      if (await FlutterBluePlus.isSupported == false) {
        _statusController.add('Bluetooth not supported on this device');
        return;
      }

      // Check adapter state
      final adapterState = await FlutterBluePlus.adapterState.first;
      if (adapterState != BluetoothAdapterState.on) {
        _statusController.add(
            'Bluetooth is off. Please turn on Bluetooth in settings.');
        return;
      }

      _isScanning = true;
      _statusController.add('Scanning for TempSpike devices...');

      // Start scanning with allow duplicates to get continuous updates
      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 0), // Continuous scan
        androidUsesFineLocation: true,
      );

      _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
        for (ScanResult result in results) {
          _handleScanResult(result);
        }
      });
    } catch (e) {
      _statusController.add('Error starting scan: $e');
      _isScanning = false;
    }
  }

  void _handleScanResult(ScanResult result) {
    final device = result.device;
    final advertisementData = result.advertisementData;
    final name = advertisementData.advName;

    // Check if this is a TempSpike device
    if (!TempSpikeParser.isTempSpikeDevice(name)) {
      return;
    }

    // Get manufacturer data
    final manufacturerData = advertisementData.manufacturerData;
    if (manufacturerData.isEmpty) {
      return;
    }

    // Parse the first manufacturer data entry
    final entry = manufacturerData.entries.first;
    final data = TempSpikeParser.parseManufacturerData(entry.value, name);

    if (data != null) {
      final deviceId = device.remoteId.toString();
      _latestData[deviceId] = data;
      _scanResultsController.add(Map.from(_latestData));
    }
  }

  Future<void> stopScanning() async {
    if (!_isScanning) {
      return;
    }

    await _scanSubscription?.cancel();
    await FlutterBluePlus.stopScan();
    _isScanning = false;
    _statusController.add('Scanning stopped');
  }

  void dispose() {
    stopScanning();
    _scanResultsController.close();
    _statusController.close();
  }
}
