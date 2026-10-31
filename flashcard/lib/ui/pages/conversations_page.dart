import 'package:auto_route/auto_route.dart';
import 'package:flashcard/model/entities/conversation.dart';
import 'package:flashcard/model/entities/conversation_summary.dart';
import 'package:flashcard/routers/app_router.dart';
import 'package:flashcard/state_management/cubits/conversations_cubit/conversations_cubit.dart';
import 'package:flashcard/theme/app_colors.dart';
import 'package:flashcard/theme/app_text_styles.dart';
import 'package:flashcard/theme/dimensions.dart';
import 'package:flashcard/ui/widgets/content_width.dart';
import 'package:flashcard/ui/widgets/error_view.dart';
import 'package:flashcard/utils/date_time_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

@RoutePage()
class ConversationsPage extends StatelessWidget {
  const ConversationsPage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (context) =>
        ConversationsCubit(repository: context.read())..fetch(),
    child: Builder(
      builder: (context) {
        Future<void> open(String? id) async {
          await context.router.push(ChatRoute(conversationId: id));
          if (context.mounted) await context.read<ConversationsCubit>().fetch();
        }

        return Scaffold(
          appBar: AppBar(title: const Text('Chat di ripasso')),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => open(null),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Nuova chat'),
          ),
          body: ContentWidth(
            maxWidth: Dimensions.readingMaxWidth,
            child: BlocBuilder<ConversationsCubit, ConversationsState>(
              builder: (context, state) => switch (state) {
                LoadingConversationsState() => const Center(
                  child: CircularProgressIndicator(),
                ),
                ErrorConversationsState(:final message) => ErrorView(
                  message: message,
                  onRetry: context.read<ConversationsCubit>().fetch,
                ),
                LoadedConversationsState(:final conversations)
                    when conversations.isEmpty =>
                  Center(
                    child: Text(
                      'Nessuna chat: iniziane una.',
                      style: AppTextStyles.bodySm.copyWith(
                        color: context.colors.muted,
                      ),
                    ),
                  ),
                LoadedConversationsState(:final conversations) =>
                  ListView.separated(
                    padding: const EdgeInsets.fromLTRB(
                      Dimensions.paddingMedium,
                      Dimensions.paddingSmall,
                      Dimensions.paddingMedium,
                      Dimensions.spaceXl * 3,
                    ),
                    itemCount: conversations.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: Dimensions.paddingSmall),
                    itemBuilder: (context, index) => _ConversationTile(
                      conversation: conversations[index],
                      onOpen: () => open(conversations[index].id),
                      onDelete: () => context.read<ConversationsCubit>().delete(
                        conversations[index].id,
                      ),
                    ),
                  ),
              },
            ),
          ),
        );
      },
    ),
  );
}

class _ConversationTile extends StatelessWidget {
  final ConversationSummary conversation;
  final VoidCallback onOpen;
  final VoidCallback onDelete;

  const _ConversationTile({
    required this.conversation,
    required this.onOpen,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final waiting =
        conversation.status == ConversationStatus.waitingConfirmation;
    final when = DateTimeUtils.getRelativeTime(conversation.updatedAt);
    return Card(
      child: ListTile(
        onTap: onOpen,
        leading: const Icon(Icons.chat_bubble_outline_rounded),
        title: Text(
          conversation.title.isEmpty ? 'Chat senza titolo' : conversation.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(waiting ? '$when · da confermare' : when),
        trailing: IconButton(
          tooltip: 'Cancella',
          icon: const Icon(Icons.delete_outline_rounded),
          onPressed: onDelete,
        ),
      ),
    );
  }
}
