import 'package:pine/pine.dart';

class SavedSessionDTO extends DTO {
  final int id;
  final String startedAt;
  final String endedAt;
  final int knew;
  final int didntKnow;
  final String? deckName;
  final String? noteTitle;
  final String? temporaryDeckName;

  const SavedSessionDTO({
    required this.id,
    required this.startedAt,
    required this.endedAt,
    required this.knew,
    required this.didntKnow,
    this.deckName,
    this.noteTitle,
    this.temporaryDeckName,
  });

  factory SavedSessionDTO.fromJson(Map<String, dynamic> json) =>
      SavedSessionDTO(
        id: json['id'] as int,
        startedAt: json['started_at'] as String,
        endedAt: json['ended_at'] as String,
        knew: json['knew'] as int,
        didntKnow: json['didnt_know'] as int,
        deckName: (json['deck'] as Map<String, dynamic>?)?['name'] as String?,
        noteTitle: switch (json['note_title']) {
          final String value when value.isNotEmpty => value,
          _ => null,
        },
        temporaryDeckName:
            (json['temporary_deck'] as Map<String, dynamic>?)?['name']
                as String?,
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'started_at': startedAt,
    'ended_at': endedAt,
    'knew': knew,
    'didnt_know': didntKnow,
    'deck': deckName == null ? null : {'name': deckName},
    'note_title': noteTitle ?? '',
    'temporary_deck': temporaryDeckName == null
        ? null
        : {'name': temporaryDeckName},
  };
}
