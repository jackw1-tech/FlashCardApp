import 'package:auto_route/auto_route.dart';
import 'package:flashcard/model/entities/conversation.dart';
import 'package:flashcard/routers/app_router.dart';
import 'package:flashcard/state_management/cubits/chat_cubit/chat_cubit.dart';
import 'package:flashcard/theme/app_colors.dart';
import 'package:flashcard/theme/app_text_styles.dart';
import 'package:flashcard/theme/dimensions.dart';
import 'package:flashcard/ui/widgets/chat_item_view.dart';
import 'package:flashcard/ui/widgets/content_width.dart';
import 'package:flashcard/ui/widgets/error_view.dart';
import 'package:flashcard/ui/widgets/pending_confirmation_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

@RoutePage()
class ChatPage extends StatelessWidget {
  final String? conversationId;

  const ChatPage({this.conversationId, super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (context) =>
        ChatCubit(repository: context.read(), conversationId: conversationId)
          ..load(),
    child: BlocListener<ChatCubit, ChatState>(
      listenWhen: (_, state) =>
          state is ShowingChatState && state.notice != null,
      listener: (context, state) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text((state as ShowingChatState).notice!)),
      ),
      child: Scaffold(
        appBar: AppBar(
          title: BlocSelector<ChatCubit, ChatState, String>(
            selector: (state) => switch (state) {
              ShowingChatState(:final conversation)
                  when conversation.title.isNotEmpty =>
                conversation.title,
              _ => 'Nuova chat',
            },
            builder: (_, title) => Text(title),
          ),
        ),
        body: ContentWidth(
          maxWidth: Dimensions.readingMaxWidth,
          child: BlocBuilder<ChatCubit, ChatState>(
            builder: (context, state) => switch (state) {
              LoadingChatState() => const Center(
                child: CircularProgressIndicator(),
              ),
              ErrorChatState(:final message) => ErrorView(
                message: message,
                onRetry: context.read<ChatCubit>().load,
              ),
              ShowingChatState() => _Conversation(state: state),
            },
          ),
        ),
      ),
    ),
  );
}

class _Conversation extends StatelessWidget {
  final ShowingChatState state;

  const _Conversation({required this.state});

  void _study(BuildContext context, ChatItem item) => context.router.push(
    StudyRoute(
      deckName: item.text,
      sessionLength: item.total ?? 0,
      temporaryDeckId: item.temporaryDeckId,
    ),
  );

  @override
  Widget build(BuildContext context) {
    final conversation = state.conversation;
    final pending = conversation.pending;
    final items = conversation.items.reversed.toList();
    final waiting =
        conversation.status == ConversationStatus.waitingConfirmation;
    return Column(
      children: [
        Expanded(
          child: items.isEmpty && !state.working
              ? const _Hint()
              : ListView.separated(
                  reverse: true,
                  padding: const EdgeInsets.all(Dimensions.paddingMedium),
                  itemCount: items.length + (state.working ? 1 : 0),
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: Dimensions.paddingSmall),
                  itemBuilder: (context, index) {
                    if (state.working && index == 0) return const _Thinking();
                    final item = items[index - (state.working ? 1 : 0)];
                    return ChatItemView(
                      item: item,
                      onStudy: item.temporaryDeckId == null
                          ? null
                          : () => _study(context, item),
                    );
                  },
                ),
        ),
        if (pending != null && waiting)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: Dimensions.paddingMedium,
            ),
            child: PendingConfirmationCard(
              pending: pending,
              enabled: !state.working,
              onApprove: () => context.read<ChatCubit>().confirm(approve: true),
              onReject: () => context.read<ChatCubit>().confirm(approve: false),
            ),
          ),
        _Composer(enabled: !state.working && !waiting),
      ],
    );
  }
}

class _Composer extends StatefulWidget {
  final bool enabled;

  const _Composer({required this.enabled});

  @override
  State<_Composer> createState() => _ComposerState();
}

class _ComposerState extends State<_Composer> {
  final _controller = TextEditingController();

  void _send() {
    final text = _controller.text;
    if (text.trim().isEmpty || !widget.enabled) return;
    _controller.clear();
    context.read<ChatCubit>().send(text);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: Padding(
      padding: const EdgeInsets.all(Dimensions.paddingMedium),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              enabled: widget.enabled,
              minLines: 1,
              maxLines: 4,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _send(),
              decoration: const InputDecoration(
                hintText: 'Es. oggi ripasso MCP e Raft, 20 card',
              ),
            ),
          ),
          const SizedBox(width: Dimensions.paddingSmall),
          IconButton.filled(
            tooltip: 'Invia',
            onPressed: widget.enabled ? _send : null,
            icon: const Icon(Icons.arrow_upward_rounded),
          ),
        ],
      ),
    ),
  );
}

class _Thinking extends StatelessWidget {
  const _Thinking();

  @override
  Widget build(BuildContext context) => Row(
    children: [
      const SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
      const SizedBox(width: Dimensions.paddingSmall),
      Text(
        'Sto preparando…',
        style: AppTextStyles.caption.copyWith(color: context.colors.muted),
      ),
    ],
  );
}

class _Hint extends StatelessWidget {
  const _Hint();

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(Dimensions.spaceXl),
      child: Text(
        'Dimmi cosa vuoi ripassare: degli argomenti, le card di oggi o quelle '
        'che hai sbagliato. Preparo un mazzo provvisorio da studiare qui.',
        textAlign: TextAlign.center,
        style: AppTextStyles.bodySm.copyWith(color: context.colors.muted),
      ),
    ),
  );
}
