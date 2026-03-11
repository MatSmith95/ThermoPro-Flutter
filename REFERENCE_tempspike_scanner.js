const EventEmitter = require('events');
const noble = require('@abandonware/noble');
const Store = require('electron-store');

class TempSpikeScanner extends EventEmitter {
  constructor() {
    super();
    this.scanning = false;
    this.maxHistorySize = 10000; // Increased to store more data
    this.probes = new Map(); // Map of probe address -> probe data

    // Initialize persistent storage
    this.store = new Store({
      name: 'temperature-data',
      defaults: {
        probes: {}
      }
    });

    // Load probe data from database on startup
    const savedProbes = this.store.get('probes', {});
    Object.entries(savedProbes).forEach(([address, probeData]) => {
      this.probes.set(address, probeData);
    });
    console.log(`Loaded ${this.probes.size} probes from database`);
  }

  async start() {
    return new Promise((resolve, reject) => {
      if (this.scanning) {
        resolve();
        return;
      }

      const onStateChange = (state) => {
        if (state === 'poweredOn') {
          this.scanning = true;
          noble.startScanning([], true); // Allow duplicates to get continuous updates
          this.emit('status', 'Scanning for TempSpike devices...');
          resolve();
        } else {
          const errorMsg = `Bluetooth adapter is ${state}. ${state === 'unauthorized' ? 'Please grant Bluetooth permission in System Settings.' : ''}`;
          this.emit('status', errorMsg);
          reject(new Error(errorMsg));
        }
      };

      if (noble.state === 'poweredOn') {
        onStateChange('poweredOn');
      } else {
        noble.once('stateChange', onStateChange);
      }

      noble.on('discover', this.handleDiscover.bind(this));
    });
  }

  stop() {
    if (this.scanning) {
      noble.stopScanning();
      this.scanning = false;
      this.emit('status', 'Scanning stopped');
    }
  }

  handleDiscover(peripheral) {
    const name = peripheral.advertisement.localName;

    // Check if this is a ThermoProbe/TempSpike device
    // Accepts: TP-series (TP96*, TP97*) or I-series (I60*, I61*, I62*, I97*, etc.)
    const isTempSpikeDevice = name && (name.startsWith('TP') || name.startsWith('I'));

    if (!isTempSpikeDevice) {
      return;
    }

    const manufacturerData = peripheral.advertisement.manufacturerData;

    if (!manufacturerData || manufacturerData.length < 7) {
      return;
    }

    try {
      const data = this.parseManufacturerData(manufacturerData, name);
      // On macOS, peripheral.address is often empty, so use id or uuid as fallback
      const address = peripheral.address || peripheral.id || peripheral.uuid;

      data.deviceName = name;
      data.address = address;
      data.rssi = peripheral.rssi;
      data.timestamp = Date.now();

      // Initialize probe if not seen before
      if (!this.probes.has(address)) {
        const newProbe = {
          address: address,
          name: name,
          history: [],
          lastSeen: Date.now(),
          active: true
        };
        this.probes.set(address, newProbe);
        this.emit('probe-discovered', newProbe);
        this.emit('status', `New probe discovered: ${name} (${address})`);
      }

      // Update probe data
      const probe = this.probes.get(address);
      probe.lastSeen = Date.now();
      probe.name = name; // Update name in case it changed

      // Add to probe's history
      this.addToProbeHistory(address, data);

      // Emit temperature update with probe info
      this.emit('temperature', {
        ...data,
        probeAddress: address,
        probeName: name
      });

      // Save to database
      this.saveToDatabase();
    } catch (error) {
      this.emit('error', error);
    }
  }

  parseManufacturerData(buffer, deviceName) {
    // Format: 1 byte probe index + 3 x 2-byte unsigned shorts (little-endian)
    // Bytes 0: probe index
    // Bytes 1-2: internal temp
    // Bytes 3-4: battery (booster/repeater battery)
    // Bytes 5-6: ambient temp
    // Bytes 7-8: probe battery (optional, if packet is 9+ bytes)

    const probeIndex = buffer.readUInt8(0);
    const internalTempRaw = buffer.readUInt16LE(1);
    const boosterBatteryRaw = buffer.readUInt16LE(3);
    const ambientTempRaw = buffer.readUInt16LE(5);

    // Temperature calculation differs by device series
    let internalTemp, ambientTemp;

    if (deviceName && deviceName.startsWith('I')) {
      // I-series devices (I60, I61, I62, I97, etc.)
      // Formula: raw - 30 (no division)
      internalTemp = internalTempRaw - 30;
      ambientTemp = ambientTempRaw - 30;
    } else {
      // TP-series devices (TP96*, TP97*)
      // Formula: (raw - 30) / 10
      internalTemp = (internalTempRaw - 30) / 10;
      ambientTemp = (ambientTempRaw - 30) / 10;
    }

    // Battery calculations
    const boosterBattery = this.calculateBattery(boosterBatteryRaw);

    const result = {
      probeIndex,
      internalTemp,
      ambientTemp,
      boosterBattery, // Renamed from 'battery' to be more specific
      battery: boosterBattery // Keep for backward compatibility
    };

    // Check if packet contains probe battery (bytes 7-8)
    if (buffer.length >= 9) {
      const probeBatteryRaw = buffer.readUInt16LE(7);
      result.probeBattery = this.calculateBattery(probeBatteryRaw);
    }

    return result;
  }

