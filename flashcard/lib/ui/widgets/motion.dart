import 'package:flashcard/theme/dimensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

extension MotionContext on BuildContext {
  Duration motionDuration([
    int milliseconds = Dimensions.entranceAnimationMs,
  ]) => MediaQuery.disableAnimationsOf(this)
      ? Duration.zero
      : Duration(milliseconds: milliseconds);
}

class FadeSlideIn extends StatefulWidget {
  final Widget child;
  final double offset;

  const FadeSlideIn({required this.child, this.offset = 12, super.key});

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn> {
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _visible = true);
    });
  }

  @override
  Widget build(BuildContext context) => AnimatedOpacity(
    opacity: _visible ? 1 : 0,
    duration: context.motionDuration(),
    curve: Curves.easeOutCubic,
    child: AnimatedSlide(
      offset: _visible ? Offset.zero : Offset(0, widget.offset / 100),
      duration: context.motionDuration(),
      curve: Curves.easeOutCubic,
      child: widget.child,
    ),
  );
}

class Pressable extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final BorderRadius borderRadius;
  final String? semanticLabel;
  final bool haptic;

  const Pressable({
    required this.child,
    required this.onTap,
    required this.borderRadius,
    this.onLongPress,
    this.semanticLabel,
    this.haptic = true,
    super.key,
  });

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _pressed = false;

  void _tap() {
    if (widget.haptic) HapticFeedback.selectionClick();
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: widget.semanticLabel,
    child: AnimatedScale(
      scale: _pressed ? 0.985 : 1,
      duration: context.motionDuration(Dimensions.microAnimationMs),
      curve: Curves.easeOut,
      child: InkWell(
        borderRadius: widget.borderRadius,
        onHighlightChanged: (value) => setState(() => _pressed = value),
        onTap: _tap,
        onLongPress: widget.onLongPress,
        child: widget.child,
      ),
    ),
  );
}
