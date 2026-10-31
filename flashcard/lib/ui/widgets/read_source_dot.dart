import 'package:flashcard/model/entities/db_node.dart';
import 'package:flashcard/state_management/cubits/read_source_cubit/read_source_cubit.dart';
import 'package:flashcard/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ReadSourceOverlay extends StatelessWidget {
  final Widget child;

  const ReadSourceOverlay({required this.child, super.key});

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.paddingOf(context);
    return Stack(
      children: [
        child,
        Positioned(
          bottom: padding.bottom + 4,
          left: padding.left + 4,
          child: const IgnorePointer(child: ReadSourceDot()),
        ),
      ],
    );
  }
}

class ReadSourceDot extends StatefulWidget {
  const ReadSourceDot({super.key});

  @override
  State<ReadSourceDot> createState() => _ReadSourceDotState();
}

class _ReadSourceDotState extends State<ReadSourceDot>
    with SingleTickerProviderStateMixin {
  static const double _size = 22;

  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 650),
  );

  late final Animation<double> _scale = TweenSequence<double>([
    TweenSequenceItem(
      tween: Tween<double>(
        begin: 1,
        end: 1.45,
      ).chain(CurveTween(curve: Curves.easeOut)),
      weight: 35,
    ),
    TweenSequenceItem(
      tween: Tween<double>(
        begin: 1.45,
        end: 1,
      ).chain(CurveTween(curve: Curves.elasticOut)),
      weight: 65,
    ),
  ]).animate(_pulse);

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  Color _color(BuildContext context, DbNode? node) => switch (node) {
    DbNode.primary => context.colors.primary,
    DbNode.replica => context.colors.knew,
    null => context.colors.muted,
  };

  Color _onColor(BuildContext context, DbNode? node) => switch (node) {
    DbNode.primary => context.colors.onPrimary,
    _ => Colors.white,
  };

  String _label(DbNode? node) => switch (node) {
    DbNode.primary => 'P',
    DbNode.replica => 'R',
    null => '·',
  };

  @override
  Widget build(BuildContext context) =>
      BlocConsumer<ReadSourceCubit, ReadSourceState>(
        listener: (_, _) => _pulse.forward(from: 0),
        builder: (context, state) {
          final color = _color(context, state.node);
          return Semantics(
            label: switch (state.node) {
              DbNode.primary => 'Ultima risposta dal database primary',
              DbNode.replica => 'Ultima risposta dalla replica',
              null => 'Nessuna risposta dal backend',
            },
            child: Material(
              type: MaterialType.transparency,
              child: SizedBox.square(
                dimension: _size * 2,
                child: AnimatedBuilder(
                  animation: _pulse,
                  builder: (context, _) => Stack(
                    alignment: Alignment.center,
                    children: [
                      if (_pulse.isAnimating)
                        Container(
                          width: _size * (1 + _pulse.value),
                          height: _size * (1 + _pulse.value),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: color.withValues(alpha: 1 - _pulse.value),
                              width: 2,
                            ),
                          ),
                        ),
                      Transform.scale(
                        scale: _scale.value,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          width: _size,
                          height: _size,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: color.withValues(alpha: 0.45),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 250),
                            transitionBuilder: (child, animation) =>
                                RotationTransition(
                                  turns: Tween(
                                    begin: 0.5,
                                    end: 1.0,
                                  ).animate(animation),
                                  child: FadeTransition(
                                    opacity: animation,
                                    child: child,
                                  ),
                                ),
                            child: Text(
                              _label(state.node),
                              key: ValueKey(state.node),
                              style: TextStyle(
                                color: _onColor(context, state.node),
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                height: 1,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );
}
