part of 'stats_cubit.dart';

sealed class StatsState {
  const StatsState();
}

class FetchingStatsState extends StatsState {
  const FetchingStatsState();
}

class FetchedStatsState extends StatsState {
  final StudyStats stats;

  const FetchedStatsState(this.stats);
}

class ErrorStatsState extends StatsState {
  final String message;

  const ErrorStatsState(this.message);
}
