# urovo_rfid

`urovo_rfid` is a Flutter plugin for integrating **Urovo Android RFID handheld devices** through the Urovo USDK and RFID native libraries.

## Platform support

- ✅ **Android**: supported
- ❌ iOS / Web / macOS / Windows / Linux: not implemented

This package is intended for Urovo enterprise handhelds that include an RFID module and compatible firmware/SDK stack.

## Device and SDK prerequisites

Before using this plugin, ensure all of the following are true:

1. Your target device is a Urovo Android handheld with built-in or attached RFID hardware.
2. The app includes Urovo native dependencies expected by this plugin (`platform_sdk_v3.1.221124.jar`, `URFIDLibrary-v2.4.0125.aar`).
3. Your Flutter/Android project is configured for:
   - Flutter plugin support
   - Android `minSdkVersion` 21 or higher
   - Runtime permissions required by your target Urovo model and Android version
4. You test on real hardware (the RFID APIs are not usable on generic emulators).

## Installation

Add the package to `pubspec.yaml`:

```yaml
dependencies:
  urovo_rfid: ^0.0.1
```

Then install dependencies:

```bash
flutter pub get
```

## API quick reference

The main entry point is `UrovoRfid`:

- `Future<bool?> init()`
- `Future<void> startInventory(int session)`
- `Future<void> stopInventory()`
- `Stream<Map<String, dynamic>> get inventoryStream`
- `Future<Map<String, dynamic>?> readTag(...)`
- `Future<int?> writeTag(...)`
- `Future<int?> writeTagEpc(...)`
- `Future<int?> getOutputPower()`
- `Future<int?> setOutputPower(int power)`
- `Future<void> setInventoryParameter(Map<String, dynamic> params)`
- `Future<void> enableScanHead(bool enable)`

## Full usage examples

### 1) Initialize and subscribe to inventory events

```dart
import 'dart:async';
import 'package:urovo_rfid/urovo_rfid.dart';

final rfid = UrovoRfid();
StreamSubscription<Map<String, dynamic>>? _sub;

Future<void> setupRfid() async {
  final initialized = await rfid.init();
  if (initialized != true) {
    throw Exception('RFID init failed');
  }

  _sub = rfid.inventoryStream.listen((event) {
    // Native events are delivered as envelopes; inspect keys carefully.
    if (event.containsKey('event_inventory_tag')) {
      final payload = event['event_inventory_tag'];
      // payload may be a JSON string from native side (EPC/TID/RSSI).
      print('Tag event: $payload');
    } else if (event.containsKey('event_inventory_tag_end')) {
      print('Inventory cycle ended');
    } else if (event.containsKey('event_init')) {
      print('Native init event: ${event['event_init']}');
    }
  }, onError: (error, stackTrace) {
    print('Inventory stream error: $error');
  });
}

Future<void> disposeRfid() async {
  await _sub?.cancel();
}
```

### 2) Start/stop inventory scanning

```dart
Future<void> runInventorySession(UrovoRfid rfid) async {
  // Session is forwarded to the native Urovo RFID manager.
  await rfid.startInventory(0);

  // ... collect inventory events through inventoryStream ...

  await rfid.stopInventory();
}
```

### 3) Read tag memory

```dart
Future<void> readExample(UrovoRfid rfid, String epc) async {
  // 4-byte access password (example only).
  const password = <int>[0x00, 0x00, 0x00, 0x00];

  final result = await rfid.readTag(
    epc,
    1, // memory bank
    2, // word start
    6, // word count
    password,
  );

  print('readTag result: $result');
}
```

### 4) Write tag memory / EPC

```dart
Future<void> writeExample(UrovoRfid rfid, String epc) async {
  const password = <int>[0x00, 0x00, 0x00, 0x00];

  final writeCode = await rfid.writeTag(
    epc,
    password,
    3, // memory bank
    2, // word start
    <int>[0x11, 0x22, 0x33, 0x44],
  );

  if (writeCode == 0) {
    print('writeTag succeeded');
  } else {
    print('writeTag failed with code: $writeCode');
  }

  final epcCode = await rfid.writeTagEpc(epc, '00000000', '300833B2DDD9014000000001');
  print('writeTagEpc code: $epcCode');
}
```

### 5) Configure inventory parameters

`setInventoryParameter` expects a Dart `Map<String, dynamic>` where keys map directly to Urovo `RfidParameter` fields.

Currently supported keys:

- `Session` (`int`)
- `Interval` (`int`)
- `QValue` (`int`)

```dart
Future<void> configureInventory(UrovoRfid rfid) async {
  await rfid.setInventoryParameter({
    'Session': 0,
    'Interval': 0,
    'QValue': 6,
  });
}
```

## Error handling semantics

This plugin exposes two error surfaces:

1. **MethodChannel invocation failures**
   - Native side can return a Flutter `PlatformException` (for example, if RFID manager is not initialized).
   - Handle with `try/catch` around async API calls.

2. **Native return codes and event payloads**
   - Many calls return integer result codes from Urovo SDK APIs (`0` is commonly success).
   - Some failure cases return a unified plugin code (`-19`) when arguments are missing/invalid on native side.
   - Inventory and init status are emitted as event stream entries (`event_inventory_tag`, `event_inventory_tag_end`, `event_init`).

Recommended pattern:

```dart
try {
  final code = await rfid.setOutputPower(26);
  if (code != 0) {
    // Map SDK-specific code to app-level error UI/logging.
  }
} on PlatformException catch (e) {
  // Transport/initialization/channel error
  print('PlatformException: ${e.code} ${e.message}');
}
```

## Permission and hardware requirements

Because this plugin delegates to vendor SDK behavior, required permissions can vary by device model and Android release. In production deployments, verify all of the following in your app:

- Device has operational Urovo RFID hardware.
- Vendor services/firmware required by Urovo USDK are present.
- Android runtime permissions required for scanning workflows are granted (for example, permissions tied to hardware scan features and device management on your target model).
- Any enterprise policy (MDM/EMM) restrictions allow RFID service access.

> Tip: validate the full read/write/inventory lifecycle on each hardware SKU you support; Urovo SDK behavior can differ by firmware and reader module revision.

## Additional documentation

Detailed background notes are available in [`docs/rfid_development_documentation.md`](docs/rfid_development_documentation.md).
