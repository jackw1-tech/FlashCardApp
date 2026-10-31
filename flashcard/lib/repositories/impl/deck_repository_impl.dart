import 'dart:convert';

import 'package:flashcard/model/entities/decks_overview.dart';
import 'package:flashcard/model/entities/note_summary.dart';
import 'package:flashcard/model/entities/vault_sync_report.dart';
import 'package:flashcard/network/dto/deck_ref_dto.dart';
import 'package:flashcard/network/dto/decks_overview_dto.dart';
import 'package:flashcard/network/dto/note_summary_dto.dart';
import 'package:flashcard/network/dto/vault_sync_report_dto.dart';
import 'package:flashcard/network/service/deck_service.dart';
import 'package:flashcard/network/service/local_store_service.dart';
import 'package:flashcard/other/constants/app_constants.dart';
import 'package:flashcard/repositories/deck_repository.dart';
import 'package:flashcard/repositories/impl/base_repository_impl.dart';
import 'package:pine/pine.dart';

class DeckRepositoryImpl with BaseRepositoryImpl implements DeckRepository {
  final DeckService service;
  final DTOMapper<DecksOverviewDTO, DecksOverview> mapper;
  final DTOMapper<NoteSummaryDTO, NoteSummary> noteMapper;
  final DTOMapper<VaultSyncReportDTO, VaultSyncReport> vaultSyncMapper;
  final LocalStoreService store;

  DeckRepositoryImpl({
    required this.service,
    required this.mapper,
    required this.noteMapper,
    required this.vaultSyncMapper,
    required this.store,
  });

  @override
  DecksOverview? cachedOverview() {
    final raw = store.read(AppConstants.decksSnapshotKey);
    if (raw == null) return null;
    try {
      return mapper.fromDTO(
        DecksOverviewDTO.fromJson(jsonDecode(raw) as Map<String, dynamic>),
      );
    } on FormatException {
      return null;
    }
  }

  @override
  Future<DecksOverview> fetchOverview() => guard(() async {
    final raw = await service.fetchOverview();
    final overview = mapper.fromDTO(DecksOverviewDTO.fromJson(raw));
    store.write(AppConstants.decksSnapshotKey, jsonEncode(raw));
    return overview;
  });

  @override
  Future<List<NoteSummary>> fetchNotes(String slug) => guard(() async {
    final raw = await service.fetchNotes(slug);
    return noteMapper
        .fromDTOMany([
          for (final note in raw['notes'] as List<dynamic>)
            NoteSummaryDTO.fromJson(note as Map<String, dynamic>),
        ])
        .toList(growable: false);
  });

  @override
  Future<String> renameDeck({required String slug, required String name}) =>
      guard(() async {
        final raw = await service.renameDeck(slug: slug, name: name);
        store.remove(AppConstants.decksSnapshotKey);
        return DeckRefDTO.fromJson(raw).name;
      });

  @override
  Future<VaultSyncReport> syncVault() => guard(() async {
    final report = vaultSyncMapper.fromDTO(
      VaultSyncReportDTO.fromJson(await service.syncVault()),
    );
    store.remove(AppConstants.decksSnapshotKey);
    return report;
  });
}
