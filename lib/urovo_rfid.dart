
import 'urovo_rfid_platform_interface.dart';

/// Public API exposed to Flutter applications.
class UrovoRfid {
  UrovoRfidPlatform get _platform => UrovoRfidPlatform.instance;

  /// Current stream of inventory events emitted by the native plugin.
  Stream<Map<String, dynamic>> get inventoryStream => _platform.inventoryStream;

  /// Initialize the underlying RFID manager.
  Future<bool?> init() => _platform.init();

  /// Begin scanning for tags.
  Future<void> startInventory(int session) => _platform.startInventory(session);

  /// Stop the current inventory operation.
  Future<void> stopInventory() => _platform.stopInventory();

  /// Read tag data from the device.
  Future<Map<String, dynamic>?> readTag(
    String epc,
    int memBank,
    int wordAdd,
    int wordCnt,
    List<int> password,
  ) =>
      _platform.readTag(epc, memBank, wordAdd, wordCnt, password);

  /// Write tag memory contents.
  Future<int?> writeTag(
    String epc,
    List<int> password,
    int memBank,
    int wordAdd,
    List<int> data,
  ) =>
      _platform.writeTag(epc, password, memBank, wordAdd, data);

  /// Write the EPC region of a tag.
  Future<int?> writeTagEpc(String epc, String password, String data) =>
      _platform.writeTagEpc(epc, password, data);

  /// Query reader output power in dBm.
  Future<int?> getOutputPower() => _platform.getOutputPower();

  /// Set reader output power in dBm.
  Future<int?> setOutputPower(int power) => _platform.setOutputPower(power);

  /// Update inventory parameters.
  Future<void> setInventoryParameter(Map<String, dynamic> params) =>
      _platform.setInventoryParameter(params);

  /// Enable or disable the scanning head light.
  Future<void> enableScanHead(bool enable) => _platform.enableScanHead(enable);

  Future<String?> getPlatformVersion() => _platform.getPlatformVersion();
}
