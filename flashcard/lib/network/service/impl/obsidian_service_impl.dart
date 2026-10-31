import 'package:flashcard/network/service/obsidian_service.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class ObsidianServiceImpl implements ObsidianService {
  static Uri noteUri(String vault, String noteTitle) => Uri.parse(
    'obsidian://open'
    '?vault=${Uri.encodeComponent(vault)}'
    '&file=${Uri.encodeComponent('Flashcard -> $noteTitle')}',
  );

  @override
  Future<bool> openNote({
    required String vault,
    required String noteTitle,
  }) async {
    try {
      return await launchUrl(
        noteUri(vault, noteTitle),
        mode: LaunchMode.externalApplication,
      );
    } on PlatformException {
      return false;
    }
  }
}
