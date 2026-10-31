import 'dart:async';
import 'dart:convert';

import 'package:flashcard/model/entities/auth_user.dart';
import 'package:flashcard/network/dto/session_dto.dart';
import 'package:flashcard/network/service/auth_service.dart';
import 'package:flashcard/network/service/local_store_service.dart';
import 'package:flashcard/other/constants/api_constants.dart';
import 'package:flashcard/other/constants/app_constants.dart';
import 'package:flashcard/repositories/auth_repository.dart';
import 'package:flashcard/repositories/impl/base_repository_impl.dart';
import 'package:pine/pine.dart';

class AuthRepositoryImpl with BaseRepositoryImpl implements AuthRepository {
  final AuthService service;
  final LocalStoreService store;
  final DTOMapper<SessionUserDTO, AuthUser> mapper;
  final DateTime Function() now;

  late final StreamSubscription<Map<String, dynamic>> _updates;

  AuthRepositoryImpl({
    required this.service,
    required this.store,
    required this.mapper,
    String apiBase = ApiConstants.baseApiUrl,
    DateTime Function()? now,
  }) : now = now ?? DateTime.now {
    store.write(AppConstants.apiBaseKey, apiBase);
    _updates = service.sessionUpdates.listen(_saveHints);
  }

  @override
  AuthUser? likelySessionUser() {
    final refreshExpires = _readDate(AppConstants.refreshExpiresKey);
    final user = store.read(AppConstants.userKey);
    if (refreshExpires == null ||
        user == null ||
        !refreshExpires.isAfter(now())) {
      return null;
    }
    return mapper.fromDTO(
      SessionUserDTO.fromJson(jsonDecode(user) as Map<String, dynamic>),
    );
  }

  @override
  bool likelyAccessValid() {
    final accessExpires = _readDate(AppConstants.accessExpiresKey);
    return accessExpires != null &&
        accessExpires.subtract(AppConstants.expiryMargin).isAfter(now());
  }

  @override
  Future<AuthUser?> restoreSession() async {
    final cached = likelySessionUser();
    if (cached == null) {
      _clearLocal();
      return null;
    }
    try {
      final result = await service.session();
      return switch (result.status) {
        200 => mapper.fromDTO(SessionDTO.fromJson(result.body!).user),
        401 => _expire(),
        _ => cached,
      };
    } on Exception {
      return cached;
    }
  }

  @override
  Future<AuthUser> login(String username, String password) => guard(() async {
    final raw = await service.login(username, password);
    return mapper.fromDTO(SessionDTO.fromJson(raw).user);
  });

  @override
  Future<void> logout() async {
    try {
      await service.logout();
    } on Exception {
      return;
    } finally {
      _clearLocal();
    }
  }

  @override
  Stream<void> get sessionExpired => service.sessionExpired.map((_) {
    _clearLocal();
  });

  AuthUser? _expire() {
    _clearLocal();
    return null;
  }

  void _saveHints(Map<String, dynamic> body) {
    final session = SessionDTO.fromJson(body);
    store.write(AppConstants.accessExpiresKey, session.accessExpiresAt);
    if (session.refreshExpiresAt != null) {
      store.write(AppConstants.refreshExpiresKey, session.refreshExpiresAt!);
    }
    store.write(AppConstants.userKey, jsonEncode(session.user.toJson()));
  }

  void _clearLocal() {
    store.removeWhere(AppConstants.localPrefix);
    store.write(AppConstants.apiBaseKey, ApiConstants.baseApiUrl);
  }

  DateTime? _readDate(String key) {
    final value = store.read(key);
    return value == null ? null : DateTime.tryParse(value);
  }

  void dispose() => _updates.cancel();
}
