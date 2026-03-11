# ThermoPro Flutter

A cross-platform mobile and desktop application for monitoring ThermoPro TempSpike Bluetooth temperature probes. Built with Flutter for iOS, Android, and macOS from a single codebase.

## Features

- **Real-time Temperature Monitoring**: Track internal and ambient temperatures from multiple TempSpike probes simultaneously
- **Live Charts**: View temperature trends with up to 4 customizable chart panels, multiple time ranges (5min, 15min, 1hr, all)
- **Smart Alerts**: Receive notifications for:
  - Target temperature reached
  - Temperature stalling
  - Battery low
  - Probe connection lost
  - Unexpected temperature drops
- **Time-to-Target Predictions**: Linear regression-based cooking time estimates
- **Session Management**: Save and review historical cook sessions with CSV export
- **Probe Customization**: Set custom nicknames, targets, and colors for each probe

## Supported Devices

- **TP-series**: TP96*, TP97*
- **I-series**: I60*, I61*, I62*, I97*

## Requirements

### iOS
- iOS 12.0 or later
- Bluetooth access permission

### Android
- Android 5.0 (API 21) or later
- Bluetooth, location, and notification permissions

### macOS
- macOS 10.14 or later
- Bluetooth entitlements

## Permissions

### Android
The app requires the following permissions:
- `BLUETOOTH_SCAN` - Scan for TempSpike devices
- `BLUETOOTH_CONNECT` - Connect to probes
- `ACCESS_FINE_LOCATION` - Required for BLE scanning on Android
- `FOREGROUND_SERVICE` - Background temperature monitoring
- `POST_NOTIFICATIONS` - Alert notifications

### iOS
- `NSBluetoothAlwaysUsageDescription` - Bluetooth access for probe connectivity

### macOS
- `com.apple.security.device.bluetooth` - Bluetooth device access

## Setup

1. Clone the repository:
   ```bash
   git clone https://github.com/MatSmith95/ThermoPro-Flutter.git
   cd ThermoPro-Flutter
   ```

2. Install Flutter dependencies:
   ```bash
   flutter pub get
   ```

3. Generate Hive type adapters:
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```

4. Run the app:
   ```bash
   # iOS
   flutter run -d ios

   # Android
   flutter run -d android

   # macOS
   flutter run -d macos
   ```

## Architecture

### Tech Stack
- **Flutter** - UI framework
- **Provider** - State management
- **Hive** - Local database for probe data and sessions
- **flutter_blue_plus** - Bluetooth Low Energy communication
- **fl_chart** - Real-time temperature charts
- **flutter_local_notifications** - Alert system
- **go_router** - Navigation
- **share_plus** - CSV export functionality

### Project Structure
```
lib/
├── models/           # Hive-annotated data models
├── services/         # BLE, alerts, predictions, parsing
├── controllers/      # State management (probe, session)
├── screens/          # UI screens (dashboard, charts, etc.)
└── widgets/          # Reusable UI components
```

## BLE Protocol

The app parses TempSpike manufacturer data packets:
- **Byte 0**: Probe index
- **Bytes 1-2**: Internal temperature (uint16 little-endian)
- **Bytes 3-4**: Booster battery (uint16 little-endian)
- **Bytes 5-6**: Ambient temperature (uint16 little-endian)
- **Bytes 7-8**: Probe battery (optional, uint16 little-endian)

Temperature conversion:
- **TP-series**: `(raw - 30) / 10`
- **I-series**: `raw - 30`

## Platform Notes

### iOS
- Requires Bluetooth "Always" permission for background scanning
- Background execution may be limited by iOS power management

### Android
- Location permission required for BLE scanning (Android requirement)
- Foreground service notification appears when actively monitoring

### macOS
- App sandbox enabled with Bluetooth entitlement
- Full desktop experience with resizable windows

## Development

### Building for Release

```bash
# iOS (requires Apple Developer account)
flutter build ios --release

# Android
flutter build apk --release
flutter build appbundle --release

# macOS
flutter build macos --release
```

### Running Tests

```bash
flutter test
```

### Code Analysis

```bash
flutter analyze
```

## Contributing

This is a rewrite of an Electron desktop app, porting Node.js noble BLE logic to Dart with flutter_blue_plus.

## License

MIT License

## Credits

- Ported from the original Electron ThermoPro app
- BLE protocol reverse-engineered from TempSpike devices
- Built with Flutter and the amazing Flutter community packages
