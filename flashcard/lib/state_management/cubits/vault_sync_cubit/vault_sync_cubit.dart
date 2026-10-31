import 'package:flashcard/model/app_failure.dart';
import 'package:flashcard/model/entities/vault_sync_report.dart';
import 'package:flashcard/repositories/deck_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'vault_sync_cubit_state.dart';

class VaultSyncCubit extends Cubit<VaultSyncState> {
  final DeckRepository repository;

  VaultSyncCubit({required this.repository})
    : super(const IdleVaultSyncState());

  Future<void> sync() async {
    if (state is SyncingVaultSyncState) return;
    emit(const SyncingVaultSyncState());
    try {
      emit(CompletedVaultSyncState(await repository.syncVault()));
    } on AppFailure catch (failure) {
      emit(ErrorVaultSyncState(failure.message));
    }
  }
}
