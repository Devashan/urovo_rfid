import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:urovo_rfid/urovo_rfid.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _platformVersion = 'Unknown';
  final _urovoRfidPlugin = UrovoRfid();
  StreamSubscription<Map<String, dynamic>>? _inventorySubscription;
  final List<String> _logs = [];

  @override
  void initState() {
    super.initState();
    initPlatformState();
    _inventorySubscription = _urovoRfidPlugin.inventoryStream.listen((event) {
      _log('Inventory event: $event');
    });
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    String platformVersion;
    // Platform messages may fail, so we use a try/catch PlatformException.
    // We also handle the message potentially returning null.
    try {
      platformVersion =
          await _urovoRfidPlugin.getPlatformVersion() ?? 'Unknown platform version';
    } on PlatformException {
      platformVersion = 'Failed to get platform version.';
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _platformVersion = platformVersion;
    });
  }

  void _log(String message) {
    setState(() {
      _logs.add(message);
    });
  }

  Future<void> _init() async {
    try {
      await _urovoRfidPlugin.init();
      _log('init');
    } catch (e) {
      _log('init error: $e');
    }
  }

  Future<void> _startInventory() async {
    try {
      await _urovoRfidPlugin.startInventory(0);
      _log('startInventory');
    } catch (e) {
      _log('startInventory error: $e');
    }
  }

  Future<void> _stopInventory() async {
    try {
      await _urovoRfidPlugin.stopInventory();
      _log('stopInventory');
    } catch (e) {
      _log('stopInventory error: $e');
    }
  }

  Future<void> _readTag() async {
    try {
      await _urovoRfidPlugin
          .readTag('E2000017221101441890F7E0', 0, 0, 0, [0, 0, 0, 0]);
      _log('readTag');
    } catch (e) {
      _log('readTag error: $e');
    }
  }

  Future<void> _writeTag() async {
    try {
      await _urovoRfidPlugin
          .writeTag('E2000017221101441890F7E0', [0, 0, 0, 0], 0, 0, [0, 0]);
      _log('writeTag');
    } catch (e) {
      _log('writeTag error: $e');
    }
  }

  Future<void> _writeTagEpc() async {
    try {
      await _urovoRfidPlugin
          .writeTagEpc('E2000017221101441890F7E0', '00000000', '00000000');
      _log('writeTagEpc');
    } catch (e) {
      _log('writeTagEpc error: $e');
    }
  }

  Future<void> _getOutputPower() async {
    try {
      final power = await _urovoRfidPlugin.getOutputPower();
      _log('getOutputPower: $power');
    } catch (e) {
      _log('getOutputPower error: $e');
    }
  }

  Future<void> _setOutputPower() async {
    try {
      await _urovoRfidPlugin.setOutputPower(30);
      _log('setOutputPower');
    } catch (e) {
      _log('setOutputPower error: $e');
    }
  }

  Future<void> _setInventoryParameter() async {
    try {
      await _urovoRfidPlugin.setInventoryParameter({'dummy': true});
      _log('setInventoryParameter');
    } catch (e) {
      _log('setInventoryParameter error: $e');
    }
  }

  Future<void> _enableScanHead() async {
    try {
      await _urovoRfidPlugin.enableScanHead(true);
      _log('enableScanHead');
    } catch (e) {
      _log('enableScanHead error: $e');
    }
  }

  @override
  void dispose() {
    _inventorySubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Running on: $_platformVersion'),
            const SizedBox(height: 8),
            ElevatedButton(
                onPressed: _init, child: const Text('Init')), 
            ElevatedButton(
                onPressed: _startInventory, child: const Text('Start Inventory')),
            ElevatedButton(
                onPressed: _stopInventory, child: const Text('Stop Inventory')),
            ElevatedButton(
                onPressed: _readTag, child: const Text('Read Tag')),
            ElevatedButton(
                onPressed: _writeTag, child: const Text('Write Tag')),
            ElevatedButton(
                onPressed: _writeTagEpc, child: const Text('Write Tag EPC')),
            ElevatedButton(
                onPressed: _getOutputPower, child: const Text('Get Output Power')),
            ElevatedButton(
                onPressed: _setOutputPower, child: const Text('Set Output Power')),
            ElevatedButton(
                onPressed: _setInventoryParameter, child: const Text('Set Inventory Parameter')),
            ElevatedButton(
                onPressed: _enableScanHead, child: const Text('Enable Scan Head')),
            const SizedBox(height: 20),
            const Text('Logs:'),
            ..._logs.map((e) => Text(e)),
          ],
        ),
      ),
    );
  }
}
