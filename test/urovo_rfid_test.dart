import 'package:flutter_test/flutter_test.dart';
import 'package:urovo_rfid/urovo_rfid.dart';
import 'package:urovo_rfid/urovo_rfid_platform_interface.dart';
import 'package:urovo_rfid/urovo_rfid_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockUrovoRfidPlatform
    with MockPlatformInterfaceMixin
    implements UrovoRfidPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');

  @override
  Stream<Map<String, dynamic>> get inventoryStream => const Stream.empty();

  @override
  Future<bool?> init() async => true;

  @override
  Future<void> startInventory(int session) async {}

  @override
  Future<void> stopInventory() async {}

  @override
  Future<Map<String, dynamic>?> readTag(
          String epc, int memBank, int wordAdd, int wordCnt, List<int> password) async =>
      {};

  @override
  Future<int?> writeTag(String epc, List<int> password, int memBank,
          int wordAdd, List<int> data) async =>
      0;

  @override
  Future<int?> writeTagEpc(String epc, String password, String data) async => 0;

  @override
  Future<int?> getOutputPower() async => 0;

  @override
  Future<int?> setOutputPower(int power) async => 0;

  @override
  Future<void> setInventoryParameter(Map<String, dynamic> params) async {}

  @override
  Future<void> enableScanHead(bool enable) async {}
}

void main() {
  final UrovoRfidPlatform initialPlatform = UrovoRfidPlatform.instance;

  test('$MethodChannelUrovoRfid is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelUrovoRfid>());
  });

  test('getPlatformVersion', () async {
    UrovoRfid urovoRfidPlugin = UrovoRfid();
    MockUrovoRfidPlatform fakePlatform = MockUrovoRfidPlatform();
    UrovoRfidPlatform.instance = fakePlatform;

    expect(await urovoRfidPlugin.getPlatformVersion(), '42');
  });
}
