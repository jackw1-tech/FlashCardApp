import 'dart:math' as math;

import 'package:flashcard/model/entities/review_outcome.dart';
import 'package:flashcard/theme/app_colors.dart';
import 'package:flashcard/theme/app_text_styles.dart';
import 'package:flashcard/theme/dimensions.dart';
import 'package:flashcard/ui/widgets/card_markdown.dart';
import 'package:flashcard/ui/widgets/outcome_dots.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class FlashcardController {
  _FlashcardViewState? _attached;

  void flip() => _attached?._toggle();

  bool answer(ReviewOutcome outcome) => _attached?._answer(outcome) ?? false;
}

class FlashcardView extends StatefulWidget {
  final String front;
  final String back;
  final String caption;

  final List<ReviewOutcome> recentOutcomes;

  final double textScale;

  final bool keyboardHints;

  final FlashcardController? controller;

  final bool revealed;

  final bool interactive;
  final VoidCallback onReveal;
  final ValueChanged<ReviewOutcome> onSwipe;

  const FlashcardView({
    required this.front,
    required this.back,
    required this.caption,
    this.recentOutcomes = const [],
    this.textScale = 1.0,
    this.keyboardHints = false,
    this.controller,
    required this.revealed,
    required this.interactive,
    required this.onReveal,
    required this.onSwipe,
    super.key,
  });

  @override
  State<FlashcardView> createState() => _FlashcardViewState();
}

