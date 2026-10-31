import 'package:pine/pine.dart';

class SessionUserDTO extends DTO {
  final int id;
  final String username;

  const SessionUserDTO({required this.id, required this.username});

  factory SessionUserDTO.fromJson(Map<String, dynamic> json) => SessionUserDTO(
    id: json['id'] as int,
    username: json['username'] as String,
  );

  Map<String, dynamic> toJson() => {'id': id, 'username': username};
}

class SessionDTO extends DTO {
  final SessionUserDTO user;
  final String accessExpiresAt;

  final String? refreshExpiresAt;

  const SessionDTO({
    required this.user,
    required this.accessExpiresAt,
    this.refreshExpiresAt,
  });

  factory SessionDTO.fromJson(Map<String, dynamic> json) => SessionDTO(
    user: SessionUserDTO.fromJson(json['user'] as Map<String, dynamic>),
    accessExpiresAt: json['access_expires_at'] as String,
    refreshExpiresAt: json['refresh_expires_at'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'user': user.toJson(),
    'access_expires_at': accessExpiresAt,
    'refresh_expires_at': refreshExpiresAt,
  };
}
