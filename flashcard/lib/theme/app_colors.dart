import 'package:flashcard/theme/color_palette.dart';
import 'package:flutter/material.dart';

@immutable
class AppColors extends ThemeExtension<AppColors> {
  final Color canvas;

  final Color card;

  final Color flashcard;
  final Color hairline;
  final Color ink;
  final Color body;
  final Color muted;
  final Color primary;
  final Color onPrimary;

  final Color code;
  final Color onCode;
  final Color knew;
  final Color didntKnow;

  const AppColors({
    required this.canvas,
    required this.card,
    required this.flashcard,
    required this.hairline,
    required this.ink,
    required this.body,
    required this.muted,
    required this.primary,
    required this.onPrimary,
    required this.code,
    required this.onCode,
    required this.knew,
    required this.didntKnow,
  });

  static const light = AppColors(
    canvas: ColorPalette.canvas,
    card: ColorPalette.surfaceCard,
    flashcard: ColorPalette.canvas,
    hairline: ColorPalette.hairline,
    ink: ColorPalette.ink,
    body: ColorPalette.body,
    muted: ColorPalette.muted,
    primary: ColorPalette.primary,
    onPrimary: ColorPalette.onPrimary,
    code: ColorPalette.surfaceDark,
    onCode: ColorPalette.onDark,
    knew: ColorPalette.success,
    didntKnow: ColorPalette.error,
  );

  static const dark = AppColors(
    canvas: ColorPalette.surfaceDark,
    card: ColorPalette.surfaceDarkElevated,
    flashcard: ColorPalette.surfaceDarkElevated,
    hairline: ColorPalette.hairlineDark,
    ink: ColorPalette.onDark,
    body: ColorPalette.onDark,
    muted: ColorPalette.onDarkSoft,
    primary: ColorPalette.primary,
    onPrimary: ColorPalette.onPrimary,
    code: ColorPalette.surfaceDarkSoft,
    onCode: ColorPalette.onDark,
    knew: ColorPalette.success,
    didntKnow: ColorPalette.error,
  );

  @override
  AppColors copyWith() => this;

  @override
  AppColors lerp(AppColors? other, double t) {
    if (other == null) return this;
    Color mix(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppColors(
      canvas: mix(canvas, other.canvas),
      card: mix(card, other.card),
      flashcard: mix(flashcard, other.flashcard),
      hairline: mix(hairline, other.hairline),
      ink: mix(ink, other.ink),
      body: mix(body, other.body),
      muted: mix(muted, other.muted),
      primary: mix(primary, other.primary),
      onPrimary: mix(onPrimary, other.onPrimary),
      code: mix(code, other.code),
      onCode: mix(onCode, other.onCode),
      knew: mix(knew, other.knew),
      didntKnow: mix(didntKnow, other.didntKnow),
    );
  }
}

extension AppColorsContext on BuildContext {
  AppColors get colors =>
      Theme.of(this).extension<AppColors>() ?? AppColors.light;
}
