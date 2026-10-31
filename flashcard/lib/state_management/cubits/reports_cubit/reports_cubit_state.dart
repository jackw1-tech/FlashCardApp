part of 'reports_cubit.dart';

sealed class ReportsState {
  const ReportsState();
}

class FetchingReportsState extends ReportsState {
  const FetchingReportsState();
}

class FetchedReportsState extends ReportsState {
  final List<CardReport> reports;

  final String? notice;

  const FetchedReportsState(this.reports, {this.notice});
}

class ErrorReportsState extends ReportsState {
  final String message;

  const ErrorReportsState(this.message);
}
