import 'package:flutter/material.dart';

class AppTextStyles {
  static const String serif = 'CormorantGaramond';
  static const String sans = 'Inter';
  static const String mono = 'JetBrainsMono';

  static const TextStyle displayMd = TextStyle(
    fontFamily: serif,
    fontSize: 38,
    fontWeight: FontWeight.w500,
    height: 1.1,
    letterSpacing: -0.8,
  );

  static const TextStyle displaySm = TextStyle(
    fontFamily: serif,
    fontSize: 30,
    fontWeight: FontWeight.w500,
    height: 1.15,
    letterSpacing: -0.5,
  );

  static const TextStyle flashcard = TextStyle(
    fontFamily: serif,
    fontSize: 30,
    fontWeight: FontWeight.w500,
    height: 1.2,
    letterSpacing: -0.4,
  );

  static const TextStyle titleLg = TextStyle(
    fontFamily: sans,
    fontSize: 22,
    fontWeight: FontWeight.w500,
    height: 1.3,
  );

  static const TextStyle titleMd = TextStyle(
    fontFamily: sans,
    fontSize: 18,
    fontWeight: FontWeight.w500,
    height: 1.4,
  );

  static const TextStyle titleSm = TextStyle(
    fontFamily: sans,
    fontSize: 16,
    fontWeight: FontWeight.w500,
    height: 1.4,
  );

  static const TextStyle bodyMd = TextStyle(
    fontFamily: sans,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.55,
  );

  static const TextStyle bodySm = TextStyle(
    fontFamily: sans,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.55,
  );

  static const TextStyle caption = TextStyle(
    fontFamily: sans,
    fontSize: 13,
    fontWeight: FontWeight.w500,
    height: 1.4,
  );

  static const TextStyle captionUppercase = TextStyle(
    fontFamily: sans,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.4,
    letterSpacing: 1.5,
  );

  static const TextStyle code = TextStyle(
    fontFamily: mono,
    fontSize: 14,
    height: 1.6,
  );

  static const TextStyle button = TextStyle(
    fontFamily: sans,
    fontSize: 15,
    fontWeight: FontWeight.w500,
  );

  static TextTheme textTheme({
    required Color ink,
    required Color body,
    required Color muted,
  }) => TextTheme(
    displaySmall: displayMd.copyWith(color: ink),
    headlineMedium: displaySm.copyWith(color: ink),
    headlineSmall: titleLg.copyWith(color: ink),
    titleLarge: titleLg.copyWith(color: ink),
    titleMedium: titleMd.copyWith(color: ink),
    titleSmall: titleSm.copyWith(color: ink),
    bodyLarge: bodyMd.copyWith(color: body),
    bodyMedium: bodySm.copyWith(color: body),
    bodySmall: caption.copyWith(color: muted),
    labelLarge: button,
    labelSmall: captionUppercase.copyWith(color: muted),
  );
}
