part of 'vault_sync_cubit.dart';

sealed class VaultSyncState {
  const VaultSyncState();
}

class IdleVaultSyncState extends VaultSyncState {
  const IdleVaultSyncState();
}

class SyncingVaultSyncState extends VaultSyncState {
  const SyncingVaultSyncState();
}

class CompletedVaultSyncState extends VaultSyncState {
  final VaultSyncReport report;

  const CompletedVaultSyncState(this.report);
}

class ErrorVaultSyncState extends VaultSyncState {
  final String message;

  const ErrorVaultSyncState(this.message);
}
