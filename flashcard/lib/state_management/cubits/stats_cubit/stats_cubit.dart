import 'package:flashcard/model/app_failure.dart';
import 'package:flashcard/model/entities/study_stats.dart';
import 'package:flashcard/repositories/study_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'stats_cubit_state.dart';

class StatsCubit extends Cubit<StatsState> {
  final StudyRepository repository;

  StatsCubit({required this.repository}) : super(const FetchingStatsState());

  Future<void> fetch() async {
    final shown = switch (state) {
      FetchedStatsState(:final stats) => stats,
      _ => repository.cachedStats(),
    };
    emit(shown == null ? const FetchingStatsState() : FetchedStatsState(shown));
    try {
      emit(FetchedStatsState(await repository.fetchStats()));
    } on AppFailure catch (failure) {
      if (shown == null) emit(ErrorStatsState(failure.message));
    }
  }

  void reset() => emit(const FetchingStatsState());
}
