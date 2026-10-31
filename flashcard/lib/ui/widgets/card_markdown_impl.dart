import 'package:flashcard/theme/app_colors.dart';
import 'package:flashcard/theme/app_text_styles.dart';
import 'package:flashcard/theme/dimensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:markdown/markdown.dart' as md;

class CardMarkdownImpl extends StatelessWidget {
  final String data;
  final TextStyle? style;

  final bool centered;

  const CardMarkdownImpl(
    this.data, {
    this.style,
    this.centered = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.colors;
    final base = style ?? theme.textTheme.bodyLarge;
    return MarkdownBody(
      data: data,
      selectable: true,
      softLineBreak: true,
      extensionSet: md.ExtensionSet(
        md.ExtensionSet.gitHubFlavored.blockSyntaxes,
        [_LatexSyntax(), ...md.ExtensionSet.gitHubFlavored.inlineSyntaxes],
      ),
      builders: {'latex': _LatexBuilder(), 'pre': _CodeBlockBuilder(colors)},
      styleSheet: MarkdownStyleSheet.fromTheme(theme).copyWith(
        p: base,
        strong: base?.copyWith(fontWeight: FontWeight.w700),
        textAlign: centered ? WrapAlignment.center : WrapAlignment.start,
        code: AppTextStyles.code.copyWith(
          fontSize: 14,
          color: colors.ink,
          backgroundColor: colors.card,
        ),
      ),
    );
  }
}

class _LatexSyntax extends md.InlineSyntax {
  _LatexSyntax() : super(r'\$\$([^$]+)\$\$|\$([^$\n]+)\$');

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    final display = match[1] != null;
    parser.addNode(
      md.Element.text('latex', (match[1] ?? match[2])!)
        ..attributes['display'] = '$display',
    );
    return true;
  }
}

class _LatexBuilder extends MarkdownElementBuilder {
  @override
  Widget? visitElementAfterWithContext(
    BuildContext context,
    md.Element element,
    TextStyle? preferredStyle,
    TextStyle? parentStyle,
  ) {
    final display = element.attributes['display'] == 'true';
    final tex = element.textContent;
    final math = Math.tex(
      tex,
      mathStyle: display ? MathStyle.display : MathStyle.text,
      textStyle: parentStyle,
      onErrorFallback: (_) => Text('\$$tex\$', style: parentStyle),
    );
    return display
        ? Center(child: math)
        : Text.rich(
            WidgetSpan(alignment: PlaceholderAlignment.middle, child: math),
          );
  }
}

class _CodeBlockBuilder extends MarkdownElementBuilder {
  final AppColors colors;

  _CodeBlockBuilder(this.colors);

  @override
  bool isBlockElement() => true;

  @override
  Widget? visitElementAfterWithContext(
    BuildContext context,
    md.Element element,
    TextStyle? preferredStyle,
    TextStyle? parentStyle,
  ) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(Dimensions.paddingMedium),
    decoration: BoxDecoration(
      color: colors.code,
      borderRadius: BorderRadius.circular(Dimensions.radiusLg),
    ),
    child: SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Text(
        element.textContent.trimRight(),
        style: AppTextStyles.code.copyWith(color: colors.onCode),
      ),
    ),
  );
}
