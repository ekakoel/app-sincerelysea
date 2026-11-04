import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/format.dart';
import '../../core/widgets.dart';
import '../../data/local_store.dart';
import '../auth/auth_pages.dart';

class MessagesPage extends StatelessWidget {
  const MessagesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<LocalAppStore>();
    final user = store.session;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Messages')),
        body: AppEmptyState(
          title: 'Sign in',
          body: 'Conversations are visible only to their participants.',
        ),
      );
    }
    final conversations = store.conversationsFor(user.id);
    return Scaffold(
      appBar: AppBar(title: const Text('Messages')),
      body: conversations.isEmpty
          ? const AppEmptyState(
              title: 'No conversations',
              body: 'Messages from members you can reach will appear here.',
            )
          : ListView(
              children: [
                for (final conversation in conversations)
                  ListTile(
                    title: Text(_title(store, conversation, user.id)),
                    subtitle: Text(
                      conversation.messages.isEmpty
                          ? 'No messages'
                          : conversation.messages.last.body,
                    ),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) =>
                            ThreadPage(conversationId: conversation.id),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }

  String _title(LocalAppStore store, Conversation conversation, String userId) {
    final other = conversation.participantIds.where((id) => id != userId);
    if (other.isEmpty) return 'Conversation';
    return store.userById(other.first)?.displayName ?? 'Member';
  }
}

class ThreadPage extends StatefulWidget {
  const ThreadPage({super.key, required this.conversationId});

  final String conversationId;

  @override
  State<ThreadPage> createState() => _ThreadPageState();
}

class _ThreadPageState extends State<ThreadPage> {
  final _body = TextEditingController();
  var _marked = false;

  @override
  void dispose() {
    _body.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<LocalAppStore>();
    final user = store.session;
    final conversation = store.conversations.cast<Conversation?>().firstWhere(
      (item) => item!.id == widget.conversationId,
      orElse: () => null,
    );
    if (user == null ||
        conversation == null ||
        !conversation.participantIds.contains(user.id)) {
      return Scaffold(
        appBar: AppBar(),
        body: const AppEmptyState(
          title: 'Private',
          body: 'This conversation is not available to you.',
        ),
      );
    }
    if (!_marked) {
      _marked = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        runStore(
          context,
          () => context.read<LocalAppStore>().markConversationRead(
            widget.conversationId,
          ),
        );
      });
    }
    final otherId = conversation.participantIds.firstWhere(
      (id) => id != user.id,
      orElse: () => user.id,
    );
    return Scaffold(
      appBar: AppBar(
        title: Text(store.userById(otherId)?.displayName ?? 'Message'),
        actions: [
          if (otherId != user.id)
            IconButton(
              tooltip: 'Block',
              onPressed: () {
                final ok = runStore(context, () => store.blockUser(otherId));
                if (ok && context.mounted) {
                  showAppFeedback(context, 'Member blocked.');
                }
              },
              icon: const Icon(Icons.block),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                for (final message in conversation.messages)
                  Align(
                    alignment: message.senderId == user.id
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(message.body),
                            Text(
                              '${relativeTime(message.sentAt)} · ${message.read ? 'read' : 'sent'}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Row(
              children: [
                Expanded(
                  child: AppTextField(label: 'Message', controller: _body),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () {
                    final ok = runStore(
                      context,
                      () => store.sendMessage(conversation.id, _body.text),
                    );
                    if (ok) _body.clear();
                  },
                  icon: const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

void openMessages(BuildContext context) {
  if (context.read<LocalAppStore>().session == null) {
    openLogin(context);
    return;
  }
  Navigator.of(context)
      .push(MaterialPageRoute<void>(builder: (_) => const MessagesPage()));
}
