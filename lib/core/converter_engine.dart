enum UnitCategory {
  length('Length', '↔', 'Distance and dimensions'),
  weight('Weight', '◌', 'Mass and everyday weight'),
  temperature('Temperature', '°', 'Celsius, Fahrenheit and Kelvin'),
  area('Area', '▦', 'Surface measurements'),
  volume('Volume', '◇', 'Kitchen and liquid volume'),
  speed('Speed', '⚡', 'Travel and movement'),
  data('Data', '▤', 'Digital storage sizes'),
  time('Time', '◷', 'Seconds, hours and days');

  const UnitCategory(this.label, this.symbol, this.description);

  final String label;
  final String symbol;
  final String description;
}

class UnitDefinition {
  const UnitDefinition(this.id, this.label, this.symbol, this.toBase);

  final String id;
  final String label;
  final String symbol;
  final double Function(double) toBase;
}

class ConversionResult {
  const ConversionResult({required this.value, required this.text});

  final double value;
  final String text;

  bool get isValid => value.isFinite;
}

class ConverterEngine {
  const ConverterEngine();

  List<UnitDefinition> units(UnitCategory category) {
    return switch (category) {
      UnitCategory.length => _lengthUnits,
      UnitCategory.weight => _weightUnits,
      UnitCategory.temperature => _temperatureUnits,
      UnitCategory.area => _areaUnits,
      UnitCategory.volume => _volumeUnits,
      UnitCategory.speed => _speedUnits,
      UnitCategory.data => _dataUnits,
      UnitCategory.time => _timeUnits,
    };
  }

  ConversionResult convert({
    required UnitCategory category,
    required String from,
    required String to,
    required String input,
    int precision = 8,
  }) {
    final parsed = double.tryParse(input.trim().replaceAll(',', '.'));
    if (input.length > 80 || parsed == null || !parsed.isFinite) {
      return const ConversionResult(value: double.nan, text: '—');
    }
    final definitions = units(category);
    final sources = definitions.where((unit) => unit.id == from);
    final targets = definitions.where((unit) => unit.id == to);
    if (sources.isEmpty || targets.isEmpty) {
      return const ConversionResult(value: double.nan, text: '—');
    }
    final source = sources.first;
    final target = targets.first;
    var base = source.toBase(parsed);
    if (category == UnitCategory.temperature) {
      if (base < -1e-10) {
        return const ConversionResult(value: double.nan, text: '—');
      }
      if (base < 0) base = 0;
    }
    final value = from == to
        ? parsed
        : category == UnitCategory.temperature
        ? _fromTemperatureBase(base, target.id)
        : _fromFactorBase(base, target);
    return ConversionResult(value: value, text: format(value, precision));
  }

  String format(double value, int precision) {
    if (!value.isFinite) return '—';
    if (value == 0) return '0';
    final places = precision.clamp(0, 12);
    final fixed = value.toStringAsFixed(places);
    if (fixed.contains('e') || double.tryParse(fixed) == 0) {
      final parts = value.toStringAsExponential(places).split('e');
      return '${_trimFraction(parts.first)}e${parts.last}';
    }
    return _trimFraction(fixed);
  }

  static String _trimFraction(String value) {
    if (!value.contains('.')) return value;
    return value
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
  }

  static double _fromFactorBase(double base, UnitDefinition target) {
    final probe = target.toBase(1);
    return base / probe;
  }

  static double _fromTemperatureBase(double kelvin, String target) {
    return switch (target) {
      'celsius' => kelvin - 273.15,
      'fahrenheit' => (kelvin - 273.15) * 9 / 5 + 32,
      _ => kelvin,
    };
  }

  static UnitDefinition _factor(
    String id,
    String label,
    String symbol,
    double factor,
  ) {
    return UnitDefinition(id, label, symbol, (value) => value * factor);
  }

  static final _lengthUnits = <UnitDefinition>[
    _factor('meter', 'Meter', 'm', 1),
    _factor('kilometer', 'Kilometer', 'km', 1000),
    _factor('centimeter', 'Centimeter', 'cm', .01),
    _factor('millimeter', 'Millimeter', 'mm', .001),
    _factor('inch', 'Inch', 'in', .0254),
    _factor('foot', 'Foot', 'ft', .3048),
    _factor('yard', 'Yard', 'yd', .9144),
    _factor('mile', 'Mile', 'mi', 1609.344),
  ];

  static final _weightUnits = <UnitDefinition>[
    _factor('kilogram', 'Kilogram', 'kg', 1),
    _factor('gram', 'Gram', 'g', .001),
    _factor('milligram', 'Milligram', 'mg', .000001),
    _factor('pound', 'Pound', 'lb', .45359237),
    _factor('ounce', 'Ounce', 'oz', .028349523125),
    _factor('stone', 'Stone', 'st', 6.35029318),
  ];

  static final _temperatureUnits = <UnitDefinition>[
    UnitDefinition('celsius', 'Celsius', '°C', (value) => value + 273.15),
    UnitDefinition(
      'fahrenheit',
      'Fahrenheit',
      '°F',
      (value) => (value - 32) * 5 / 9 + 273.15,
    ),
    UnitDefinition('kelvin', 'Kelvin', 'K', (value) => value),
  ];

  static final _areaUnits = <UnitDefinition>[
    _factor('square-meter', 'Square meter', 'm²', 1),
    _factor('square-kilometer', 'Square kilometer', 'km²', 1000000),
    _factor('square-foot', 'Square foot', 'ft²', .09290304),
    _factor('square-yard', 'Square yard', 'yd²', .83612736),
    _factor('acre', 'Acre', 'ac', 4046.8564224),
    _factor('hectare', 'Hectare', 'ha', 10000),
  ];

  static final _volumeUnits = <UnitDefinition>[
    _factor('liter', 'Liter', 'L', 1),
    _factor('milliliter', 'Milliliter', 'mL', .001),
    _factor('cubic-meter', 'Cubic meter', 'm³', 1000),
    _factor('gallon', 'US gallon', 'gal', 3.785411784),
    _factor('quart', 'US quart', 'qt', .946352946),
    _factor('cup', 'US cup', 'cup', .2365882365),
  ];

  static final _speedUnits = <UnitDefinition>[
    _factor('meter-second', 'Meter per second', 'm/s', 1),
    _factor('kilometer-hour', 'Kilometer per hour', 'km/h', .2777777777777778),
    _factor('mile-hour', 'Mile per hour', 'mph', .44704),
    _factor('knot', 'Knot', 'kn', .5144444444444445),
    _factor('foot-second', 'Foot per second', 'ft/s', .3048),
  ];

  static final _dataUnits = <UnitDefinition>[
    _factor('byte', 'Byte', 'B', 1),
    _factor('kilobyte', 'Kilobyte', 'KB', 1000),
    _factor('megabyte', 'Megabyte', 'MB', 1000000),
    _factor('gigabyte', 'Gigabyte', 'GB', 1000000000),
    _factor('terabyte', 'Terabyte', 'TB', 1000000000000),
    _factor('kibibyte', 'Kibibyte', 'KiB', 1024),
    _factor('mebibyte', 'Mebibyte', 'MiB', 1048576),
    _factor('gibibyte', 'Gibibyte', 'GiB', 1073741824),
  ];

  static final _timeUnits = <UnitDefinition>[
    _factor('second', 'Second', 's', 1),
    _factor('minute', 'Minute', 'min', 60),
    _factor('hour', 'Hour', 'h', 3600),
    _factor('day', 'Day', 'd', 86400),
    _factor('week', 'Week', 'wk', 604800),
  ];
}
