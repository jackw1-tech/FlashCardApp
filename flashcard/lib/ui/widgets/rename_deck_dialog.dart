import 'package:flutter/material.dart';

class RenameDeckDialog extends StatefulWidget {
  final String currentName;

  const RenameDeckDialog({required this.currentName, super.key});

  static Future<String?> show(BuildContext context, String currentName) =>
      showDialog<String>(
        context: context,
        builder: (_) => RenameDeckDialog(currentName: currentName),
      );

  @override
  State<RenameDeckDialog> createState() => _RenameDeckDialogState();
}

class _RenameDeckDialogState extends State<RenameDeckDialog> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.currentName)
        ..selection = TextSelection(
          baseOffset: 0,
          extentOffset: widget.currentName.length,
        );

  String get _name => _controller.text.trim();

  bool get _canSave => _name.isNotEmpty && _name != widget.currentName;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    if (_canSave) Navigator.of(context).pop(_name);
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Rinomina mazzo'),
    content: TextField(
      controller: _controller,
      autofocus: true,
      maxLength: 200,
      textCapitalization: TextCapitalization.sentences,
      decoration: const InputDecoration(hintText: 'Nome del mazzo'),
      onChanged: (_) => setState(() {}),
      onSubmitted: (_) => _save(),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Annulla'),
      ),
      FilledButton(
        onPressed: _canSave ? _save : null,
        style: FilledButton.styleFrom(minimumSize: const Size(88, 40)),
        child: const Text('Salva'),
      ),
    ],
  );
}
