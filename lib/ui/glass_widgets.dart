import 'dart:ui';

import 'package:flutter/material.dart';

import 'palette.dart';

class GlassSurface extends StatelessWidget {
  const GlassSurface({
    super.key,
    required this.palette,
    required this.child,
    this.padding = EdgeInsets.zero,
    this.radius = 24,
    this.blur = false,
  });

  final AppPalette palette;
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final bool blur;

  @override
  Widget build(BuildContext context) {
    final content = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: palette.line),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            palette.surface.withValues(alpha: .9),
            palette.surfaceRaised.withValues(alpha: palette.dark ? .72 : .78),
          ],
        ),
      ),
      child: Padding(padding: padding, child: child),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: blur
          ? BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: content,
            )
          : content,
    );
  }
}

class RoundIconButton extends StatelessWidget {
  const RoundIconButton({
    super.key,
    required this.icon,
    required this.label,
    required this.palette,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final AppPalette palette;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: label,
    onPressed: onPressed,
    style: IconButton.styleFrom(
      minimumSize: const Size(48, 48),
      foregroundColor: palette.secondary,
      backgroundColor: palette.surface.withValues(alpha: .7),
      side: BorderSide(color: palette.line),
    ),
    icon: Icon(icon, size: 21),
  );
}

class CategoryChip extends StatelessWidget {
  const CategoryChip({
    super.key,
    required this.label,
    required this.icon,
    required this.selected,
    this.favorite = false,
    required this.palette,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final bool favorite;
  final AppPalette palette;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    label: label,
    onTap: onPressed,
    child: ExcludeSemantics(
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: selected
                ? palette.operator
                : palette.surface.withValues(alpha: .58),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected
                  ? palette.accent.withValues(alpha: .55)
                  : palette.line,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color: selected ? palette.accent : palette.secondary,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: selected ? palette.text : palette.secondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (favorite) ...[
                const SizedBox(width: 6),
                Icon(Icons.star_rounded, size: 14, color: palette.accent),
              ],
            ],
          ),
        ),
      ),
    ),
  );
}
