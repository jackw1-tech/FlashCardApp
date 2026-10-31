import 'package:flashcard/mappers/auth_user_mapper.dart';
import 'package:flashcard/model/entities/auth_user.dart';
import 'package:flashcard/network/dto/session_dto.dart';
import 'package:flashcard/network/interceptor/csrf_interceptor.dart';
import 'package:flashcard/network/interceptor/read_source_interceptor.dart';
import 'package:flashcard/network/service/impl/read_source_service_impl.dart';
import 'package:flashcard/network/service/read_source_service.dart';
import 'package:flashcard/repositories/impl/read_source_repository_impl.dart';
import 'package:flashcard/repositories/read_source_repository.dart';
import 'package:flashcard/state_management/cubits/read_source_cubit/read_source_cubit.dart';
import 'package:flashcard/network/interceptor/session_interceptor.dart';
import 'package:flashcard/network/interceptor/session_refresher.dart';
import 'package:flashcard/network/platform/platform_client.dart';
import 'package:flashcard/network/service/auth_service.dart';
import 'package:flashcard/network/service/impl/auth_service_impl.dart';
import 'package:flashcard/network/service/impl/local_store_service_impl.dart';
import 'package:flashcard/network/service/impl/prefetch_service_impl.dart';
import 'package:flashcard/network/service/local_store_service.dart';
import 'package:flashcard/network/service/prefetch_service.dart';
import 'package:flashcard/repositories/auth_repository.dart';
import 'package:flashcard/repositories/impl/auth_repository_impl.dart';
import 'package:flashcard/state_management/cubits/auth_cubit/auth_cubit.dart';
import 'package:flashcard/mappers/app_settings_mapper.dart';
import 'package:flashcard/mappers/conversation_mapper.dart';
import 'package:flashcard/mappers/conversation_summary_mapper.dart';
import 'package:flashcard/mappers/temporary_deck_mapper.dart';
import 'package:flashcard/mappers/vault_sync_report_mapper.dart';
import 'package:flashcard/mappers/session_draft_mapper.dart';
import 'package:flashcard/mappers/saved_session_mapper.dart';
import 'package:flashcard/model/entities/session_draft.dart';
import 'package:flashcard/model/entities/saved_session.dart';
import 'package:flashcard/network/dto/session_request_dto.dart';
import 'package:flashcard/network/dto/saved_session_dto.dart';
import 'package:flashcard/model/entities/temporary_deck.dart';
import 'package:flashcard/model/entities/vault_sync_report.dart';
import 'package:flashcard/network/dto/temporary_deck_dto.dart';
import 'package:flashcard/network/dto/vault_sync_report_dto.dart';
import 'package:flashcard/state_management/cubits/temporary_decks_cubit/temporary_decks_cubit.dart';
import 'package:flashcard/model/entities/conversation.dart';
import 'package:flashcard/model/entities/conversation_summary.dart';
import 'package:flashcard/network/dto/conversation_dto.dart';
import 'package:flashcard/network/dto/conversation_summary_dto.dart';
import 'package:flashcard/network/service/chat_service.dart';
import 'package:flashcard/network/service/impl/chat_service_impl.dart';
import 'package:flashcard/repositories/chat_repository.dart';
import 'package:flashcard/repositories/impl/chat_repository_impl.dart';
import 'package:flashcard/mappers/card_report_mapper.dart';
import 'package:flashcard/mappers/decks_overview_mapper.dart';
import 'package:flashcard/mappers/note_summary_mapper.dart';
import 'package:flashcard/mappers/report_draft_mapper.dart';
import 'package:flashcard/mappers/review_answer_mapper.dart';
import 'package:flashcard/mappers/review_mapper.dart';
import 'package:flashcard/mappers/study_card_mapper.dart';
import 'package:flashcard/mappers/study_stats_mapper.dart';
import 'package:flashcard/model/entities/app_settings.dart';
import 'package:flashcard/model/entities/card_report.dart';
import 'package:flashcard/model/entities/decks_overview.dart';
import 'package:flashcard/model/entities/note_summary.dart';
import 'package:flashcard/model/entities/report_draft.dart';
import 'package:flashcard/model/entities/review.dart';
import 'package:flashcard/model/entities/review_answer.dart';
import 'package:flashcard/model/entities/study_card.dart';
import 'package:flashcard/model/entities/study_stats.dart';
import 'package:flashcard/network/dto/card_dto.dart';
import 'package:flashcard/network/dto/card_report_dto.dart';
import 'package:flashcard/network/dto/decks_overview_dto.dart';
import 'package:flashcard/network/dto/note_summary_dto.dart';
import 'package:flashcard/network/dto/report_request_dto.dart';
import 'package:flashcard/network/dto/review_answer_dto.dart';
import 'package:flashcard/network/dto/review_dto.dart';
import 'package:flashcard/network/dto/settings_dto.dart';
import 'package:flashcard/network/dto/stats_dto.dart';
import 'package:flashcard/network/service/card_service.dart';
import 'package:flashcard/network/service/deck_service.dart';
import 'package:flashcard/network/service/impl/card_service_impl.dart';
import 'package:flashcard/network/service/impl/deck_service_impl.dart';
import 'package:flashcard/network/service/impl/obsidian_service_impl.dart';
import 'package:flashcard/network/service/impl/settings_service_impl.dart';
import 'package:flashcard/network/service/impl/study_service_impl.dart';
import 'package:flashcard/network/service/obsidian_service.dart';
import 'package:flashcard/network/service/settings_service.dart';
import 'package:flashcard/network/service/study_service.dart';
import 'package:flashcard/other/constants/api_constants.dart';
import 'package:flashcard/repositories/card_repository.dart';
import 'package:flashcard/repositories/deck_repository.dart';
import 'package:flashcard/repositories/impl/card_repository_impl.dart';
import 'package:flashcard/repositories/impl/deck_repository_impl.dart';
import 'package:flashcard/repositories/impl/obsidian_repository_impl.dart';
import 'package:flashcard/repositories/impl/settings_repository_impl.dart';
import 'package:flashcard/repositories/impl/study_repository_impl.dart';
import 'package:flashcard/repositories/obsidian_repository.dart';
import 'package:flashcard/repositories/settings_repository.dart';
import 'package:flashcard/repositories/study_repository.dart';
import 'package:flashcard/state_management/cubits/card_actions_cubit/card_actions_cubit.dart';
import 'package:flashcard/state_management/cubits/decks_cubit/decks_cubit.dart';
import 'package:flashcard/state_management/cubits/settings_cubit/settings_cubit.dart';
import 'package:flashcard/state_management/cubits/stats_cubit/stats_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:pine/pine.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

part 'blocs.dart';
part 'mappers.dart';
part 'providers.dart';
part 'repositories.dart';

class DependencyInjector extends StatelessWidget {
  final Widget child;

  const DependencyInjector({required this.child, super.key});

  @override
  Widget build(BuildContext context) => DependencyInjectorHelper(
    blocs: blocs,
    mappers: _mappers,
    repositories: repositories,
    providers: _providers,
    child: child,
  );
}
