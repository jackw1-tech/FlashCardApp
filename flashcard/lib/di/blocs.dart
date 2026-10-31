part of 'dependency_injector.dart';

final List<BlocProvider> blocs = [
  BlocProvider<ReadSourceCubit>(
    lazy: false,
    create: (context) => ReadSourceCubit(repository: context.read())..start(),
  ),
  BlocProvider<AuthCubit>(
    create: (context) => AuthCubit(repository: context.read())..start(),
  ),
  BlocProvider<DecksCubit>(
    create: (context) => DecksCubit(repository: context.read()),
  ),
  BlocProvider<StatsCubit>(
    create: (context) => StatsCubit(repository: context.read()),
  ),
  BlocProvider<TemporaryDecksCubit>(
    create: (context) => TemporaryDecksCubit(repository: context.read()),
  ),
  BlocProvider<SettingsCubit>(
    create: (context) => SettingsCubit(repository: context.read())..load(),
  ),
  BlocProvider<CardActionsCubit>(
    create: (context) =>
        CardActionsCubit(cards: context.read(), obsidian: context.read()),
  ),
];
