import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'urovo_rfid_platform_interface.dart';

/// An implementation of [UrovoRfidPlatform] that uses method channels.
class MethodChannelUrovoRfid extends UrovoRfidPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('urovo_rfid');

  /// Event channel used for streaming inventory callbacks from the reader.
  @visibleForTesting
  final EventChannel eventChannel = const EventChannel('urovo_rfid/events');

  @override
  Stream<Map<String, dynamic>> get inventoryStream =>
      eventChannel.receiveBroadcastStream().map((event) =>
          Map<String, dynamic>.from(event as Map));

  @override
  Future<bool?> init() async {
    return await methodChannel.invokeMethod<bool>('init');
  }

  @override
  Future<void> startInventory(int session) async {
    await methodChannel.invokeMethod('startInventory', {'session': session});
  }

  @override
  Future<void> stopInventory() async {
    await methodChannel.invokeMethod('stopInventory');
  }

  @override
  Future<Map<String, dynamic>?> readTag(
    String epc,
    int memBank,
    int wordAdd,
    int wordCnt,
    List<int> password,
  ) async {
    final result = await methodChannel.invokeMapMethod<String, dynamic>(
      'readTag',
      {
        'epc': epc,
        'memBank': memBank,
        'wordAdd': wordAdd,
        'wordCnt': wordCnt,
        'password': password,
      },
    );
    return result;
  }

  @override
  Future<int?> writeTag(
    String epc,
    List<int> password,
    int memBank,
    int wordAdd,
    List<int> data,
  ) async {
    return await methodChannel.invokeMethod<int>('writeTag', {
      'epc': epc,
      'password': password,
      'memBank': memBank,
      'wordAdd': wordAdd,
      'data': data,
    });
  }

  @override
  Future<int?> writeTagEpc(String epc, String password, String data) async {
    return await methodChannel.invokeMethod<int>('writeTagEpc', {
      'epc': epc,
      'password': password,
      'data': data,
    });
  }

  @override
  Future<int?> getOutputPower() async {
    return await methodChannel.invokeMethod<int>('getOutputPower');
  }

  @override
  Future<int?> setOutputPower(int power) async {
    return await methodChannel.invokeMethod<int>('setOutputPower', {
      'power': power,
    });
  }

  @override
  Future<void> setInventoryParameter(Map<String, dynamic> params) async {
    await methodChannel.invokeMethod('setInventoryParameter', params);
  }

  @override
  Future<void> enableScanHead(bool enable) async {
    await methodChannel.invokeMethod('enableScanHead', {
      'enable': enable,
    });
  }

  @override
  Future<String?> getPlatformVersion() async {
    final version =
        await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
