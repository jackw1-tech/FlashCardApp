import 'package:flashcard/theme/app_colors.dart';
import 'package:flashcard/theme/dimensions.dart';
import 'package:flutter/material.dart';

class LoadingSkeleton extends StatefulWidget {
  final int rows;

  const LoadingSkeleton({this.rows = 4, super.key});

  @override
  State<LoadingSkeleton> createState() => _LoadingSkeletonState();
}

class _LoadingSkeletonState extends State<LoadingSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _pulse.stop();
      _pulse.value = 0.5;
    } else if (!_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: AnimatedBuilder(
      animation: _pulse,
      builder: (context, _) {
        final color = Color.lerp(
          context.colors.hairline.withValues(alpha: 0.55),
          context.colors.card,
          _pulse.value,
        )!;
        return ListView.separated(
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.all(Dimensions.paddingMedium),
          itemCount: widget.rows,
          separatorBuilder: (_, _) =>
              const SizedBox(height: Dimensions.spaceSm),
          itemBuilder: (_, index) => Container(
            height: index == 0 ? 104 : 86,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(Dimensions.radiusLg),
            ),
          ),
        );
      },
    ),
  );
}
