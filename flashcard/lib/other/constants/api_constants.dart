class ApiConstants {
  static const String baseApiUrl = String.fromEnvironment('API_BASE_URL');

  static const String obsidianVault = String.fromEnvironment(
    'OBSIDIAN_VAULT',
    defaultValue: '2Brain',
  );

  static const String authPathPrefix = '/api/auth/';
  static const String loginPath = '/api/auth/login/';
  static const String sessionPath = '/api/auth/session/';
  static const String logoutPath = '/api/auth/logout/';
  static const String decksPath = '/api/decks/';
  static const String vaultSyncPath = '/api/vault/sync/';
  static String deckPath(String slug) =>
      '$decksPath${Uri.encodeComponent(slug)}/';
  static String deckNotesPath(String slug) => '${deckPath(slug)}notes/';
  static const String nextCardPath = '/api/next-card/';
  static const String reviewsPath = '/api/reviews/';
  static String undoReviewPath(String reviewId) =>
      '$reviewsPath$reviewId/undo/';
  static const String statsPath = '/api/stats/';
  static const String temporaryDecksPath = '/api/temporary-decks/';
  static const String sessionsPath = '/api/sessions/';
  static String temporaryDeckPath(String id) => '$temporaryDecksPath$id/';
  static const String searchPath = '/api/cards/search/';
  static String cardReportsPath(String cardId) => '/api/cards/$cardId/reports/';
  static const String reportsPath = '/api/reports/';
  static String resolveReportPath(String reportId) =>
      '$reportsPath$reportId/resolve/';
  static const String conversationsPath = '/api/conversations/';
  static String conversationPath(String id) => '$conversationsPath$id/';
  static String conversationMessagesPath(String id) =>
      '${conversationPath(id)}messages/';
  static String conversationConfirmationPath(String id) =>
      '${conversationPath(id)}confirmation/';
}
