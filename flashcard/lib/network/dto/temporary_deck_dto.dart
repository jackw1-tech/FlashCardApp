import 'package:pine/pine.dart';

class TemporaryDeckDTO extends DTO {
  final int id;
  final String name;
  final String createdAt;
  final String expiresAt;
  final int total;
  final int done;
  final int missed;

  const TemporaryDeckDTO({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.expiresAt,
    required this.total,
    required this.done,
    required this.missed,
  });

  factory TemporaryDeckDTO.fromJson(Map<String, dynamic> json) =>
      TemporaryDeckDTO(
        id: json['id'] as int,
        name: json['name'] as String,
        createdAt: json['created_at'] as String,
        expiresAt: json['expires_at'] as String,
        total: json['total'] as int,
        done: json['done'] as int,
        missed: json['missed'] as int,
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'created_at': createdAt,
    'expires_at': expiresAt,
    'total': total,
    'done': done,
    'missed': missed,
  };
}
