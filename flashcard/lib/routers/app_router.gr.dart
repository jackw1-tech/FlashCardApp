// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouterGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

part of 'app_router.dart';

/// generated route for
/// [ChatPage]
class ChatRoute extends PageRouteInfo<ChatRouteArgs> {
  ChatRoute({String? conversationId, Key? key, List<PageRouteInfo>? children})
    : super(
        ChatRoute.name,
        args: ChatRouteArgs(conversationId: conversationId, key: key),
        initialChildren: children,
      );

  static const String name = 'ChatRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<ChatRouteArgs>(
        orElse: () => const ChatRouteArgs(),
      );
      return ChatPage(conversationId: args.conversationId, key: args.key);
    },
  );
}

class ChatRouteArgs {
  const ChatRouteArgs({this.conversationId, this.key});

  final String? conversationId;

  final Key? key;

  @override
  String toString() {
    return 'ChatRouteArgs{conversationId: $conversationId, key: $key}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ChatRouteArgs) return false;
    return conversationId == other.conversationId && key == other.key;
  }

  @override
  int get hashCode => conversationId.hashCode ^ key.hashCode;
}

/// generated route for
/// [ConversationsPage]
class ConversationsRoute extends PageRouteInfo<void> {
  const ConversationsRoute({List<PageRouteInfo>? children})
    : super(ConversationsRoute.name, initialChildren: children);

  static const String name = 'ConversationsRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const ConversationsPage();
    },
  );
}

/// generated route for
/// [DecksPage]
class DecksRoute extends PageRouteInfo<void> {
  const DecksRoute({List<PageRouteInfo>? children})
    : super(DecksRoute.name, initialChildren: children);

  static const String name = 'DecksRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const DecksPage();
    },
  );
}

/// generated route for
/// [NotesPage]
class NotesRoute extends PageRouteInfo<NotesRouteArgs> {
  NotesRoute({
    required String deckSlug,
    required String deckName,
    Key? key,
    List<PageRouteInfo>? children,
  }) : super(
         NotesRoute.name,
         args: NotesRouteArgs(deckSlug: deckSlug, deckName: deckName, key: key),
         initialChildren: children,
       );

  static const String name = 'NotesRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<NotesRouteArgs>();
      return NotesPage(
        deckSlug: args.deckSlug,
        deckName: args.deckName,
        key: args.key,
      );
    },
  );
}

class NotesRouteArgs {
  const NotesRouteArgs({
    required this.deckSlug,
    required this.deckName,
    this.key,
  });

  final String deckSlug;

  final String deckName;

  final Key? key;

  @override
  String toString() {
    return 'NotesRouteArgs{deckSlug: $deckSlug, deckName: $deckName, key: $key}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! NotesRouteArgs) return false;
    return deckSlug == other.deckSlug &&
        deckName == other.deckName &&
        key == other.key;
  }

  @override
  int get hashCode => deckSlug.hashCode ^ deckName.hashCode ^ key.hashCode;
}

/// generated route for
/// [ReportsPage]
class ReportsRoute extends PageRouteInfo<void> {
  const ReportsRoute({List<PageRouteInfo>? children})
    : super(ReportsRoute.name, initialChildren: children);

  static const String name = 'ReportsRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const ReportsPage();
    },
  );
}

/// generated route for
/// [SavedSessionsPage]
class SavedSessionsRoute extends PageRouteInfo<void> {
  const SavedSessionsRoute({List<PageRouteInfo>? children})
    : super(SavedSessionsRoute.name, initialChildren: children);

  static const String name = 'SavedSessionsRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const SavedSessionsPage();
    },
  );
}

/// generated route for
/// [SearchPage]
class SearchRoute extends PageRouteInfo<void> {
  const SearchRoute({List<PageRouteInfo>? children})
    : super(SearchRoute.name, initialChildren: children);

  static const String name = 'SearchRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const SearchPage();
    },
  );
}

/// generated route for
/// [SessionSummaryPage]
class SessionSummaryRoute extends PageRouteInfo<SessionSummaryRouteArgs> {
  SessionSummaryRoute({
    required String deckName,
    required SessionSummary summary,
    required int sessionLength,
    String? deckSlug,
    String? noteTitle,
    String? temporaryDeckId,
    Key? key,
    List<PageRouteInfo>? children,
  }) : super(
         SessionSummaryRoute.name,
         args: SessionSummaryRouteArgs(
           deckName: deckName,
           summary: summary,
           sessionLength: sessionLength,
           deckSlug: deckSlug,
           noteTitle: noteTitle,
           temporaryDeckId: temporaryDeckId,
           key: key,
         ),
         initialChildren: children,
       );

