import 'package:flashcard/model/app_failure.dart';
import 'package:flashcard/model/entities/conversation.dart';
import 'package:flashcard/repositories/chat_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'chat_cubit_state.dart';

class ChatCubit extends Cubit<ChatState> {
  final ChatRepository repository;
  String? conversationId;

  ChatCubit({required this.repository, this.conversationId})
    : super(const LoadingChatState());

  static const Conversation _empty = Conversation(
    id: '',
    title: '',
    status: ConversationStatus.idle,
    items: [],
  );

  Future<void> load() async {
    final id = conversationId;
    if (id == null) {
      emit(const ShowingChatState(_empty));
      return;
    }
    emit(const LoadingChatState());
    try {
      emit(_showing(await repository.fetch(id)));
    } on AppFailure catch (failure) {
      emit(ErrorChatState(failure.message));
    }
  }

  Future<void> send(String text) async {
    final message = text.trim();
    final current = state;
    if (message.isEmpty || current is! ShowingChatState || current.working) {
      return;
    }
    final optimistic = current.conversation.copyWith(
      items: [
        ...current.conversation.items,
        ChatItem(kind: ChatItemKind.user, text: message),
      ],
    );
    emit(ShowingChatState(optimistic, working: true));
    try {
      final id = conversationId ??= (await repository.create()).id;
      emit(_showing(await repository.send(id, message)));
    } on AppFailure catch (failure) {
      emit(ShowingChatState(current.conversation, notice: failure.message));
    }
  }

  Future<void> confirm({required bool approve}) async {
    final current = state;
    final id = conversationId;
    if (id == null || current is! ShowingChatState || current.working) return;
    emit(ShowingChatState(current.conversation, working: true));
    try {
      emit(_showing(await repository.confirm(id, approve: approve)));
    } on AppFailure catch (failure) {
      emit(ShowingChatState(current.conversation, notice: failure.message));
    }
  }

  ShowingChatState _showing(Conversation conversation) =>
      ShowingChatState(conversation, notice: conversation.error);
}
