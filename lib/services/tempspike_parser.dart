import 'dart:typed_data';
import 'dart:math';

class TempSpikeData {
  final int probeIndex;
  final double internalTemp;
  final double ambientTemp;
  final double boosterBattery;
  final double? probeBattery;

  TempSpikeData({
    required this.probeIndex,
    required this.internalTemp,
    required this.ambientTemp,
    required this.boosterBattery,
    this.probeBattery,
  });

  double get battery => probeBattery ?? boosterBattery;
}

class TempSpikeParser {
  static TempSpikeData? parseManufacturerData(
    Uint8List buffer,
    String deviceName,
  ) {
    if (buffer.length < 7) {
      return null;
    }

    try {
      // Format: 1 byte probe index + 3 x 2-byte unsigned shorts (little-endian)
      // Bytes 0: probe index
      // Bytes 1-2: internal temp
      // Bytes 3-4: battery (booster/repeater battery)
      // Bytes 5-6: ambient temp
      // Bytes 7-8: probe battery (optional, if packet is 9+ bytes)

      final probeIndex = buffer[0];
      final internalTempRaw = _readUInt16LE(buffer, 1);
      final boosterBatteryRaw = _readUInt16LE(buffer, 3);
      final ambientTempRaw = _readUInt16LE(buffer, 5);

      // Temperature calculation differs by device series
      double internalTemp;
      double ambientTemp;

      if (deviceName.startsWith('I')) {
        // I-series devices (I60, I61, I62, I97, etc.)
        // Formula: raw - 30 (no division)
        internalTemp = (internalTempRaw - 30).toDouble();
        ambientTemp = (ambientTempRaw - 30).toDouble();
      } else {
        // TP-series devices (TP96*, TP97*)
        // Formula: (raw - 30) / 10
        internalTemp = (internalTempRaw - 30) / 10.0;
        ambientTemp = (ambientTempRaw - 30) / 10.0;
      }

      // Battery calculations
      final boosterBattery = _calculateBattery(boosterBatteryRaw);

      double? probeBattery;
      if (buffer.length >= 9) {
        final probeBatteryRaw = _readUInt16LE(buffer, 7);
        probeBattery = _calculateBattery(probeBatteryRaw);
      }

      return TempSpikeData(
        probeIndex: probeIndex,
        internalTemp: internalTemp,
        ambientTemp: ambientTemp,
        boosterBattery: boosterBattery,
        probeBattery: probeBattery,
      );
    } catch (e) {
      return null;
    }
  }

  static int _readUInt16LE(Uint8List buffer, int offset) {
    return buffer[offset] | (buffer[offset + 1] << 8);
  }

  static double _calculateBattery(int rawValue) {
    // Simplified battery calculation
    // Real implementation uses: tanh((millivolts - 2200) / 100) mapping to 0-100%
    // For now, use a simple linear approximation
    final voltage = rawValue / 100.0;
    const minVoltage = 2.0;
    const maxVoltage = 3.0;

    final percentage = ((voltage - minVoltage) / (maxVoltage - minVoltage)) * 100;
    return max(0, min(100, percentage));
  }

  static bool isTempSpikeDevice(String? name) {
    if (name == null) return false;
    // Accepts: TP-series (TP96*, TP97*) or I-series (I60*, I61*, I62*, I97*, etc.)
    return name.startsWith('TP') || name.startsWith('I');
  }

  static String getModelType(String name) {
    if (name.startsWith('I')) return 'I';
    if (name.startsWith('TP')) return 'TP';
    return 'Unknown';
  }
}
