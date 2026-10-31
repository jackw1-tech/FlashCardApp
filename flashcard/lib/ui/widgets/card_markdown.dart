import 'dart:convert';

import 'package:flashcard/ui/widgets/card_markdown_impl.dart' deferred as impl;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

Future<void>? _loading;
bool _loaded = false;

Future<void> preloadCardMarkdown() => _loading ??= Future.wait([
  impl.loadLibrary(),
  loadDeferredFonts(rootBundle),
]).then((_) => _loaded = true);

@visibleForTesting
Future<void> loadDeferredFonts(AssetBundle bundle) async {
  if (!kIsWeb || !kReleaseMode) return;
  final String manifest;
  try {
    manifest = await bundle.loadString('FontManifest.deferred.json');
  } on FlutterError {
    return;
  }
  await Future.wait([
    for (final family in jsonDecode(manifest) as List<dynamic>)
      (FontLoader(family['family'] as String)..addFonts([
            for (final font in family['fonts'] as List<dynamic>)
              bundle.load(font['asset'] as String),
          ]))
          .load(),
  ]);
}

extension on FontLoader {
  void addFonts(List<Future<ByteData>> fonts) => fonts.forEach(addFont);
}

class CardMarkdown extends StatelessWidget {
  final String data;
  final TextStyle? style;

  final bool centered;

  const CardMarkdown(this.data, {this.style, this.centered = false, super.key});

  @override
  Widget build(BuildContext context) {
    if (_loaded) {
      return impl.CardMarkdownImpl(data, style: style, centered: centered);
    }
    return FutureBuilder<void>(
      future: preloadCardMarkdown(),
      builder: (context, snapshot) =>
          snapshot.connectionState == ConnectionState.done
          ? impl.CardMarkdownImpl(data, style: style, centered: centered)
          : const SizedBox.shrink(),
    );
  }
}
