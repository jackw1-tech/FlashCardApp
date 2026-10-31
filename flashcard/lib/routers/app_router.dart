import 'package:auto_route/auto_route.dart';
import 'package:collection/collection.dart';
import 'package:flashcard/model/entities/session_summary.dart';
import 'package:flashcard/model/entities/study_card.dart';
import 'package:flashcard/ui/pages/chat_page.dart';
import 'package:flashcard/ui/pages/conversations_page.dart';
import 'package:flashcard/ui/pages/decks_page.dart';
import 'package:flashcard/ui/pages/notes_page.dart';
import 'package:flashcard/ui/pages/reports_page.dart';
import 'package:flashcard/ui/pages/search_page.dart';
import 'package:flashcard/ui/pages/saved_sessions_page.dart';
import 'package:flashcard/ui/pages/session_summary_page.dart';
import 'package:flashcard/ui/pages/settings_page.dart';
import 'package:flashcard/ui/pages/stats_page.dart';
import 'package:flashcard/ui/pages/study_page.dart';
import 'package:flutter/material.dart';

part 'app_router.gr.dart';

@AutoRouterConfig()
class AppRouter extends RootStackRouter {
  AppRouter({super.navigatorKey});

  @override
  RouteType get defaultRouteType => RouteType.custom(
    transitionsBuilder: TransitionsBuilders.slideLeftWithFade,
    duration: const Duration(milliseconds: 260),
    reverseDuration: const Duration(milliseconds: 220),
    enablePredictiveBackGesture: true,
  );

  @override
  List<AutoRoute> get routes => [
    AutoRoute(path: '/', page: DecksRoute.page, initial: true),
    AutoRoute(path: '/notes', page: NotesRoute.page),
    AutoRoute(path: '/study', page: StudyRoute.page),
    AutoRoute(path: '/summary', page: SessionSummaryRoute.page),
    AutoRoute(path: '/search', page: SearchRoute.page),
    AutoRoute(path: '/stats', page: StatsRoute.page),
    AutoRoute(path: '/sessions', page: SavedSessionsRoute.page),
    AutoRoute(path: '/settings', page: SettingsRoute.page),
    AutoRoute(path: '/reports', page: ReportsRoute.page),
    AutoRoute(path: '/chats', page: ConversationsRoute.page),
    AutoRoute(path: '/chat', page: ChatRoute.page),
  ];
}
