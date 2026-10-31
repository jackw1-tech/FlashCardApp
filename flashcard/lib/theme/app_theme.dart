import 'package:flashcard/theme/app_colors.dart';
import 'package:flashcard/theme/app_text_styles.dart';
import 'package:flashcard/theme/color_palette.dart';
import 'package:flashcard/theme/dimensions.dart';
import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get lightTheme => _build(Brightness.light, AppColors.light);

  static ThemeData get darkTheme => _build(Brightness.dark, AppColors.dark);

  static ThemeData _build(Brightness brightness, AppColors colors) {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: ColorPalette.primary,
          brightness: brightness,
        ).copyWith(
          primary: colors.primary,
          onPrimary: colors.onPrimary,
          surface: colors.canvas,
          onSurface: colors.ink,
          onSurfaceVariant: colors.muted,
          surfaceContainerHighest: colors.card,
          outline: colors.hairline,
          outlineVariant: colors.hairline,
          error: ColorPalette.error,
        );
    final radiusMd = BorderRadius.circular(Dimensions.radiusMd);
    final hairline = BorderSide(color: colors.hairline);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      fontFamily: AppTextStyles.sans,
      scaffoldBackgroundColor: colors.canvas,
      extensions: [colors],
      textTheme: AppTextStyles.textTheme(
        ink: colors.ink,
        body: colors.body,
        muted: colors.muted,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: colors.canvas,
        foregroundColor: colors.ink,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: AppTextStyles.titleSm.copyWith(color: colors.ink),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: colors.primary,
          foregroundColor: colors.onPrimary,
          disabledBackgroundColor: ColorPalette.primaryDisabled,
          disabledForegroundColor: ColorPalette.muted,
          minimumSize: const Size.fromHeight(Dimensions.buttonHeight),
          textStyle: AppTextStyles.button,
          shape: RoundedRectangleBorder(borderRadius: radiusMd),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colors.ink,
          minimumSize: const Size.fromHeight(Dimensions.buttonHeight),
          textStyle: AppTextStyles.button,
          side: hairline,
          shape: RoundedRectangleBorder(borderRadius: radiusMd),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colors.ink,
          textStyle: AppTextStyles.button,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(foregroundColor: colors.ink),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colors.ink,
        linearTrackColor: colors.hairline,
        circularTrackColor: colors.hairline,
      ),
      dividerTheme: DividerThemeData(
        color: colors.hairline,
        thickness: 1,
        space: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.canvas,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: radiusMd,
          borderSide: hairline,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: radiusMd,
          borderSide: hairline,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: radiusMd,
          borderSide: BorderSide(color: colors.primary, width: 1.5),
        ),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: colors.primary,
        selectionColor: colors.primary.withValues(alpha: 0.25),
        selectionHandleColor: colors.primary,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colors.canvas,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: AppTextStyles.displaySm.copyWith(
          color: colors.ink,
          fontSize: 26,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Dimensions.radiusXl),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        constraints: const BoxConstraints(maxWidth: Dimensions.sheetMaxWidth),
        backgroundColor: colors.canvas,
        surfaceTintColor: Colors.transparent,
        dragHandleColor: colors.hairline,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(Dimensions.radiusXl),
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: ColorPalette.surfaceDark,
        contentTextStyle: AppTextStyles.bodySm.copyWith(
          color: ColorPalette.onDark,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Dimensions.radiusLg),
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: colors.ink,
        textColor: colors.ink,
        minTileHeight: 56,
      ),
      cardTheme: CardThemeData(
        color: colors.card,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: radiusMd),
      ),
      visualDensity: VisualDensity.standard,
      materialTapTargetSize: MaterialTapTargetSize.padded,
    );
  }
}
