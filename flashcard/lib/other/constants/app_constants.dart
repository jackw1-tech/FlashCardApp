class AppConstants {
  static const Duration requestTimeout = Duration(seconds: 10);

  static const Duration chatTurnTimeout = Duration(seconds: 130);

  static const List<int> sessionLengthOptions = [10, 20, 50];
  static const int sessionLength = 20;

  static const int maxExcludedIds = 50;

  static const String localPrefix = 'fc.';
  static const String apiBaseKey = 'fc.api_base';
  static const String accessExpiresKey = 'fc.access_expires_at';
  static const String refreshExpiresKey = 'fc.refresh_expires_at';
  static const String userKey = 'fc.user';
  static const String decksSnapshotKey = 'fc.snapshot.decks';
  static const String statsSnapshotKey = 'fc.snapshot.stats';

  static const Duration expiryMargin = Duration(seconds: 60);

  static const int recentOutcomes = 5;

  static const String textScaleKey = 'text_scale';
  static const String dailyGoalKey = 'daily_goal';
  static const List<double> textScaleOptions = [0.85, 1.0, 1.15, 1.3];
  static const List<String> textScaleLabels = [
    'Piccolo',
    'Normale',
    'Grande',
    'Molto grande',
  ];
  static const List<int> dailyGoalOptions = [10, 20, 30, 50, 100];
  static const int defaultDailyGoal = 30;

  static const Duration searchDebounce = Duration(milliseconds: 300);
  static const int searchMinLength = 2;

  static const Duration shortAnimationDuration = Duration(milliseconds: 200);
  static const Duration mediumAnimationDuration = Duration(milliseconds: 400);
  static const Duration longAnimationDuration = Duration(milliseconds: 800);
}
