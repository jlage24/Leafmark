import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rxdart/rxdart.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/models/chat_metadata.dart';
import '../providers/chat_provider.dart';
import 'chat_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  late final Stream<List<ChatMetadata>> _chatsStream;

  @override
  void initState() {
    super.initState();
    _chatsStream = context.read<ChatProvider>().getChats().shareValue();
  }

  @override
  Widget build(BuildContext context) {
    final currentUid = context.read<AuthProvider>().user?.uid ?? '';

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const _ChatsHeader(),
            Expanded(
              child: StreamBuilder<List<ChatMetadata>>(
                stream: _chatsStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const _ChatsLoadingState();
                  }

                  if (snapshot.hasError) {
                    return const _ChatsMessageState(
                      icon: Icons.error_outline_rounded,
                      title: 'Could not load chats',
                      message: 'Something went wrong. Please try again later.',
                    );
                  }

                  final chats = snapshot.data ?? [];

                  if (chats.isEmpty) {
                    return const _ChatsMessageState(
                      icon: Icons.forum_outlined,
                      title: 'No chats yet',
                      message: 'Propose a swap to start a conversation.',
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.only(bottom: 16),
                    itemCount: chats.length,
                    itemBuilder: (context, index) {
                      final chat = chats[index];
                      final otherUid = chat.participantIds.firstWhere(
                        (id) => id != currentUid,
                        orElse: () => '',
                      );

                      return _ChatTile(
                        key: ValueKey(chat.swapId),
                        chat: chat,
                        otherUid: otherUid,
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatsHeader extends StatelessWidget {
  const _ChatsHeader();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 14),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(
              Icons.forum_rounded,
              color: theme.colorScheme.primary,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Chats',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Manage your book swap conversations.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.62),
                  ),
                ),
              ],
            ),
          ),
        ],
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
    final info = await context.read<ChatProvider>().fetchUserInfo(
      widget.otherUid,
    );

    if (!mounted) return;

    setState(() {
      _displayName = info['displayName'];
      _photoUrl = info['photoUrl'];
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = _displayName ?? widget.otherUid;
    final lastMessage = widget.chat.lastMessage ?? 'Swap proposal';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
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
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                _ChatAvatar(name: name, photoUrl: _photoUrl),
                const SizedBox(width: 14),
                Expanded(
                  child: _ChatPreview(name: name, lastMessage: lastMessage),
                ),
                const SizedBox(width: 10),
                _ChatTrailing(time: widget.chat.lastMessageAt),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ChatAvatar extends StatelessWidget {
  final String name;
  final String? photoUrl;

  const _ChatAvatar({required this.name, required this.photoUrl});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: theme.colorScheme.primaryContainer,
      ),
      child: ClipOval(
        child: photoUrl != null && photoUrl!.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: photoUrl!,
                fit: BoxFit.cover,
                errorWidget: (context, url, error) =>
                    _AvatarInitial(initial: initial),
              )
            : _AvatarInitial(initial: initial),
      ),
    );
  }
}

class _AvatarInitial extends StatelessWidget {
  final String initial;

  const _AvatarInitial({required this.initial});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Text(
        initial,
        style: theme.textTheme.titleMedium?.copyWith(
          color: theme.colorScheme.onPrimaryContainer,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _ChatPreview extends StatelessWidget {
  final String name;
  final String lastMessage;

  const _ChatPreview({required this.name, required this.lastMessage});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          lastMessage,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.58),
          ),
        ),
      ],
    );
  }
}

class _ChatTrailing extends StatelessWidget {
  final DateTime? time;

  const _ChatTrailing({required this.time});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (time == null) {
      return Icon(
        Icons.chevron_right_rounded,
        color: theme.colorScheme.onSurface.withValues(alpha: 0.35),
      );
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          _formatTime(time!),
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.48),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Icon(
          Icons.chevron_right_rounded,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.32),
          size: 22,
        ),
      ],
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();

    if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
      final h = dt.hour.toString().padLeft(2, '0');
      final m = dt.minute.toString().padLeft(2, '0');

      return '$h:$m';
    }

    return '${dt.day}/${dt.month}';
  }
}

class _ChatsLoadingState extends StatelessWidget {
  const _ChatsLoadingState();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 16),
      itemCount: 5,
      itemBuilder: (context, index) {
        return const _LoadingChatCard();
      },
    );
  }
}

class _LoadingChatCard extends StatelessWidget {
  const _LoadingChatCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final baseColor = theme.colorScheme.onSurface.withValues(alpha: 0.08);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(color: baseColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                _LoadingLine(widthFactor: 0.48),
                SizedBox(height: 10),
                _LoadingLine(widthFactor: 0.76),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingLine extends StatelessWidget {
  final double widthFactor;

  const _LoadingLine({required this.widthFactor});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FractionallySizedBox(
      widthFactor: widthFactor,
      alignment: Alignment.centerLeft,
      child: Container(
        height: 12,
        decoration: BoxDecoration(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(99),
        ),
      ),
    );
  }
}

class _ChatsMessageState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _ChatsMessageState({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 38, color: theme.colorScheme.primary),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.62),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
