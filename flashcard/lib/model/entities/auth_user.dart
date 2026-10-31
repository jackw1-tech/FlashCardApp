import 'package:flashcard/model/base_model.dart';

class AuthUser implements BaseModel {
  @override
  final String id;
  final String username;

  const AuthUser({required this.id, required this.username});

  @override
  Map<String, dynamic> toJson() => {'id': id, 'username': username};

  @override
  AuthUser copyWith({String? id, String? username}) =>
      AuthUser(id: id ?? this.id, username: username ?? this.username);

  @override
  bool operator ==(Object other) =>
      other is AuthUser && other.id == id && other.username == username;

  @override
  int get hashCode => Object.hash(id, username);
}
