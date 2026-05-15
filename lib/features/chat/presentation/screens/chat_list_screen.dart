import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/models/chat_metadata.dart';
import 'chat_screen.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final chatProvider = context.read<ChatProvider>();
    final currentUid = context.read<AuthProvider>().user?.uid ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text('Chats')),
      body: StreamBuilder<List<ChatMetadata>>(
        stream: chatProvider.getChats(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final chats = snapshot.data ?? [];

          if (chats.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 64,
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.4),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No chats yet',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Propose a swap to start a conversation.',
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: chats.length,
            separatorBuilder: (context, index) =>
            const Divider(height: 1, indent: 72),
            itemBuilder: (context, index) {
              final chat = chats[index];
              final otherUid = chat.participantIds
                  .firstWhere((id) => id != currentUid, orElse: () => '');
              return _ChatTile(
                key: ValueKey(chat.swapId),
                chat: chat,
                otherUid: otherUid,
              );
            },
          );
        },
      ),
    );
  }
}

class _ChatTile extends StatefulWidget {
  final ChatMetadata chat;
  final String otherUid;

  const _ChatTile({super.key, required this.chat, required this.otherUid});

  @override
  State<_ChatTile> createState() => _ChatTileState();
}

class _ChatTileState extends State<_ChatTile> {
  String? _displayName;
  String? _photoUrl;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  @override
  void didUpdateWidget(_ChatTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.otherUid != widget.otherUid) {
      _displayName = null;
      _photoUrl = null;
      _loadUserInfo();
    }
  }

  Future<void> _loadUserInfo() async {
    final info = await context
        .read<ChatProvider>()
        .fetchUserInfo(widget.otherUid);
    if (mounted) {
      setState(() {
        _displayName = info['displayName'];
        _photoUrl = info['photoUrl'];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final name = _displayName ?? widget.otherUid;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: colorScheme.primaryContainer,
        backgroundImage:
        _photoUrl != null ? NetworkImage(_photoUrl!) : null,
        child: _photoUrl == null
            ? Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: TextStyle(
            color: colorScheme.onPrimaryContainer,
            fontWeight: FontWeight.bold,
          ),
        )
            : null,
      ),
      title: Text(
        name,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        widget.chat.lastMessage ?? 'Swap proposal',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style:
        TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.6)),
      ),
      trailing: widget.chat.lastMessageAt != null
          ? Text(
        _formatTime(widget.chat.lastMessageAt!),
        style: TextStyle(
          fontSize: 11,
          color: colorScheme.onSurface.withValues(alpha: 0.5),
        ),
      )
          : null,
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            swapId: widget.chat.swapId,
            otherUserName: name,
            otherUserId: widget.otherUid,
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    if (dt.year == now.year &&
        dt.month == now.month &&
        dt.day == now.day) {
      final h = dt.hour.toString().padLeft(2, '0');
      final m = dt.minute.toString().padLeft(2, '0');
      return '$h:$m';
    }
    return '${dt.day}/${dt.month}';
  }
}