class _FlashcardViewState extends State<FlashcardView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _flip = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: Dimensions.flipDurationMs),
  );
  double _dragX = 0;
  bool _dragging = false;

  bool _pastThreshold = false;

  double _width = 0;

  bool get _canSwipe => widget.revealed && widget.interactive;

  @override
  void didUpdateWidget(FlashcardView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.interactive && !oldWidget.interactive) {
      setState(() => _dragX = 0);
    }
  }

  @override
  void dispose() {
    if (widget.controller?._attached == this) {
      widget.controller!._attached = null;
    }
    _flip.dispose();
    super.dispose();
  }

  void _toggle() {
    if (!widget.interactive) return;
    if (!widget.revealed) widget.onReveal();
    HapticFeedback.lightImpact();
    _flip.isForwardOrCompleted ? _flip.reverse() : _flip.forward();
  }

  @override
  void initState() {
    super.initState();
    widget.controller?._attached = this;
  }

  bool _answer(ReviewOutcome outcome) {
    if (!_canSwipe) return false;
    setState(() {
      _dragging = false;
      _dragX = (outcome == ReviewOutcome.knew ? 1 : -1) * _width * 1.4;
    });
    widget.onSwipe(outcome);
    return true;
  }

  void _onDragUpdate(double delta, double width) {
    setState(() => _dragX += delta);
    final past = _dragX.abs() >= width * Dimensions.swipeThreshold;
    if (past != _pastThreshold) {
      _pastThreshold = past;
      if (past) HapticFeedback.mediumImpact();
    }
  }

  void _onDragEnd(double width) {
    _pastThreshold = false;
    final threshold = width * Dimensions.swipeThreshold;
    setState(() {
      _dragging = false;
      if (_dragX.abs() < threshold) {
        _dragX = 0;
        return;
      }
      final outcome = _dragX > 0 ? ReviewOutcome.knew : ReviewOutcome.didntKnow;
      _dragX = _dragX.sign * width * 1.4;
      widget.onSwipe(outcome);
    });
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final width = _width = constraints.maxWidth;
      final progress = (_dragX / (width * Dimensions.swipeThreshold)).clamp(
        -1.0,
        1.0,
      );
      return Semantics(
        button: true,
        label: widget.revealed
            ? 'Flashcard, risposta mostrata'
            : 'Flashcard, tocca per mostrare la risposta',
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: _toggle,
            onHorizontalDragStart: _canSwipe
                ? (_) => setState(() => _dragging = true)
                : null,
            onHorizontalDragUpdate: _canSwipe
                ? (details) => _onDragUpdate(details.delta.dx, width)
                : null,
            onHorizontalDragEnd: _canSwipe ? (_) => _onDragEnd(width) : null,
            child: AnimatedContainer(
              duration: _dragging
                  ? Duration.zero
                  : const Duration(milliseconds: Dimensions.swipeDurationMs),
              curve: Curves.easeOut,
              transformAlignment: Alignment.bottomCenter,
              transform: Matrix4.translationValues(_dragX, 0, 0)
                ..rotateZ(_dragX / width * 0.25),
              child: AnimatedBuilder(
                animation: _flip,
                builder: (context, _) {
                  final angle = _flip.value * math.pi;
                  final showBack = angle > math.pi / 2;
                  final face = showBack
                      ? Transform(
                          alignment: Alignment.center,
                          transform: Matrix4.rotationY(math.pi),
                          child: _face(
                            context,
                            back: true,
                            swipeProgress: progress,
                          ),
                        )
                      : _face(context, back: false, swipeProgress: progress);
                  return Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.0012)
                      ..rotateY(angle),
                    child: face,
                  );
                },
              ),
            ),
          ),
        ),
      );
    },
  );

  Widget _face(
    BuildContext context, {
    required bool back,
    required double swipeProgress,
  }) {
    final colors = context.colors;
    final swipeColor = swipeProgress > 0 ? colors.knew : colors.didntKnow;
    final borderColor = Color.lerp(
      colors.hairline,
      swipeColor,
      swipeProgress.abs(),
    )!;

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: colors.flashcard,
        borderRadius: BorderRadius.circular(Dimensions.radiusXl),
        border: Border.all(
          color: borderColor,
          width: swipeProgress == 0 ? 1 : 2,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14141413),
            blurRadius: 3,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(Dimensions.paddingLarge),
            child: Column(
              children: [
                Row(
                  children: [
                    Text(
                      back ? 'RISPOSTA' : 'DOMANDA',
                      style: AppTextStyles.captionUppercase.copyWith(
                        color: back ? colors.primary : colors.muted,
                      ),
                    ),
                    OutcomeDots(widget.recentOutcomes),
                    const SizedBox(width: Dimensions.paddingSmall),
                    Expanded(
                      child: Text(
                        widget.caption,
                        textAlign: TextAlign.end,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.caption.copyWith(
                          color: colors.muted,
                        ),
                      ),
                    ),
                  ],
                ),
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        vertical: Dimensions.paddingMedium,
                      ),
                      child: CardMarkdown(
                        back ? widget.back : widget.front,
                        centered: true,
                        style: back
                            ? AppTextStyles.bodyMd.copyWith(
                                fontSize: 18 * widget.textScale,
                                color: colors.body,
                              )
                            : AppTextStyles.flashcard.copyWith(
                                fontSize:
                                    AppTextStyles.flashcard.fontSize! *
                                    widget.textScale,
                                color: colors.ink,
                              ),
                      ),
                    ),
                  ),
                ),
                AnimatedSwitcher(
                  duration: const Duration(
                    milliseconds: Dimensions.microAnimationMs,
                  ),
                  child: Row(
                    key: ValueKey(back),
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        back ? Icons.swipe_rounded : Icons.touch_app_outlined,
                        size: 17,
                        color: colors.muted,
                      ),
                      const SizedBox(width: Dimensions.spaceXxs),
                      Flexible(
                        child: Text(
                          switch ((back, widget.keyboardHints)) {
                            (true, false) =>
                              'Destra se sapevi · sinistra se no',
                            (true, true) => 'Trascina la card o usa ← →',
                            (false, false) => 'Tocca per girare',
                            (false, true) => 'Tocca o premi Spazio per girare',
                          },
                          textAlign: TextAlign.center,
                          style: AppTextStyles.caption.copyWith(
                            color: colors.muted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (swipeProgress != 0) _stamp(swipeProgress, swipeColor),
        ],
      ),
    );
  }

  Widget _stamp(double progress, Color color) => Positioned(
    top: Dimensions.paddingLarge * 2,
    left: progress > 0 ? Dimensions.paddingLarge : null,
    right: progress < 0 ? Dimensions.paddingLarge : null,
    child: Opacity(
      opacity: progress.abs(),
      child: Transform.rotate(
        angle: progress > 0 ? -0.15 : 0.15,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: Dimensions.spaceSm,
            vertical: Dimensions.spaceXxs,
          ),
          decoration: BoxDecoration(
            border: Border.all(color: color, width: 2),
            borderRadius: BorderRadius.circular(Dimensions.radiusMd),
          ),
          child: Text(
            progress > 0 ? 'SAPEVO' : 'NON SAPEVO',
            style: AppTextStyles.captionUppercase.copyWith(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    ),
  );
}
