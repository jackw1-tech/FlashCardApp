enum ReportReason {
  wrongAnswer('Risposta sbagliata'),
  badFormat('Formattata male'),
  other('Altro');

  final String label;

  const ReportReason(this.label);
}
