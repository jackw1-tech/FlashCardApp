import 'package:flashcard/di/dependency_injector.dart';
import 'package:flashcard/routers/app_router.dart';
import 'package:flashcard/state_management/cubits/auth_cubit/auth_cubit.dart';
import 'package:flashcard/state_management/cubits/decks_cubit/decks_cubit.dart';
import 'package:flashcard/state_management/cubits/stats_cubit/stats_cubit.dart';
import 'package:flashcard/state_management/cubits/temporary_decks_cubit/temporary_decks_cubit.dart';
import 'package:flashcard/theme/app_theme.dart';
import 'package:flashcard/theme/app_colors.dart';
import 'package:flashcard/theme/app_text_styles.dart';
import 'package:flashcard/theme/dimensions.dart';
import 'package:flashcard/ui/pages/login_page.dart';
import 'package:flashcard/ui/widgets/card_markdown.dart';
import 'package:flashcard/ui/widgets/read_source_dot.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const FlashcardApp());
  WidgetsBinding.instance.addPostFrameCallback((_) => preloadCardMarkdown());
}

class FlashcardApp extends StatelessWidget {
  const FlashcardApp({super.key});

  @override
  Widget build(BuildContext context) =>
      const DependencyInjector(child: _AuthGate());
}

class _AuthGate extends StatefulWidget {
  const _AuthGate();

  @override
  State<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<_AuthGate> {
  AppRouter? _router;
  RouterConfig<Object>? _routerConfig;

  @override
  void initState() {
    super.initState();
    _onAuthChanged(context, context.read<AuthCubit>().state);
  }

  void _onAuthChanged(BuildContext context, AuthState state) {
    switch (state) {
      case AuthenticatedAuthState():
        context.read<DecksCubit>().fetch();
        context.read<StatsCubit>().fetch();
        context.read<TemporaryDecksCubit>().fetch();
      case UnauthenticatedAuthState():
        context.read<DecksCubit>().reset();
        context.read<StatsCubit>().reset();
        context.read<TemporaryDecksCubit>().reset();
        _router = null;
        _routerConfig = null;
      case CheckingAuthState():
        break;
    }
  }

  @override
  Widget build(BuildContext context) => BlocConsumer<AuthCubit, AuthState>(
    listenWhen: (previous, current) =>
        previous.runtimeType != current.runtimeType ||
        (previous is AuthenticatedAuthState &&
            current is AuthenticatedAuthState &&
            previous.user != current.user),
    listener: _onAuthChanged,
    buildWhen: (previous, current) =>
        previous.runtimeType != current.runtimeType,
    builder: (context, state) => switch (state) {
      CheckingAuthState() => _app(home: const _StartupPage()),
      UnauthenticatedAuthState() => _app(home: const LoginPage()),
      AuthenticatedAuthState() => MaterialApp.router(
        title: 'Flashcard',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        themeAnimationDuration: const Duration(milliseconds: 250),
        themeAnimationCurve: Curves.easeOutCubic,
        routerConfig: _routerConfig ??= (_router ??= AppRouter()).config(),
        builder: _withReadSource,
      ),
    },
  );

  Widget _app({required Widget home}) => MaterialApp(
    title: 'Flashcard',
    theme: AppTheme.lightTheme,
    darkTheme: AppTheme.darkTheme,
    themeMode: ThemeMode.system,
    themeAnimationDuration: const Duration(milliseconds: 250),
    themeAnimationCurve: Curves.easeOutCubic,
    home: home,
    builder: _withReadSource,
  );

  static Widget _withReadSource(BuildContext context, Widget? child) =>
      ReadSourceOverlay(child: child ?? const SizedBox.shrink());
}

class _StartupPage extends StatelessWidget {
  const _StartupPage();

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: Semantics(
          label: 'Avvio di Flashcard',
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Flashcard',
                style: AppTextStyles.displayMd.copyWith(
                  color: context.colors.ink,
                  fontSize: 40,
                ),
              ),
              const SizedBox(height: Dimensions.spaceSm),
              SizedBox(
                width: 120,
                child: LinearProgressIndicator(
                  minHeight: 3,
                  borderRadius: BorderRadius.circular(Dimensions.radiusPill),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
