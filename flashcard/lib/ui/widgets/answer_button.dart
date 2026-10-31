import 'package:flashcard/theme/app_text_styles.dart';
import 'package:flashcard/theme/dimensions.dart';
import 'package:flashcard/ui/widgets/motion.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AnswerButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onPressed;

  const AnswerButton({
    required this.icon,
    required this.label,
    required this.color,
    this.onPressed,
    super.key,
  });

  @override
  State<AnswerButton> createState() => _AnswerButtonState();
}

class _AnswerButtonState extends State<AnswerButton> {
  bool _pressed = false;

  void _answer() {
    HapticFeedback.mediumImpact();
    widget.onPressed?.call();
  }

  @override
  Widget build(BuildContext context) {
    final effective = widget.onPressed != null
        ? widget.color
        : widget.color.withValues(alpha: 0.4);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Listener(
          onPointerDown: widget.onPressed == null
              ? null
              : (_) => setState(() => _pressed = true),
          onPointerUp: widget.onPressed == null
              ? null
              : (_) => setState(() => _pressed = false),
          onPointerCancel: widget.onPressed == null
              ? null
              : (_) => setState(() => _pressed = false),
          child: AnimatedScale(
            scale: _pressed ? 0.9 : 1,
            duration: context.motionDuration(Dimensions.microAnimationMs),
            child: SizedBox.square(
              dimension: Dimensions.answerButtonSize,
              child: OutlinedButton(
                onPressed: widget.onPressed == null ? null : _answer,
                style: OutlinedButton.styleFrom(
                  minimumSize: Size.zero,
                  padding: EdgeInsets.zero,
                  shape: const CircleBorder(),
                  side: BorderSide(color: effective, width: 1.5),
                  foregroundColor: effective,
                  backgroundColor: effective.withValues(alpha: 0.1),
                ),
                child: Icon(widget.icon, size: 28),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          widget.label,
          style: AppTextStyles.caption.copyWith(color: effective),
        ),
      ],
    );
  }
}
