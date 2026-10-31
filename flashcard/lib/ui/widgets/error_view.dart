import 'package:flashcard/theme/app_colors.dart';
import 'package:flashcard/theme/app_text_styles.dart';
import 'package:flashcard/theme/dimensions.dart';
import 'package:flutter/material.dart';

class ErrorView extends StatelessWidget {
  final String message;
  final String retryLabel;
  final VoidCallback onRetry;

  const ErrorView({
    required this.message,
    required this.onRetry,
    this.retryLabel = 'Riprova',
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Dimensions.spaceXl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded, size: 40, color: colors.muted),
            const SizedBox(height: Dimensions.paddingMedium),
            Text(
              'Qualcosa non va',
              style: AppTextStyles.displaySm.copyWith(color: colors.ink),
            ),
            const SizedBox(height: Dimensions.paddingSmall),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMd.copyWith(color: colors.body),
            ),
            const SizedBox(height: Dimensions.paddingLarge),
            FilledButton(onPressed: onRetry, child: Text(retryLabel)),
          ],
        ),
      ),
    );
  }
}
