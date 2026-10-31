import 'package:flashcard/model/app_failure.dart';
import 'package:flashcard/model/entities/card_report.dart';
import 'package:flashcard/repositories/card_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'reports_cubit_state.dart';

class ReportsCubit extends Cubit<ReportsState> {
  final CardRepository repository;

  ReportsCubit({required this.repository})
    : super(const FetchingReportsState());

  Future<void> fetch() async {
    emit(const FetchingReportsState());
    try {
      emit(FetchedReportsState(await repository.openReports()));
    } on AppFailure catch (failure) {
      emit(ErrorReportsState(failure.message));
    }
  }

  Future<void> resolve(String reportId) async {
    final current = state;
    if (current is! FetchedReportsState) return;
    try {
      await repository.resolveReport(reportId);
      emit(
        FetchedReportsState([
          for (final report in current.reports)
            if (report.id != reportId) report,
        ]),
      );
    } on AppFailure catch (failure) {
      emit(
        FetchedReportsState(
          current.reports,
          notice: 'Non risolta. ${failure.message}',
        ),
      );
    }
  }
}
