import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:luma_convert/core/app_storage.dart';
import 'package:luma_convert/core/converter_controller.dart';
import 'package:luma_convert/core/converter_engine.dart';

class MemoryStorage implements AppStorage {
  Map<String, Object?> value = {};

  @override
  Future<Map<String, Object?>> read() async => value;

  @override
  Future<void> write(Map<String, Object?> state) async => value = state;
}

class FailingStorage implements AppStorage {
  @override
  Future<Map<String, Object?>> read() async => throw StateError('unavailable');

  @override
  Future<void> write(Map<String, Object?> state) async =>
      throw StateError('unavailable');
}

class DelayedStorage extends MemoryStorage {
  final release = Completer<void>();
  int writes = 0;

  @override
  Future<void> write(Map<String, Object?> state) async {
    if (++writes == 1) await release.future;
    value = state;
  }
}

void main() {
  late MemoryStorage storage;
  late ConverterController controller;

  setUp(() {
    storage = MemoryStorage();
    controller = ConverterController(storage);
  });

  tearDown(() => controller.dispose());

  test('category selection resets compatible units', () {
    controller.chooseCategory(UnitCategory.temperature);
    expect(controller.fromUnit.id, 'celsius');
    expect(controller.toUnit.id, 'fahrenheit');
    controller.setInput('100');
    expect(controller.output, '212');
  });

  test('swap reverses units and keeps the displayed value', () {
    controller.setInput('2');
    controller.setFrom('kilometer');
    controller.setTo('meter');
    expect(controller.output, '2000');
    controller.swap();
    expect(controller.fromId, 'meter');
    expect(controller.toId, 'kilometer');
    expect(controller.input, '2000');
    expect(controller.output, '2');
  });

  test('favorites, precision, and recent conversions work', () async {
    controller.toggleFavorite();
    expect(controller.favorites, contains(UnitCategory.length));
    controller.setPrecision(3);
    controller.setInput('1234');
    controller.setFrom('meter');
    controller.setTo('kilometer');
    controller.record();
    expect(controller.recent.length, 1);
    await controller.persist();
    final restored = ConverterController(storage);
    await restored.restore();
    expect(restored.favorites, contains(UnitCategory.length));
    expect(restored.precision, 3);
    expect(restored.recent, hasLength(1));
    expect(restored.recent.first.output, '1.234');
    restored.dispose();
  });

  test('theme, clear and recent removal work', () {
    expect(controller.dark, isTrue);
    controller.toggleTheme();
    expect(controller.dark, isFalse);
    controller.setInput('5');
    controller.record();
    expect(controller.recent, isNotEmpty);
    controller.clearRecent();
    controller.clear();
    expect(controller.recent, isEmpty);
    expect(controller.input, isEmpty);
    expect(controller.output, '0');
  });

  test('reselecting a category preserves input and clear stays at zero', () {
    controller.setInput('12.5');
    controller.chooseCategory(UnitCategory.length);
    expect(controller.input, '12.5');
    controller.clear();
    controller.setPrecision(2);
    controller.setTo('mile');
    controller.swap();
    expect(controller.output, '0');
    expect(controller.input, isEmpty);
  });

  test('swap uses the full result rather than rounded display text', () {
    controller.setPrecision(2);
    controller.setInput('1');
    controller.setTo('mile');
    expect(controller.output, isNot('1'));
    controller.swap();
    expect(controller.output, '1');
    controller.swap();
    expect(double.parse(controller.input), closeTo(1, 1e-12));
  });

  test('history reuse recalculates using current precision', () {
    controller.setPrecision(8);
    controller.setInput('1234.567');
    controller.record();
    final record = controller.recent.first;
    controller.setPrecision(2);
    controller.chooseCategory(UnitCategory.time);
    controller.useRecent(record);
    expect(controller.output, '1.23');
    expect(controller.category, UnitCategory.length);
  });

  test('history is bounded, deduplicated, and excludes invalid input', () {
    for (var i = 0; i < 25; i++) {
      controller.setInput('$i');
      controller.record();
    }
    expect(controller.recent, hasLength(20));
    controller.record();
    expect(controller.recent, hasLength(20));
    expect(controller.recent.first.input, '24');
    controller.setInput('NaN');
    controller.record();
    expect(controller.recent, hasLength(20));
  });

  test('favorites move to the front in a stable order', () {
    controller.chooseCategory(UnitCategory.time);
    controller.toggleFavorite();
    expect(controller.categories.first, UnitCategory.time);
    controller.toggleFavorite();
    expect(controller.categories.first, UnitCategory.length);
  });

  test('malformed stored values do not crash restoration', () async {
    storage.value = {
      'precision': double.nan,
      'favorites': ['unknown', 'time', null, 2],
      'recent': [
        {
          'category': 'length',
          'from': 'bad',
          'to': 'meter',
          'input': '1',
          'output': '1',
        },
        {
          'category': 'length',
          'from': 'meter',
          'to': 'mile',
          'input': 'NaN',
          'output': '1',
        },
        null,
        'invalid',
      ],
    };
    await controller.restore();
    expect(controller.precision, 8);
    expect(controller.favorites, {UnitCategory.time});
    expect(controller.recent, isEmpty);
    controller.setFrom('unknown');
    controller.setTo('unknown');
    expect(controller.fromId, 'meter');
    expect(controller.toId, 'kilometer');
  });

  test(
    'storage failures leave conversions usable without uncaught errors',
    () async {
      final failing = ConverterController(FailingStorage());
      await failing.restore();
      expect(failing.storageAvailable, isFalse);
      failing.setInput('1000');
      expect(failing.output, '1');
      failing.toggleTheme();
      await failing.persist();
      expect(failing.storageAvailable, isFalse);
      failing.dispose();
    },
  );

  test('queued writes cannot overwrite newer preferences', () async {
    final delayed = DelayedStorage();
    final saving = ConverterController(delayed);
    final first = saving.persist();
    await Future<void>.delayed(Duration.zero);
    saving.toggleTheme();
    final second = saving.persist();
    delayed.release.complete();
    await Future.wait([first, second]);
    expect(delayed.value['dark'], isFalse);
    saving.dispose();
  });
}
