part of 'dependency_injector.dart';

final List<SingleChildWidget> _mappers = [
  Provider<DTOMapper<SessionUserDTO, AuthUser>>(
    create: (_) => const AuthUserMapper(),
  ),
  Provider<DTOMapper<DecksOverviewDTO, DecksOverview>>(
    create: (_) => const DecksOverviewMapper(),
  ),
  Provider<DTOMapper<NoteSummaryDTO, NoteSummary>>(
    create: (_) => const NoteSummaryMapper(),
  ),
  Provider<DTOMapper<CardDTO, StudyCard>>(
    create: (_) => const StudyCardMapper(),
  ),
  Provider<DTOMapper<ReviewAnswerDTO, ReviewAnswer>>(
    create: (_) => const ReviewAnswerMapper(),
  ),
  Provider<DTOMapper<ReviewDTO, Review>>(create: (_) => const ReviewMapper()),
  Provider<DTOMapper<StatsDTO, StudyStats>>(
    create: (_) => const StudyStatsMapper(),
  ),
  Provider<DTOMapper<CardReportDTO, CardReport>>(
    create: (_) => const CardReportMapper(),
  ),
  Provider<DTOMapper<ReportRequestDTO, ReportDraft>>(
    create: (_) => const ReportDraftMapper(),
  ),
  Provider<DTOMapper<ConversationDTO, Conversation>>(
    create: (_) => const ConversationMapper(),
  ),
  Provider<DTOMapper<ConversationSummaryDTO, ConversationSummary>>(
    create: (_) => const ConversationSummaryMapper(),
  ),
  Provider<DTOMapper<TemporaryDeckDTO, TemporaryDeck>>(
    create: (_) => const TemporaryDeckMapper(),
  ),
  Provider<DTOMapper<VaultSyncReportDTO, VaultSyncReport>>(
    create: (_) => const VaultSyncReportMapper(),
  ),
  Provider<DTOMapper<SessionRequestDTO, SessionDraft>>(
    create: (_) => const SessionDraftMapper(),
  ),
  Provider<DTOMapper<SavedSessionDTO, SavedSession>>(
    create: (_) => const SavedSessionMapper(),
  ),
  Provider<DTOMapper<SettingsDTO, AppSettings>>(
    create: (_) => const AppSettingsMapper(),
  ),
];
