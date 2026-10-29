import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luma_convert/core/converter_controller.dart';
import 'package:luma_convert/core/converter_engine.dart';
import 'package:luma_convert/main.dart';

import 'converter_controller_test.dart' show MemoryStorage;

void main() {
  late ConverterController controller;

  setUp(() => controller = ConverterController(MemoryStorage()));
  tearDown(() => controller.dispose());

  Future<void> openApp(WidgetTester tester) async {
    await tester.pumpWidget(LumaConvertApp(controller: controller));
    await tester.pumpAndSettle();
  }

  Future<void> tapVisible(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  testWidgets('input, result, swap and clear stay synchronized', (
    tester,
  ) async {
    await openApp(tester);
    await tester.enterText(find.byKey(const ValueKey('input-field')), '2.5');
    await tester.pumpAndSettle();
    expect(find.text('0.0025'), findsOneWidget);
    await tapVisible(tester, find.byKey(const ValueKey('swap-button')));
    expect(controller.input, '0.0025');
    expect(controller.output, '2.5');
    expect(
      tester
          .widget<TextField>(find.byKey(const ValueKey('input-field')))
          .controller!
          .text,
      '0.0025',
    );
    await tapVisible(tester, find.byTooltip('Clear input'));
    expect(controller.input, isEmpty);
    expect(controller.output, '0');
    expect(tester.takeException(), isNull);
  });

  testWidgets('switching category clears the visible editor', (tester) async {
    await openApp(tester);
    await tester.enterText(find.byKey(const ValueKey('input-field')), '100');
    await tapVisible(
      tester,
      find.byKey(const ValueKey('category-temperature')),
    );
    expect(controller.category.name, 'temperature');
    expect(
      tester
          .widget<TextField>(find.byKey(const ValueKey('input-field')))
          .controller!
          .text,
      isEmpty,
    );
    await tester.enterText(find.byKey(const ValueKey('input-field')), '100');
    await tester.pumpAndSettle();
    expect(find.text('212'), findsOneWidget);
    await tapVisible(
      tester,
      find.byKey(const ValueKey('category-temperature')),
    );
    expect(controller.input, '100');
    expect(tester.takeException(), isNull);
  });

  testWidgets('both unit dropdowns update their selections', (tester) async {
    await openApp(tester);
    await tapVisible(tester, find.byKey(const ValueKey('from-unit')));
    await tester.tap(find.text('Kilometer  km').last);
    await tester.pumpAndSettle();
    expect(controller.fromId, 'kilometer');
    await tester.enterText(find.byKey(const ValueKey('input-field')), '2');
    await tapVisible(tester, find.byKey(const ValueKey('to-unit')));
    await tester.tap(find.text('Meter  m').last);
    await tester.pumpAndSettle();
    expect(controller.toId, 'meter');
    expect(controller.output, '2000');
    expect(tester.takeException(), isNull);
  });

  testWidgets('favorites, theme and precision settings remain usable', (
    tester,
  ) async {
    await openApp(tester);
    await tapVisible(
      tester,
      find.byKey(const ValueKey('category-temperature')),
    );
    await tapVisible(tester, find.byTooltip('Favorite category'));
    expect(controller.categories.first.name, 'temperature');
    await tapVisible(tester, find.byTooltip('Settings'));
    await tapVisible(tester, find.byKey(const ValueKey('theme-switch')));
    expect(controller.dark, isFalse);
    expect(
      tester.widget<Switch>(find.byKey(const ValueKey('theme-switch'))).value,
      isFalse,
    );
    await tapVisible(tester, find.byKey(const ValueKey('precision-select')));
    await tapVisible(tester, find.text('2').last);
    expect(controller.precision, 2);
    await tapVisible(tester, find.byTooltip('Close'));
    expect(tester.takeException(), isNull);
  });

  testWidgets('save, history reuse, clipboard and history clear work', (
    tester,
  ) async {
    String? copied;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'Clipboard.setData') {
            copied =
                (call.arguments as Map<Object?, Object?>)['text'] as String?;
          }
          return null;
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null),
    );
    await openApp(tester);
    await tester.enterText(find.byKey(const ValueKey('input-field')), '1234');
    await tapVisible(tester, find.byKey(const ValueKey('save-conversion')));
    expect(controller.recent, hasLength(1));
    await tapVisible(tester, find.byTooltip('Copy result'));
    expect(copied, '1.234');
    await tapVisible(
      tester,
      find.byKey(const ValueKey('category-temperature')),
    );
    await tapVisible(tester, find.byTooltip('Recent conversions'));
    await tapVisible(tester, find.text('Use conversion'));
    expect(controller.category.name, 'length');
    expect(controller.input, '1234');
    expect(
      tester
          .widget<TextField>(find.byKey(const ValueKey('input-field')))
          .controller!
          .text,
      '1234',
    );
    await tapVisible(tester, find.byTooltip('Recent conversions'));
    await tapVisible(tester, find.byTooltip('Clear all'));
    expect(controller.recent, isEmpty);
    await tapVisible(tester, find.byTooltip('Recent conversions'));
    expect(find.text('No saved conversions yet.'), findsOneWidget);
    await tapVisible(tester, find.byTooltip('Close'));
    expect(tester.takeException(), isNull);
  });

  testWidgets('keyboard insets do not overflow the converter', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    tester.view.viewInsets = const FakeViewPadding(bottom: 320);
    addTearDown(tester.view.reset);
    await openApp(tester);
    await tester.enterText(
      find.byKey(const ValueKey('input-field')),
      '-273.15',
    );
    await tester.pumpAndSettle();
    await tapVisible(tester, find.byTooltip('Settings'));
    expect(tester.takeException(), isNull);
  });

  for (final size in [
    const Size(240, 480),
    const Size(320, 480),
    const Size(320, 568),
    const Size(360, 640),
    const Size(360, 800),
    const Size(390, 844),
    const Size(412, 915),
    const Size(480, 320),
    const Size(640, 360),
    const Size(740, 360),
    const Size(800, 1280),
    const Size(1280, 800),
  ]) {
    for (final textScale in [1.0, 2.0, 3.0]) {
      testWidgets('responsive ${size.width}x${size.height}, text $textScale', (
        tester,
      ) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = size;
        tester.platformDispatcher.textScaleFactorTestValue = textScale;
        addTearDown(tester.view.reset);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        await openApp(tester);
        controller.chooseCategory(UnitCategory.speed);
        controller.setFrom('kilometer-hour');
        controller.setTo('foot-second');
        controller.setInput('1e30');
        controller.record();
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tapVisible(tester, find.byTooltip('Settings'));
        await tapVisible(tester, find.byKey(const ValueKey('theme-switch')));
        expect(tester.takeException(), isNull);
        await tapVisible(tester, find.byTooltip('Close'));
        await tapVisible(tester, find.byTooltip('Recent conversions'));
        expect(tester.takeException(), isNull);
        await tapVisible(tester, find.byTooltip('Close'));
      });
    }
  }

  testWidgets('rotation preserves input, units and result', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 800);
    addTearDown(tester.view.reset);
    await openApp(tester);
    await tester.enterText(find.byKey(const ValueKey('input-field')), '1234');
    await tester.pumpAndSettle();
    tester.view.physicalSize = const Size(800, 360);
    await tester.pumpAndSettle();
    expect(controller.input, '1234');
    expect(controller.output, '1.234');
    expect(find.text('1.234'), findsOneWidget);
    await tapVisible(tester, find.byTooltip('Settings'));
    expect(tester.takeException(), isNull);
    await tapVisible(tester, find.byTooltip('Close'));
    tester.view.physicalSize = const Size(360, 800);
    await tester.pumpAndSettle();
    expect(controller.input, '1234');
    expect(tester.takeException(), isNull);
  });

  for (final size in [const Size(320, 568), const Size(740, 360)]) {
    testWidgets(
      'large-text dropdowns stay usable at ${size.width}x${size.height}',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = size;
        tester.platformDispatcher.textScaleFactorTestValue = 3;
        addTearDown(tester.view.reset);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        controller.chooseCategory(UnitCategory.speed);
        controller.setInput('36');
        await openApp(tester);
        await tapVisible(tester, find.byKey(const ValueKey('from-unit')));
        await tapVisible(tester, find.text('Mile per hour  mph').last);
        expect(controller.fromId, 'mile-hour');
        await tapVisible(tester, find.byKey(const ValueKey('to-unit')));
        await tester.scrollUntilVisible(
          find.text('Foot per second  ft/s'),
          100,
          scrollable: find.byType(Scrollable).last,
        );
        await tapVisible(tester, find.text('Foot per second  ft/s').last);
        expect(controller.toId, 'foot-second');
        await tapVisible(tester, find.byTooltip('Settings'));
        await tapVisible(
          tester,
          find.byKey(const ValueKey('precision-select')),
        );
        await tester.scrollUntilVisible(
          find.text('12'),
          100,
          scrollable: find.byType(Scrollable).last,
        );
        await tapVisible(tester, find.text('12').last);
        expect(controller.precision, 12);
        await tapVisible(tester, find.byTooltip('Close'));
        expect(tester.takeException(), isNull);
      },
    );
  }

  for (final landscape in [false, true]) {
    testWidgets(
      'safe areas with ${landscape ? 'landscape' : 'portrait'} cutouts',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = landscape
            ? const Size(800, 360)
            : const Size(360, 800);
        final safeArea = landscape
            ? const FakeViewPadding(left: 48, right: 24, bottom: 24)
            : const FakeViewPadding(top: 48, bottom: 32);
        tester.view.padding = safeArea;
        tester.view.viewPadding = safeArea;
        tester.platformDispatcher.textScaleFactorTestValue = 2;
        addTearDown(tester.view.reset);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        await openApp(tester);
        await tapVisible(tester, find.byTooltip('Settings'));
        await tapVisible(tester, find.byTooltip('Close'));
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('landscape keyboard remains scrollable with large text', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(740, 360);
    tester.view.viewInsets = const FakeViewPadding(bottom: 180);
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await openApp(tester);
    await tester.enterText(find.byKey(const ValueKey('input-field')), '1e12');
    await tester.pumpAndSettle();
    await tester.drag(
      find.byKey(const ValueKey('main-scroll')),
      const Offset(0, -500),
    );
    await tester.pumpAndSettle();
    await tapVisible(tester, find.byKey(const ValueKey('save-conversion')));
    expect(controller.recent, hasLength(1));
    expect(tester.takeException(), isNull);
  });
}
