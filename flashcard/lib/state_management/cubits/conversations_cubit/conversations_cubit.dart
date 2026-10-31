import 'package:flashcard/model/app_failure.dart';
import 'package:flashcard/model/entities/conversation_summary.dart';
import 'package:flashcard/repositories/chat_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'conversations_cubit_state.dart';

class ConversationsCubit extends Cubit<ConversationsState> {
  final ChatRepository repository;

  ConversationsCubit({required this.repository})
    : super(const LoadingConversationsState());

  Future<void> fetch() async {
    emit(const LoadingConversationsState());
    try {
      emit(LoadedConversationsState(await repository.conversations()));
    } on AppFailure catch (failure) {
      emit(ErrorConversationsState(failure.message));
    }
  }

  Future<void> delete(String id) async {
    final current = state;
    if (current is! LoadedConversationsState) return;
    emit(
      LoadedConversationsState([
        for (final c in current.conversations)
          if (c.id != id) c,
      ]),
    );
    try {
      await repository.delete(id);
    } on AppFailure {
      emit(current);
    }
  }
}
