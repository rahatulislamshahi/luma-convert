import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/converter_controller.dart';
import '../core/converter_engine.dart';
import 'glass_widgets.dart';
import 'palette.dart';

class ConverterScreen extends StatefulWidget {
  const ConverterScreen({super.key, required this.controller});

  final ConverterController controller;

  @override
  State<ConverterScreen> createState() => _ConverterScreenState();
}

class _ConverterScreenState extends State<ConverterScreen>
    with WidgetsBindingObserver {
  late final TextEditingController _inputEditor;

  ConverterController get calc => widget.controller;
  AppPalette get palette => AppPalette(calc.dark);

  @override
  void initState() {
    super.initState();
    _inputEditor = TextEditingController(text: calc.input);
    calc.addListener(_syncInput);
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didUpdateWidget(covariant ConverterScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != calc) {
      oldWidget.controller.removeListener(_syncInput);
      calc.addListener(_syncInput);
      _syncInput();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) unawaited(calc.persist());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    calc.removeListener(_syncInput);
    _inputEditor.dispose();
    super.dispose();
  }

  void _syncInput() {
    if (_inputEditor.text == calc.input) return;
    _inputEditor.value = TextEditingValue(
      text: calc.input,
      selection: TextSelection.collapsed(offset: calc.input.length),
    );
  }

  void _message(String value) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(value), duration: const Duration(seconds: 2)),
      );
  }

  void _save() {
    if (calc.output == '—' || calc.input.trim().isEmpty) return;
    calc.record();
    _message('Conversion saved');
  }

  Future<void> _copy() async {
    if (calc.output == '—') return;
    try {
      await Clipboard.setData(ClipboardData(text: calc.output));
      if (mounted) _message('Result copied to clipboard');
    } on PlatformException {
      if (mounted) _message('Clipboard is unavailable');
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = palette;
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(child: ColoredBox(color: p.background)),
          Positioned(
            top: -180,
            right: -170,
            child: _orb(480, p.accentStrong.withValues(alpha: .16)),
          ),
          Positioned(
            bottom: -220,
            left: -240,
            child: _orb(560, p.mint.withValues(alpha: .1)),
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: SingleChildScrollView(
                  key: const ValueKey('main-scroll'),
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _header(p),
                      const SizedBox(height: 24),
                      _intro(p),
                      const SizedBox(height: 20),
                      _categories(p),
                      const SizedBox(height: 20),
                      _conversionArea(p),
                      const SizedBox(height: 20),
                      _recentPreview(p),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _orb(double size, Color color) => IgnorePointer(
    child: SizedBox.square(
      dimension: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
        ),
      ),
    ),
  );

  Widget _header(AppPalette p) => LayoutBuilder(
    builder: (context, constraints) {
      final compact = constraints.maxWidth < 340;
      return Row(
        children: [
          Container(
            width: compact ? 36 : 48,
            height: compact ? 36 : 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(compact ? 12 : 16),
              gradient: const LinearGradient(
                colors: [Color(0xFFD9C6FF), Color(0xFF9876E0)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(color: const Color(0x44FFFFFF)),
            ),
            child: const Icon(
              Icons.swap_horiz_rounded,
              color: Color(0xFF2C2145),
              size: 26,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'luma.',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: p.text,
                    fontSize: compact ? 23 : 28,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -1,
                  ),
                ),
                if (!compact)
                  Text(
                    'convert everyday numbers',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: p.secondary, fontSize: 11),
                  ),
              ],
            ),
          ),
          RoundIconButton(
            icon: Icons.history_rounded,
            label: 'Recent conversions',
            palette: p,
            onPressed: _historySheet,
          ),
          const SizedBox(width: 4),
          RoundIconButton(
            icon: Icons.tune_rounded,
            label: 'Settings',
            palette: p,
            onPressed: _settingsSheet,
          ),
        ],
      );
    },
  );

  Widget _intro(AppPalette p) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Make every unit make sense.',
        style: TextStyle(
          color: p.text,
          fontSize: 26,
          fontWeight: FontWeight.w500,
          letterSpacing: -.7,
        ),
      ),
      const SizedBox(height: 6),
      Text(
        'A quiet, quick converter that stays on your device.',
        style: TextStyle(color: p.secondary, fontSize: 14),
      ),
    ],
  );

  Widget _categories(AppPalette p) => SingleChildScrollView(
    key: const ValueKey('category-scroll'),
    scrollDirection: Axis.horizontal,
    child: Row(
      children: [
        for (final item in calc.categories)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: CategoryChip(
              key: ValueKey('category-${item.name}'),
              label: item.label,
              icon: switch (item) {
                UnitCategory.length => Icons.straighten_rounded,
                UnitCategory.weight => Icons.scale_rounded,
                UnitCategory.temperature => Icons.thermostat_rounded,
                UnitCategory.area => Icons.grid_4x4_rounded,
                UnitCategory.volume => Icons.water_drop_outlined,
                UnitCategory.speed => Icons.speed_rounded,
                UnitCategory.data => Icons.storage_rounded,
                UnitCategory.time => Icons.schedule_rounded,
              },
              selected: calc.category == item,
              favorite: calc.favorites.contains(item),
              palette: p,
              onPressed: () => calc.chooseCategory(item),
            ),
          ),
      ],
    ),
  );

  Widget _conversionArea(AppPalette p) => LayoutBuilder(
    builder: (context, constraints) {
      final wide =
          constraints.maxWidth >= 680 &&
          MediaQuery.textScalerOf(context).scale(14) <= 21;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (wide)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _inputCard(p)),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 90,
                  ),
                  child: _swapButton(p),
                ),
                Expanded(child: _resultCard(p)),
              ],
            )
          else ...[
            _inputCard(p),
            const SizedBox(height: 12),
            Center(child: _swapButton(p)),
            const SizedBox(height: 12),
            _resultCard(p),
          ],
          const SizedBox(height: 12),
          _precisionBar(p),
        ],
      );
    },
  );

  Widget _inputCard(AppPalette p) => GlassSurface(
    palette: p,
    blur: true,
    radius: 26,
    padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: _eyebrow('FROM', p)),
            IconButton(
              tooltip: 'Clear input',
              onPressed: calc.input.isEmpty ? null : calc.clear,
              icon: Icon(Icons.backspace_outlined, color: p.secondary),
            ),
            IconButton(
              tooltip: 'Favorite category',
              onPressed: calc.toggleFavorite,
              isSelected: calc.favorites.contains(calc.category),
              icon: Icon(Icons.star_border_rounded, color: p.secondary),
              selectedIcon: Icon(Icons.star_rounded, color: p.accent),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _unitSelect(calc.fromId, 'from-unit', p, calc.setFrom),
        const SizedBox(height: 16),
        TextField(
          key: const ValueKey('input-field'),
          controller: _inputEditor,
          maxLength: 80,
          keyboardType: const TextInputType.numberWithOptions(
            decimal: true,
            signed: true,
          ),
          textInputAction: TextInputAction.done,
          onChanged: calc.setInput,
          onSubmitted: (_) => _save(),
          style: TextStyle(
            color: p.text,
            fontSize: 38,
            fontWeight: FontWeight.w300,
            letterSpacing: -1,
          ),
          decoration: InputDecoration(
            hintText: '0',
            counterText: '',
            semanticCounterText: '',
            suffixText: calc.fromUnit.symbol,
            suffixStyle: TextStyle(color: p.secondary, fontSize: 15),
            border: InputBorder.none,
            isDense: true,
          ),
        ),
        if (calc.output == '—' && calc.input.trim().isNotEmpty)
          Text(
            calc.category == UnitCategory.temperature
                ? 'Enter a valid temperature at or above absolute zero.'
                : 'Enter a finite number, such as 12.5 or 1e6.',
            style: TextStyle(color: p.error, fontSize: 12),
          ),
        const SizedBox(height: 4),
        Text(
          calc.fromUnit.label,
          textAlign: TextAlign.right,
          style: TextStyle(color: p.secondary, fontSize: 12),
        ),
      ],
    ),
  );

  Widget _resultCard(AppPalette p) => GlassSurface(
    palette: p,
    blur: true,
    radius: 26,
    padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: _eyebrow('RESULT', p)),
            IconButton(
              tooltip: 'Copy result',
              onPressed: calc.output == '—' ? null : () => unawaited(_copy()),
              icon: const Icon(Icons.copy_rounded),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _unitSelect(calc.toId, 'to-unit', p, calc.setTo),
        const SizedBox(height: 16),
        Semantics(
          liveRegion: true,
          label: 'Result: ${calc.output} ${calc.toUnit.symbol}',
          child: ExcludeSemantics(
            child: Align(
              alignment: Alignment.centerRight,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  calc.output,
                  key: const ValueKey('result-value'),
                  maxLines: 1,
                  style: TextStyle(
                    color: p.accent,
                    fontSize: 38,
                    fontWeight: FontWeight.w300,
                    letterSpacing: -1,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          calc.toUnit.symbol,
          textAlign: TextAlign.right,
          style: TextStyle(color: p.secondary, fontSize: 15),
        ),
      ],
    ),
  );

  Widget _unitSelect(
    String selected,
    String key,
    AppPalette p,
    ValueChanged<String> onChanged,
  ) => DecoratedBox(
    decoration: BoxDecoration(
      color: p.surfaceRaised.withValues(alpha: .65),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: p.line),
    ),
    child: DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        key: ValueKey(key),
        value: selected,
        isExpanded: true,
        itemHeight: null,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        dropdownColor: p.surface,
        icon: Icon(Icons.keyboard_arrow_down_rounded, color: p.secondary),
        style: TextStyle(
          color: p.text,
          fontFamily: 'Roboto',
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        items: [
          for (final unit in calc.units)
            DropdownMenuItem(
              value: unit.id,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Text(
                  '${unit.label}  ${unit.symbol}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
        ],
        onChanged: (value) {
          if (value != null) onChanged(value);
        },
      ),
    ),
  );

  Widget _swapButton(AppPalette p) => IconButton(
    key: const ValueKey('swap-button'),
    tooltip: 'Swap units',
    onPressed: calc.swap,
    style: IconButton.styleFrom(
      minimumSize: const Size(52, 52),
      foregroundColor: p.accent,
      backgroundColor: p.operator,
      side: BorderSide(color: p.line),
    ),
    icon: const Icon(Icons.swap_horiz_rounded),
  );

  Widget _precisionBar(AppPalette p) => GlassSurface(
    palette: p,
    radius: 18,
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    child: Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 12,
      runSpacing: 2,
      children: [
        Text(
          'Decimal places',
          style: TextStyle(color: p.secondary, fontSize: 12),
        ),
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            IconButton(
              tooltip: 'Fewer decimal places',
              onPressed: calc.precision <= 2
                  ? null
                  : () => calc.setPrecision(calc.precision - 1),
              icon: const Icon(Icons.remove_rounded),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                '${calc.precision}',
                style: TextStyle(color: p.text, fontWeight: FontWeight.w600),
              ),
            ),
            IconButton(
              tooltip: 'More decimal places',
              onPressed: calc.precision >= 12
                  ? null
                  : () => calc.setPrecision(calc.precision + 1),
              icon: const Icon(Icons.add_rounded),
            ),
            TextButton(
              key: const ValueKey('save-conversion'),
              onPressed: calc.output == '—' || calc.input.trim().isEmpty
                  ? null
                  : _save,
              child: const Text('Save'),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _eyebrow(String value, AppPalette p) => Text(
    value,
    style: TextStyle(
      color: p.mint,
      fontSize: 10,
      fontWeight: FontWeight.w700,
      letterSpacing: 1.3,
    ),
  );

  Widget _recentPreview(AppPalette p) => GlassSurface(
    palette: p,
    radius: 22,
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(Icons.history_rounded, color: p.accent),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Recent conversions',
                style: TextStyle(color: p.text, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          calc.recent.isEmpty
              ? 'Save a conversion to find it here next time.'
              : _recordText(calc.recent.first),
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: p.secondary, height: 1.4),
        ),
        if (calc.recent.isNotEmpty)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _historySheet,
              child: const Text('View all'),
            ),
          ),
      ],
    ),
  );

  String _recordText(ConversionRecord record) {
    final units = calc.engine.units(record.category);
    final from = units.firstWhere((unit) => unit.id == record.from).symbol;
    final to = units.firstWhere((unit) => unit.id == record.to).symbol;
    return '${record.input} $from  →  ${record.output} $to';
  }

  void _historySheet() {
    FocusScope.of(context).unfocus();
    unawaited(
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: Colors.transparent,
        builder: (context) => _sheetFrame(
          palette,
          title: 'Recent conversions',
          subtitle: '${calc.recent.length} saved on this device',
          action: calc.recent.isEmpty
              ? null
              : IconButton(
                  tooltip: 'Clear all',
                  onPressed: () {
                    calc.clearRecent();
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.delete_outline_rounded),
                ),
          child: calc.recent.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 48),
                  child: Text(
                    'No saved conversions yet.',
                    style: TextStyle(color: palette.secondary),
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final item in calc.recent)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: GlassSurface(
                          palette: palette,
                          radius: 18,
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                _recordText(item),
                                style: TextStyle(
                                  color: palette.text,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                item.category.label,
                                style: TextStyle(
                                  color: palette.secondary,
                                  fontSize: 12,
                                ),
                              ),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton.icon(
                                  onPressed: () {
                                    calc.useRecent(item);
                                    Navigator.pop(context);
                                  },
                                  icon: const Icon(Icons.arrow_forward_rounded),
                                  label: const Text('Use conversion'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
        ),
      ),
    );
  }

  void _settingsSheet() {
    FocusScope.of(context).unfocus();
    unawaited(
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: Colors.transparent,
        builder: (context) => ListenableBuilder(
          listenable: calc,
          builder: (context, _) {
            final p = palette;
            return _sheetFrame(
              p,
              title: 'Make it yours',
              subtitle: 'Simple preferences for everyday conversions.',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  MergeSemantics(
                    child: Row(
                      children: [
                        const Expanded(child: Text('Dark appearance')),
                        Switch.adaptive(
                          key: const ValueKey('theme-switch'),
                          value: calc.dark,
                          onChanged: (_) => calc.toggleTheme(),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    'A soft glass theme for day or night',
                    style: TextStyle(color: p.secondary, fontSize: 12),
                  ),
                  const SizedBox(height: 20),
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 16,
                    children: [
                      const Text('Decimal places'),
                      DropdownButton<int>(
                        key: const ValueKey('precision-select'),
                        value: calc.precision,
                        items: [
                          for (var value = 2; value <= 12; value++)
                            DropdownMenuItem(
                              value: value,
                              child: Text('$value'),
                            ),
                        ],
                        onChanged: (value) {
                          if (value != null) calc.setPrecision(value);
                        },
                      ),
                    ],
                  ),
                  Text(
                    'Very small or large results use scientific notation.',
                    style: TextStyle(color: p.secondary, fontSize: 12),
                  ),
                  const SizedBox(height: 24),
                  GlassSurface(
                    palette: p,
                    radius: 20,
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _eyebrow('ABOUT LUMA CONVERT', p),
                        const SizedBox(height: 10),
                        Text(
                          'Fast, private and offline. Your conversions stay on this device. Star a category to move it to the front.',
                          style: TextStyle(color: p.secondary, height: 1.5),
                        ),
                      ],
                    ),
                  ),
                  if (!calc.storageAvailable) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Device storage is unavailable. Changes may not be saved.',
                      style: TextStyle(color: p.error),
                    ),
                  ],
                  const SizedBox(height: 24),
                  Text(
                    'luma. convert  1.0.2',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: p.secondary, fontSize: 12),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _sheetFrame(
    AppPalette p, {
    required String title,
    required String subtitle,
    required Widget child,
    Widget? action,
  }) => FractionallySizedBox(
    heightFactor: .88,
    child: ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      child: Material(
        color: p.background,
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            width: 38,
                            height: 4,
                            decoration: BoxDecoration(
                              color: p.secondary,
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ),
                      ),
                      if (action != null) action,
                      IconButton(
                        tooltip: 'Close',
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    title,
                    style: TextStyle(
                      color: p.text,
                      fontSize: 25,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    subtitle,
                    style: TextStyle(color: p.secondary, fontSize: 12),
                  ),
                  const SizedBox(height: 20),
                  child,
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
