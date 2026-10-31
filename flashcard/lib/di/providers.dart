part of 'dependency_injector.dart';

final List<SingleChildWidget> _providers = [
  Provider<LocalStoreService>(create: (_) => LocalStoreServiceImpl()),
  Provider<PrefetchService>(create: (_) => PrefetchServiceImpl()),
  Provider<ReadSourceService>(create: (_) => ReadSourceServiceImpl()),
  Provider<SessionRefresher>(
    create: (context) => SessionRefresher(
      client: CsrfInterceptor(
        ReadSourceInterceptor(createPlatformClient(), context.read()),
      ),
      baseUrl: ApiConstants.baseApiUrl,
      prefetch: context.read(),
    ),
  ),
  Provider<http.Client>(
    create: (context) => SessionInterceptor(
      CsrfInterceptor(
        ReadSourceInterceptor(createPlatformClient(), context.read()),
      ),
      context.read<SessionRefresher>(),
    ),
    dispose: (_, client) => client.close(),
  ),
  Provider<AuthService>(
    create: (context) => AuthServiceImpl(
      client: context.read(),
      baseUrl: ApiConstants.baseApiUrl,
      refresher: context.read(),
    ),
  ),
  Provider<DeckService>(
    create: (context) => DeckServiceImpl(
      client: context.read(),
      baseUrl: ApiConstants.baseApiUrl,
      prefetch: context.read(),
    ),
  ),
  Provider<StudyService>(
    create: (context) => StudyServiceImpl(
      client: context.read(),
      baseUrl: ApiConstants.baseApiUrl,
      prefetch: context.read(),
    ),
  ),
  Provider<CardService>(
    create: (context) => CardServiceImpl(
      client: context.read(),
      baseUrl: ApiConstants.baseApiUrl,
    ),
  ),
  Provider<ChatService>(
    create: (context) => ChatServiceImpl(
      client: context.read(),
      baseUrl: ApiConstants.baseApiUrl,
    ),
  ),
  Provider<SettingsService>(create: (_) => SettingsServiceImpl()),
  Provider<ObsidianService>(create: (_) => ObsidianServiceImpl()),
];
