import 'package:flashcard/theme/dimensions.dart';
import 'package:flutter/material.dart';

class ContentWidth extends StatelessWidget {
  final double maxWidth;
  final Widget child;

  const ContentWidth({
    required this.child,
    this.maxWidth = Dimensions.readingMaxWidth,
    super.key,
  });

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.topCenter,
    child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: child,
    ),
  );
}

extension ScreenSize on BuildContext {
  bool get isWide => MediaQuery.sizeOf(this).width >= Dimensions.wideBreakpoint;
}