  static const String name = 'SessionSummaryRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<SessionSummaryRouteArgs>();
      return SessionSummaryPage(
        deckName: args.deckName,
        summary: args.summary,
        sessionLength: args.sessionLength,
        deckSlug: args.deckSlug,
        noteTitle: args.noteTitle,
        temporaryDeckId: args.temporaryDeckId,
        key: args.key,
      );
    },
  );
}

class SessionSummaryRouteArgs {
  const SessionSummaryRouteArgs({
    required this.deckName,
    required this.summary,
    required this.sessionLength,
    this.deckSlug,
    this.noteTitle,
    this.temporaryDeckId,
    this.key,
  });

  final String deckName;

  final SessionSummary summary;

  final int sessionLength;

  final String? deckSlug;

  final String? noteTitle;

  final String? temporaryDeckId;

  final Key? key;

  @override
  String toString() {
    return 'SessionSummaryRouteArgs{deckName: $deckName, summary: $summary, sessionLength: $sessionLength, deckSlug: $deckSlug, noteTitle: $noteTitle, temporaryDeckId: $temporaryDeckId, key: $key}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! SessionSummaryRouteArgs) return false;
    return deckName == other.deckName &&
        summary == other.summary &&
        sessionLength == other.sessionLength &&
        deckSlug == other.deckSlug &&
        noteTitle == other.noteTitle &&
        temporaryDeckId == other.temporaryDeckId &&
        key == other.key;
  }

  @override
  int get hashCode =>
      deckName.hashCode ^
      summary.hashCode ^
      sessionLength.hashCode ^
      deckSlug.hashCode ^
      noteTitle.hashCode ^
      temporaryDeckId.hashCode ^
      key.hashCode;
}

/// generated route for
/// [SettingsPage]
class SettingsRoute extends PageRouteInfo<void> {
  const SettingsRoute({List<PageRouteInfo>? children})
    : super(SettingsRoute.name, initialChildren: children);

  static const String name = 'SettingsRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const SettingsPage();
    },
  );
}

/// generated route for
/// [StatsPage]
class StatsRoute extends PageRouteInfo<void> {
  const StatsRoute({List<PageRouteInfo>? children})
    : super(StatsRoute.name, initialChildren: children);

  static const String name = 'StatsRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const StatsPage();
    },
  );
}

/// generated route for
/// [StudyPage]
class StudyRoute extends PageRouteInfo<StudyRouteArgs> {
  StudyRoute({
    required String deckName,
    required int sessionLength,
    String? deckSlug,
    String? noteTitle,
    String? temporaryDeckId,
    List<StudyCard>? fixedCards,
    Key? key,
    List<PageRouteInfo>? children,
  }) : super(
         StudyRoute.name,
         args: StudyRouteArgs(
           deckName: deckName,
           sessionLength: sessionLength,
           deckSlug: deckSlug,
           noteTitle: noteTitle,
           temporaryDeckId: temporaryDeckId,
           fixedCards: fixedCards,
           key: key,
         ),
         initialChildren: children,
       );

  static const String name = 'StudyRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<StudyRouteArgs>();
      return StudyPage(
        deckName: args.deckName,
        sessionLength: args.sessionLength,
        deckSlug: args.deckSlug,
        noteTitle: args.noteTitle,
        temporaryDeckId: args.temporaryDeckId,
        fixedCards: args.fixedCards,
        key: args.key,
      );
    },
  );
}

class StudyRouteArgs {
  const StudyRouteArgs({
    required this.deckName,
    required this.sessionLength,
    this.deckSlug,
    this.noteTitle,
    this.temporaryDeckId,
    this.fixedCards,
    this.key,
  });

  final String deckName;

  final int sessionLength;

  final String? deckSlug;

  final String? noteTitle;

  final String? temporaryDeckId;

  final List<StudyCard>? fixedCards;

  final Key? key;

  @override
  String toString() {
    return 'StudyRouteArgs{deckName: $deckName, sessionLength: $sessionLength, deckSlug: $deckSlug, noteTitle: $noteTitle, temporaryDeckId: $temporaryDeckId, fixedCards: $fixedCards, key: $key}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! StudyRouteArgs) return false;
    return deckName == other.deckName &&
        sessionLength == other.sessionLength &&
        deckSlug == other.deckSlug &&
        noteTitle == other.noteTitle &&
        temporaryDeckId == other.temporaryDeckId &&
        const ListEquality<StudyCard>().equals(fixedCards, other.fixedCards) &&
        key == other.key;
  }

  @override
  int get hashCode =>
      deckName.hashCode ^
      sessionLength.hashCode ^
      deckSlug.hashCode ^
      noteTitle.hashCode ^
      temporaryDeckId.hashCode ^
      const ListEquality<StudyCard>().hash(fixedCards) ^
      key.hashCode;
}
