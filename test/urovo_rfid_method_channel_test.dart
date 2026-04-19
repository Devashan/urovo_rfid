import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:urovo_rfid/urovo_rfid_method_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  MethodChannelUrovoRfid platform = MethodChannelUrovoRfid();
  const MethodChannel channel = MethodChannel('urovo_rfid');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (MethodCall methodCall) async {
        if (methodCall.method == 'readTag') {
          return <String, dynamic>{
            'data': 'ABCD1234',
            'status': 'success',
            'errorCode': 0,
          };
        }
        return '42';
      },
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
  });

  test('getPlatformVersion', () async {
    expect(await platform.getPlatformVersion(), '42');
  });

  test('readTag returns structured response map', () async {
    expect(
      await platform.readTag('300833B2DDD9014000000000', 1, 2, 6, <int>[0, 0, 0, 0]),
      <String, dynamic>{
        'data': 'ABCD1234',
        'status': 'success',
        'errorCode': 0,
      },
    );
  });
}
