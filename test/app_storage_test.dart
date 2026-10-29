import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luma_convert/core/app_storage.dart';
import 'package:luma_convert/core/converter_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('app.luma.convert/storage');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  test(
    'native storage reads and writes JSON through the expected channel',
    () async {
      String? saved;
      messenger.setMockMethodCallHandler(channel, (call) async {
        if (call.method == 'write') saved = call.arguments as String;
        return call.method == 'read' ? saved : null;
      });
      final storage = DeviceStorage();
      await storage.write({'dark': false, 'precision': 4});
      expect(jsonDecode(saved!), {'dark': false, 'precision': 4});
      expect(await storage.read(), {'dark': false, 'precision': 4});
    },
  );

  test('missing, malformed and non-object JSON are safe to read', () async {
    for (final saved in [null, '{bad', '[]', '42']) {
      messenger.setMockMethodCallHandler(channel, (_) async => saved);
      expect(await DeviceStorage().read(), isEmpty);
    }
  });

  test('platform failures reach the controller on reads and writes', () async {
    messenger.setMockMethodCallHandler(channel, (_) async {
      throw PlatformException(code: 'STORAGE_UNAVAILABLE');
    });
    await expectLater(
      DeviceStorage().read(),
      throwsA(isA<PlatformException>()),
    );
    await expectLater(
      DeviceStorage().write({}),
      throwsA(isA<PlatformException>()),
    );
  });

  test(
    'native read failures do not stop conversion or hide storage status',
    () async {
      messenger.setMockMethodCallHandler(channel, (_) async {
        throw PlatformException(code: 'STORAGE_UNAVAILABLE');
      });
      final controller = ConverterController(DeviceStorage());
      addTearDown(controller.dispose);
      await controller.restore();
      expect(controller.storageAvailable, isFalse);
      controller.setInput('1000');
      expect(controller.output, '1');
    },
  );
}
