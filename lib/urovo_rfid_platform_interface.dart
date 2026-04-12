import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'urovo_rfid_method_channel.dart';

abstract class UrovoRfidPlatform extends PlatformInterface {
  /// Constructs a UrovoRfidPlatform.
  UrovoRfidPlatform() : super(token: _token);

  static final Object _token = Object();

  static UrovoRfidPlatform _instance = MethodChannelUrovoRfid();

  /// The default instance of [UrovoRfidPlatform] to use.
  ///
  /// Defaults to [MethodChannelUrovoRfid].
  static UrovoRfidPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [UrovoRfidPlatform] when
  /// they register themselves.
  static set instance(UrovoRfidPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// Stream of tag inventory events.  Each event is a map containing
  /// `epc`, `tid` and `rssi` values returned from the reader.
  Stream<Map<String, dynamic>> get inventoryStream {
    throw UnimplementedError('inventoryStream has not been implemented.');
  }

  /// Initialize the RFID manager.  Returns `true` when the underlying SDK
  /// reports a successful connection.
  Future<bool?> init();

  /// Begin inventory scanning using the provided [session].
  Future<void> startInventory(int session);

  /// Stop any ongoing inventory scans.
  Future<void> stopInventory();

  /// Read tag data from the specified memory [memBank].  The password is
  /// supplied as a 4-byte array in [password].
  Future<Map<String, dynamic>?> readTag(
    String epc,
    int memBank,
    int wordAdd,
    int wordCnt,
    List<int> password,
  );

  /// Write tag data to the specified memory [memBank].  Returns the error
  /// code reported by the SDK.
  Future<int?> writeTag(
    String epc,
    List<int> password,
    int memBank,
    int wordAdd,
    List<int> data,
  );

  /// Convenience method for writing the EPC region.
  Future<int?> writeTagEpc(String epc, String password, String data);

  /// Query the current reader output power in dBm.
  Future<int?> getOutputPower();

  /// Set the reader output power in dBm.  Returns the error code from the
  /// SDK where `0` generally represents success.
  Future<int?> setOutputPower(int power);

  /// Adjust inventory parameters such as `session`, `interval`, and
  /// `qValue`.  The expected keys mirror those described in the SDK
  /// documentation.
  Future<void> setInventoryParameter(Map<String, dynamic> params);

  /// Enable or disable the long range handle scanning head light.
  Future<void> enableScanHead(bool enable);

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
