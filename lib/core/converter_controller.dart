import 'dart:async';

import 'package:flutter/foundation.dart';

import 'app_storage.dart';
import 'converter_engine.dart';

class ConversionRecord {
  const ConversionRecord({
    required this.category,
    required this.from,
    required this.to,
    required this.input,
    required this.output,
  });

  final UnitCategory category;
  final String from;
  final String to;
  final String input;
  final String output;

  Map<String, String> toJson() => {
    'category': category.name,
    'from': from,
    'to': to,
    'input': input,
    'output': output,
  };

  static ConversionRecord? fromJson(Object? value) {
    if (value is! Map<String, dynamic>) return null;
    final categoryName = value['category'];
    final from = value['from'];
    final to = value['to'];
    final input = value['input'];
    final output = value['output'];
    if (categoryName is! String ||
        from is! String ||
        to is! String ||
        input is! String ||
        output is! String ||
        input.length > 80 ||
        output.length > 80) {
      return null;
    }
    final categories = UnitCategory.values.where(
      (item) => item.name == categoryName,
    );
    if (categories.isEmpty) return null;
    final category = categories.first;
    final result = const ConverterEngine().convert(
      category: category,
      from: from,
      to: to,
      input: input,
    );
    if (!result.isValid || double.tryParse(output)?.isFinite != true) {
      return null;
    }
    return ConversionRecord(
      category: category,
      from: from,
      to: to,
      input: input,
      output: output,
    );
  }
}

class ConverterController extends ChangeNotifier {
  ConverterController(this.storage);

  final AppStorage storage;
  final ConverterEngine engine = const ConverterEngine();
  UnitCategory category = UnitCategory.length;
  String fromId = 'meter';
  String toId = 'kilometer';
  String input = '';
  String output = '0';
  bool dark = true;
  int precision = 8;
  bool storageAvailable = true;
  final Set<UnitCategory> favorites = {};
  final List<ConversionRecord> recent = [];
  Timer? _saveTimer;
  Future<void> _pendingWrite = Future<void>.value();
  bool _disposed = false;

  List<UnitDefinition> get units => engine.units(category);
  UnitDefinition get fromUnit => units.firstWhere((unit) => unit.id == fromId);
  UnitDefinition get toUnit => units.firstWhere((unit) => unit.id == toId);

  List<UnitCategory> get categories => [
    ...UnitCategory.values.where(favorites.contains),
    ...UnitCategory.values.where((item) => !favorites.contains(item)),
  ];

  Future<void> restore() async {
    Map<String, Object?> state;
    try {
      state = await storage.read();
    } on Object {
      if (!_disposed) {
        storageAvailable = false;
        notifyListeners();
      }
      return;
    }
    if (_disposed) return;
    dark = state['dark'] != false;
    final savedPrecision = state['precision'];
    precision = savedPrecision is num && savedPrecision.isFinite
        ? savedPrecision.toInt().clamp(2, 12)
        : 8;
    favorites.clear();
    final savedFavorites = state['favorites'];
    if (savedFavorites is List<Object?>) {
      favorites.addAll(
        UnitCategory.values.where((item) => savedFavorites.contains(item.name)),
      );
    }
    recent.clear();
    final savedRecent = state['recent'];
    if (savedRecent is List<Object?>) {
      recent.addAll(
        savedRecent
            .map(ConversionRecord.fromJson)
            .whereType<ConversionRecord>()
            .take(20),
      );
    }
    _updateResult();
  }

  void chooseCategory(UnitCategory value) {
    if (category == value) return;
    category = value;
    fromId = units.first.id;
    toId = units[1].id;
    input = '';
    _updateResult();
  }

  void setInput(String value) {
    input = value;
    _updateResult();
  }

  void setFrom(String id) {
    if (!units.any((unit) => unit.id == id)) return;
    fromId = id;
    _updateResult();
  }

  void setTo(String id) {
    if (!units.any((unit) => unit.id == id)) return;
    toId = id;
    _updateResult();
  }

  void swap() {
    final result = engine.convert(
      category: category,
      from: fromId,
      to: toId,
      input: input,
    );
    final oldFrom = fromId;
    fromId = toId;
    toId = oldFrom;
    if (result.isValid) {
      final value = result.value.toString();
      input = value.endsWith('.0')
          ? value.substring(0, value.length - 2)
          : value;
    }
    _updateResult();
  }

  void toggleFavorite() {
    if (!favorites.add(category)) favorites.remove(category);
    _changed(save: true);
  }

  void toggleTheme() {
    dark = !dark;
    _changed(save: true);
  }

  void setPrecision(int value) {
    precision = value.clamp(2, 12);
    _updateResult(save: true);
  }

  void clear() {
    input = '';
    _updateResult();
  }

  void record() {
    if (input.trim().isEmpty || output == '—') return;
    recent.removeWhere(
      (item) =>
          item.category == category &&
          item.from == fromId &&
          item.to == toId &&
          item.input == input,
    );
    recent.insert(
      0,
      ConversionRecord(
        category: category,
        from: fromId,
        to: toId,
        input: input,
        output: output,
      ),
    );
    if (recent.length > 20) recent.removeRange(20, recent.length);
    _changed(save: true);
  }

  void useRecent(ConversionRecord value) {
    if (ConversionRecord.fromJson(value.toJson()) == null) return;
    category = value.category;
    fromId = value.from;
    toId = value.to;
    input = value.input;
    _updateResult();
  }

  void clearRecent() {
    recent.clear();
    _changed(save: true);
  }

  void _updateResult({bool save = false}) {
    output = input.trim().isEmpty
        ? '0'
        : engine
              .convert(
                category: category,
                from: fromId,
                to: toId,
                input: input,
                precision: precision,
              )
              .text;
    _changed(save: save);
  }

  void _changed({bool save = false}) {
    if (_disposed) return;
    notifyListeners();
    if (!save) return;
    _saveTimer?.cancel();
    _saveTimer = Timer(
      const Duration(milliseconds: 250),
      () => unawaited(persist()),
    );
  }

  Future<void> persist() {
    _saveTimer?.cancel();
    final state = <String, Object?>{
      'dark': dark,
      'precision': precision,
      'favorites': favorites.map((value) => value.name).toList(),
      'recent': recent.map((value) => value.toJson()).toList(),
    };
    _pendingWrite = _pendingWrite.then((_) async {
      var available = true;
      try {
        await storage.write(state);
      } on Object {
        available = false;
      }
      if (!_disposed && storageAvailable != available) {
        storageAvailable = available;
        notifyListeners();
      }
    });
    return _pendingWrite;
  }

  @override
  void dispose() {
    if (_saveTimer?.isActive == true) unawaited(persist());
    _saveTimer?.cancel();
    _disposed = true;
    super.dispose();
  }
}
