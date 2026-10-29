import 'package:flutter_test/flutter_test.dart';
import 'package:luma_convert/core/converter_engine.dart';

void main() {
  const engine = ConverterEngine();

  test('length conversion', () {
    expect(
      engine
          .convert(
            category: UnitCategory.length,
            from: 'kilometer',
            to: 'meter',
            input: '2.5',
          )
          .value,
      2500,
    );
    expect(
      engine
          .convert(
            category: UnitCategory.length,
            from: 'inch',
            to: 'centimeter',
            input: '10',
          )
          .value,
      closeTo(25.4, 1e-10),
    );
  });

  test('temperature conversion', () {
    expect(
      engine
          .convert(
            category: UnitCategory.temperature,
            from: 'celsius',
            to: 'fahrenheit',
            input: '100',
          )
          .value,
      212,
    );
    expect(
      engine
          .convert(
            category: UnitCategory.temperature,
            from: 'fahrenheit',
            to: 'celsius',
            input: '32',
          )
          .value,
      0,
    );
    expect(
      engine
          .convert(
            category: UnitCategory.temperature,
            from: 'kelvin',
            to: 'celsius',
            input: '273.15',
          )
          .value,
      closeTo(0, 1e-10),
    );
  });

  test('other categories convert through their base unit', () {
    expect(
      engine
          .convert(
            category: UnitCategory.weight,
            from: 'kilogram',
            to: 'pound',
            input: '1',
          )
          .value,
      closeTo(2.2046226218, 1e-9),
    );
    expect(
      engine
          .convert(
            category: UnitCategory.area,
            from: 'acre',
            to: 'square-meter',
            input: '1',
          )
          .value,
      closeTo(4046.8564224, 1e-7),
    );
    expect(
      engine
          .convert(
            category: UnitCategory.volume,
            from: 'liter',
            to: 'milliliter',
            input: '2',
          )
          .value,
      2000,
    );
    expect(
      engine
          .convert(
            category: UnitCategory.speed,
            from: 'kilometer-hour',
            to: 'meter-second',
            input: '36',
          )
          .value,
      10,
    );
    expect(
      engine
          .convert(
            category: UnitCategory.data,
            from: 'gibibyte',
            to: 'byte',
            input: '1',
          )
          .value,
      1073741824,
    );
    expect(
      engine
          .convert(
            category: UnitCategory.time,
            from: 'day',
            to: 'hour',
            input: '2',
          )
          .value,
      48,
    );
  });

  test('invalid input returns a safe empty result', () {
    expect(
      engine
          .convert(
            category: UnitCategory.length,
            from: 'meter',
            to: 'kilometer',
            input: '1,5',
          )
          .text,
      '0.0015',
    );
    expect(
      engine
          .convert(
            category: UnitCategory.length,
            from: 'meter',
            to: 'kilometer',
            input: 'abc',
          )
          .text,
      '—',
    );
    expect(
      engine
          .convert(
            category: UnitCategory.length,
            from: 'meter',
            to: 'kilometer',
            input: '',
          )
          .text,
      '—',
    );
  });

  test('formatting follows requested precision', () {
    expect(
      engine
          .convert(
            category: UnitCategory.length,
            from: 'meter',
            to: 'kilometer',
            input: '1234',
            precision: 2,
          )
          .text,
      '1.23',
    );
    expect(engine.format(-0.0, 4), '0');
  });

  test('large exponents keep every exponent digit', () {
    expect(engine.format(1e30, 8), '1e+30');
    expect(engine.format(-1.25e100, 4), '-1.25e+100');
    expect(engine.format(1000, 0), '1000');
  });

  test('small nonzero results do not round to zero', () {
    expect(engine.format(0.00000123, 2), '1.23e-6');
    expect(engine.format(-1e-30, 8), '-1e-30');
    expect(engine.format(1e-10, 1000), '0.0000000001');
    expect(engine.format(1e-100, -10), '1e-100');
  });

  test('nonfinite input, unknown units and overflow are safe', () {
    for (final input in ['NaN', 'Infinity', '1e999', '--1', '1.2.3']) {
      expect(
        engine
            .convert(
              category: UnitCategory.length,
              from: 'meter',
              to: 'kilometer',
              input: input,
            )
            .isValid,
        isFalse,
      );
    }
    expect(
      engine
          .convert(
            category: UnitCategory.length,
            from: 'unknown',
            to: 'meter',
            input: '1',
          )
          .isValid,
      isFalse,
    );
    expect(
      engine
          .convert(
            category: UnitCategory.length,
            from: 'kilometer',
            to: 'millimeter',
            input: '1e308',
          )
          .text,
      '—',
    );
  });

  test('temperatures respect absolute zero', () {
    for (final from in ['celsius', 'fahrenheit', 'kelvin']) {
      expect(
        engine
            .convert(
              category: UnitCategory.temperature,
              from: from,
              to: 'kelvin',
              input: '-1000',
            )
            .isValid,
        isFalse,
      );
    }
    expect(
      engine
          .convert(
            category: UnitCategory.temperature,
            from: 'fahrenheit',
            to: 'kelvin',
            input: '-459.67',
          )
          .text,
      '0',
    );
  });

  for (final category in UnitCategory.values) {
    test('${category.name} conversions round trip through every unit pair', () {
      for (final from in engine.units(category)) {
        for (final to in engine.units(category)) {
          final result = engine.convert(
            category: category,
            from: from.id,
            to: to.id,
            input: '123.456',
          );
          expect(result.isValid, isTrue);
          final restored = engine.convert(
            category: category,
            from: to.id,
            to: from.id,
            input: result.value.toString(),
          );
          expect(restored.value, closeTo(123.456, 1e-8));
        }
      }
    });
  }
}
