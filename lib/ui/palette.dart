import 'package:flutter/material.dart';

class AppPalette {
  const AppPalette(this.dark);

  final bool dark;

  Color get background =>
      dark ? const Color(0xFF0E101D) : const Color(0xFFF2F0FB);
  Color get surface => dark ? const Color(0xFF242538) : const Color(0xFFFFFFFF);
  Color get surfaceRaised =>
      dark ? const Color(0xFF303148) : const Color(0xFFF8F6FF);
  Color get line => dark ? const Color(0x335A5D78) : const Color(0x22565A82);
  Color get text => dark ? const Color(0xFFF5F1FF) : const Color(0xFF28233B);
  Color get secondary =>
      dark ? const Color(0xFFA8A6BC) : const Color(0xFF716D83);
  Color get accent => dark ? const Color(0xFFC7A5FF) : const Color(0xFF7352BF);
  Color get accentStrong => const Color(0xFFAD8BEF);
  Color get mint => dark ? const Color(0xFF91E1D0) : const Color(0xFF278D7C);
  Color get operator =>
      dark ? const Color(0xFF403558) : const Color(0xFFE5DDF7);
  Color get error => dark ? const Color(0xFFFF9FAC) : const Color(0xFFB4284A);
}
