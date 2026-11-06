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
  late final Animation<double> _flipProgress = CurvedAnimation(
    parent: _flip,
    curve: Curves.easeInOutCubic,
  );
  final ValueNotifier<double> _dragX = ValueNotifier(0);
  bool _dragging = false;

  bool _pastThreshold = false;

  double _width = 0;

  bool get _canSwipe => widget.revealed && widget.interactive;

  @override
  void didUpdateWidget(FlashcardView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.interactive && !oldWidget.interactive) {
      _dragX.value = 0;
    }
  }

  @override
  void dispose() {
    if (widget.controller?._attached == this) {
      widget.controller!._attached = null;
    }
    _dragX.dispose();
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
    setState(() => _dragging = false);
    _dragX.value = (outcome == ReviewOutcome.knew ? 1 : -1) * _width * 1.4;
    widget.onSwipe(outcome);
    return true;
  }

  void _onDragUpdate(double delta, double width) {
    _dragX.value += delta;
    final past = _dragX.value.abs() >= width * Dimensions.swipeThreshold;
    if (past != _pastThreshold) {
      _pastThreshold = past;
      if (past) HapticFeedback.mediumImpact();
    }
  }

  void _onDragEnd(double width) {
    _pastThreshold = false;
    final threshold = width * Dimensions.swipeThreshold;
    setState(() => _dragging = false);
    if (_dragX.value.abs() < threshold) {
      _dragX.value = 0;
      return;
    }
    final outcome = _dragX.value > 0
        ? ReviewOutcome.knew
        : ReviewOutcome.didntKnow;
    _dragX.value = _dragX.value.sign * width * 1.4;
    widget.onSwipe(outcome);
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final width = _width = constraints.maxWidth;
      final faces = <Widget>[
        RepaintBoundary(child: _face(context, back: false)),
        Transform(
          alignment: Alignment.center,
          transform: Matrix4.rotationY(math.pi),
          child: RepaintBoundary(child: _face(context, back: true)),
        ),
      ];
      final flipCard = AnimatedBuilder(
        animation: _flipProgress,
        builder: (context, _) {
          final angle = _flipProgress.value * math.pi;
          final showBack = angle > math.pi / 2;
          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.0012)
              ..rotateY(angle),
            child: IndexedStack(
              index: showBack ? 1 : 0,
              sizing: StackFit.expand,
              children: faces,
            ),
          );
        },
      );
      return ValueListenableBuilder<double>(
        valueListenable: _dragX,
        child: flipCard,
        builder: (context, dragX, flipCard) {
          final progress = (dragX / (width * Dimensions.swipeThreshold)).clamp(
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
                onHorizontalDragEnd: _canSwipe
                    ? (_) => _onDragEnd(width)
                    : null,
                child: AnimatedContainer(
                  duration: _dragging
                      ? Duration.zero
                      : const Duration(
                          milliseconds: Dimensions.swipeDurationMs,
                        ),
                  curve: Curves.easeOutCubic,
                  transformAlignment: Alignment.bottomCenter,
                  transform: Matrix4.translationValues(dragX, 0, 0)
                    ..rotateZ(dragX / width * 0.25),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      flipCard!,
                      if (progress != 0) _swipeFeedback(progress),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );
    },
  );

  Widget _face(BuildContext context, {required bool back}) {
    final colors = context.colors;

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: colors.flashcard,
        borderRadius: BorderRadius.circular(Dimensions.radiusXl),
        border: Border.all(color: colors.hairline),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14141413),
            blurRadius: 3,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Padding(
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
                    style: AppTextStyles.caption.copyWith(color: colors.muted),
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
                        (true, false) => 'Destra se sapevi · sinistra se no',
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
    );
  }

  Widget _swipeFeedback(double progress) {
    final colors = context.colors;
    final color = progress > 0 ? colors.knew : colors.didntKnow;
    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(Dimensions.radiusXl),
              border: Border.all(
                color: color.withValues(alpha: progress.abs()),
                width: 2,
              ),
            ),
          ),
          _stamp(progress, color),
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