  calculateBattery(rawValue) {
    // Simplified battery calculation
    // Real implementation uses: tanh((millivolts - 2200) / 100) mapping to 0-100%
    // For now, use a simple linear approximation
    const voltage = rawValue / 100; // Rough conversion
    const minVoltage = 2.0;
    const maxVoltage = 3.0;

    const percentage = ((voltage - minVoltage) / (maxVoltage - minVoltage)) * 100;
    return Math.max(0, Math.min(100, percentage));
  }

  addToProbeHistory(address, data) {
    const probe = this.probes.get(address);
    if (!probe) return;

    probe.history.push({
      timestamp: data.timestamp,
      internalTemp: data.internalTemp,
      ambientTemp: data.ambientTemp,
      battery: data.battery
    });

    // Limit history size per probe
    if (probe.history.length > this.maxHistorySize) {
      probe.history.shift();
    }
  }

  saveToDatabase() {
    // Convert Map to plain object for storage
    const probesObj = {};
    this.probes.forEach((probe, address) => {
      probesObj[address] = probe;
    });
    this.store.set('probes', probesObj);
  }

  getProbes() {
    return Array.from(this.probes.values());
  }

  getProbe(address) {
    return this.probes.get(address);
  }

  getProbeHistory(address) {
    const probe = this.probes.get(address);
    return probe ? probe.history : [];
  }

  getAllHistory() {
    // Return combined history from all probes for backward compatibility
    const allHistory = [];
    this.probes.forEach((probe) => {
      probe.history.forEach(record => {
        allHistory.push({
          ...record,
          probeAddress: probe.address,
          probeName: probe.name
        });
      });
    });
    return allHistory.sort((a, b) => a.timestamp - b.timestamp);
  }

  clearHistory() {
    this.probes.forEach(probe => {
      probe.history = [];
    });
    this.saveToDatabase();
  }

  clearProbeHistory(address) {
    const probe = this.probes.get(address);
    if (probe) {
      probe.history = [];
      this.saveToDatabase();
    }
  }

  removeProbe(address) {
    this.probes.delete(address);
    this.saveToDatabase();
  }

  // Calculate cooking time prediction based on temperature trend
  predictCookingTime(probeAddress, targetTemp) {
    const probe = this.probes.get(probeAddress);
    if (!probe || !probe.history || probe.history.length < 10) {
      return null; // Not enough data
    }

    // Get recent history (last 5 minutes)
    const fiveMinutesAgo = Date.now() - (5 * 60 * 1000);
    const recentHistory = probe.history.filter(d => d.timestamp >= fiveMinutesAgo);

    if (recentHistory.length < 5) {
      return null;
    }

    // Calculate temperature change rate (degrees per minute)
    const firstPoint = recentHistory[0];
    const lastPoint = recentHistory[recentHistory.length - 1];

    const tempChange = lastPoint.internalTemp - firstPoint.internalTemp;
    const timeChange = (lastPoint.timestamp - firstPoint.timestamp) / (60 * 1000); // minutes

    const ratePerMinute = tempChange / timeChange;

    if (ratePerMinute <= 0) {
      return null; // Temperature not increasing
    }

    const currentTemp = lastPoint.internalTemp;
    const tempRemaining = targetTemp - currentTemp;

    if (tempRemaining <= 0) {
      return { complete: true, minutesRemaining: 0 };
    }

    const minutesRemaining = tempRemaining / ratePerMinute;

    return {
      complete: false,
      minutesRemaining: Math.round(minutesRemaining),
      ratePerMinute: ratePerMinute.toFixed(2),
      currentTemp: currentTemp.toFixed(1)
    };
  }
}

module.exports = TempSpikeScanner;
