import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Builds the app's Material 3 theme with Sora font and amber/gold color scheme.
/// Per user decision: light + clean aesthetic, white/light gray backgrounds, modern feel.
/// Amber/gold accent ties to the "vault" concept.
ThemeData buildAppTheme() {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFFFFC107), // amber[500]
      brightness: Brightness.light,
    ),
  );

  return base.copyWith(
    textTheme: GoogleFonts.soraTextTheme(base.textTheme),
    scaffoldBackgroundColor: Colors.white,
  );
}
