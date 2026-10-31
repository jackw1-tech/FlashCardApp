part of 'dependency_injector.dart';

final List<RepositoryProvider> repositories = [
  RepositoryProvider<AuthRepository>(
    create: (context) => AuthRepositoryImpl(
      service: context.read(),
      store: context.read(),
      mapper: context.read(),
    ),
  ),
  RepositoryProvider<DeckRepository>(
    create: (context) => DeckRepositoryImpl(
      service: context.read(),
      mapper: context.read(),
      noteMapper: context.read(),
      vaultSyncMapper: context.read(),
      store: context.read(),
    ),
  ),
  RepositoryProvider<StudyRepository>(
    create: (context) => StudyRepositoryImpl(
      service: context.read(),
      cardMapper: context.read(),
      answerMapper: context.read(),
      reviewMapper: context.read(),
      statsMapper: context.read(),
      temporaryDeckMapper: context.read(),
      sessionDraftMapper: context.read(),
      savedSessionMapper: context.read(),
      store: context.read(),
    ),
  ),
  RepositoryProvider<CardRepository>(
    create: (context) => CardRepositoryImpl(
      service: context.read(),
      cardMapper: context.read(),
      reportMapper: context.read(),
      draftMapper: context.read(),
    ),
  ),
  RepositoryProvider<ChatRepository>(
    create: (context) => ChatRepositoryImpl(
      service: context.read(),
      mapper: context.read(),
      summaryMapper: context.read(),
    ),
  ),
  RepositoryProvider<SettingsRepository>(
    create: (context) =>
        SettingsRepositoryImpl(service: context.read(), mapper: context.read()),
  ),
  RepositoryProvider<ObsidianRepository>(
    create: (context) => ObsidianRepositoryImpl(service: context.read()),
  ),
  RepositoryProvider<ReadSourceRepository>(
    create: (context) => ReadSourceRepositoryImpl(service: context.read()),
  ),
];
