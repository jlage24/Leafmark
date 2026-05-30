import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/presentation/screens/public_profile_screen.dart';
import '../../../books/presentation/providers/book_shelf_provider.dart';
import '../../../ratings/presentation/providers/rating_provider.dart';
import '../../../ratings/presentation/screens/rate_exchange_screen.dart';
import '../../../swaps/presentation/providers/swap_provider.dart';
import '../../domain/models/chat_message.dart';
import '../../domain/models/chat_metadata.dart';
import '../components/chat_components.dart';
import '../providers/chat_provider.dart';

class ChatScreen extends StatefulWidget {
  final String swapId;
  final String otherUserName;
  final String otherUserId;

  const ChatScreen({
    super.key,
    required this.swapId,
    required this.otherUserName,
    required this.otherUserId,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with WidgetsBindingObserver {
  final _controller = TextEditingController();

  late final ChatProvider _chatProvider;
  late Future<bool> _hasRatedFuture;
  late final Stream<ChatMetadata?> _metaStream;
  late final Stream<List<ChatMessage>> _messagesStream;

  String? _otherUserPhotoUrl;
  StreamSubscription? _messagesSubscription;

  @override
  void initState() {
    super.initState();

    _chatProvider = context.read<ChatProvider>();
    final currentUid = context.read<AuthProvider>().user?.uid ?? '';

    _hasRatedFuture =
        context.read<RatingProvider>().hasRated(widget.swapId, currentUid);

    _metaStream = _chatProvider.chatStream(widget.swapId);
    _messagesStream = _chatProvider.getMessages(widget.swapId);

    WidgetsBinding.instance.addObserver(this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _chatProvider.markRead(widget.swapId);
    });

    _loadOtherUserPhoto();

    _messagesSubscription = _messagesStream.listen((messages) {
      if (mounted && messages.isNotEmpty) {
        _chatProvider.markRead(widget.swapId);
      }
    });
  }

  Future<void> _loadOtherUserPhoto() async {
    try {
      final info = await _chatProvider.fetchUserInfo(widget.otherUserId);

      if (!mounted) return;

      setState(() {
        _otherUserPhotoUrl = info['photoUrl'];
      });
    } catch (e) {
      debugPrint('Error loading user photo: $e');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _chatProvider.markRead(widget.swapId);
    }
  }

  @override
  void dispose() {
    _messagesSubscription?.cancel();
    _chatProvider.stopTyping(widget.swapId);
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  Future<void> _sendText() async {
    final text = _controller.text.trim();

    if (text.isEmpty) return;

    _controller.clear();

    await _chatProvider.sendText(
      swapId: widget.swapId,
      text: text,
    );
  }

  void _openPublicProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PublicProfileScreen(
          userId: widget.otherUserId,
          displayName: widget.otherUserName,
        ),
      ),
    );
  }

  void _showCounterOfferSheet({required String bookWantedId}) {
    final shelfBooks = context.read<BookShelfProvider>().availableBooks;
    final currentUid = context.read<AuthProvider>().user?.uid ?? '';

    if (shelfBooks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'You have no available books to offer. Books reserved for other swaps are hidden.',
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetCtx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Choose a counter-offer',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Pick one of your available books to offer instead.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.62),
                  ),
                ),
                const SizedBox(height: 16),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.46,
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: shelfBooks.length,
                    separatorBuilder: (ctx, index) => const SizedBox(height: 8),
                    itemBuilder: (ctx, index) {
                      final offeredBook = shelfBooks[index];

                      return _CounterOfferBookTile(
                        title: offeredBook.title,
                        subtitle: offeredBook.condition.label,
                        coverUrl: offeredBook.coverUrl,
                        onTap: () async {
                          Navigator.pop(sheetCtx);

                          await _chatProvider.sendCounterOffer(
                            swapId: widget.swapId,
                            bookOfferedId: offeredBook.id,
                            bookOfferedOwnerId: currentUid,
                            bookWantedId: bookWantedId,
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
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUid = context.read<AuthProvider>().user?.uid ?? '';
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            _ChatHeader(
              name: widget.otherUserName,
              photoUrl: _otherUserPhotoUrl,
              onBack: () => Navigator.pop(context),
              onProfileTap: _openPublicProfile,
            ),
            Expanded(
              child: StreamBuilder<ChatMetadata?>(
                stream: _metaStream,
                builder: (context, metaSnap) {
                  final meta = metaSnap.data;
                  final status = meta?.status ?? ChatStatus.active;
                  final otherLastRead = meta?.lastReadAt[widget.otherUserId];
                  final typingUids = (meta?.typingUids ?? [])
                      .where((uid) => uid != currentUid)
                      .toList();

                  return Column(
                    children: [
                      Expanded(
                        child: StreamBuilder<List<ChatMessage>>(
                          stream: _messagesStream,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const _ChatLoadingState();
                            }

                            final messages = snapshot.data ?? [];

                            if (messages.isEmpty) {
                              return const _EmptyChatState();
                            }

                            return ListView.builder(
                              reverse: true,
                              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                              itemCount: messages.length,
                              itemBuilder: (context, index) {
                                final message = messages[index];
                                final isMe = message.senderId == currentUid;
                                final isLast = index == 0;
                                final isSeen = isMe &&
                                    isLast &&
                                    otherLastRead != null &&
                                    otherLastRead.isAfter(message.createdAt);

                                if (message.type == MessageType.text) {
                                  return TextBubble(
                                    message: message,
                                    isMe: isMe,
                                    showSeen: isSeen,
                                  );
                                }

                                return ProposalCard(
                                  message: message,
                                  isMe: isMe,
                                  swapId: widget.swapId,
                                  currentUid: currentUid,
                                  otherUserId: widget.otherUserId,
                                  chatStatus: status,
                                  onCounter: isMe
                                      ? null
                                      : () => _showCounterOfferSheet(
                                    bookWantedId:
                                    message.bookOfferedId ?? '',
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                      if (typingUids.isNotEmpty)
                        const Padding(
                          padding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: TypingIndicator(),
                          ),
                        ),
                      _buildInputArea(context, status, currentUid),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea(
      BuildContext context,
      ChatStatus status,
      String currentUid,
      ) {
    final theme = Theme.of(context);

    if (status == ChatStatus.completed) {
      return FutureBuilder<bool>(
        future: _hasRatedFuture,
        builder: (context, ratingSnap) {
          final hasRated = ratingSnap.data ?? false;

          return _StatusPanel(
            icon: Icons.check_circle_outline_rounded,
            iconColor: Colors.green.shade700,
            title: 'Exchange completed',
            message: hasRated
                ? 'You have already rated this exchange. Thank you!'
                : 'The books have been exchanged. You can now rate this swap.',
            action: hasRated
                ? null
                : FilledButton.icon(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => RateExchangeScreen(
                      swapId: widget.swapId,
                      revieweeId: widget.otherUserId,
                    ),
                  ),
                );

                if (!mounted) return;

                setState(() {
                  _hasRatedFuture = context
                      .read<RatingProvider>()
                      .hasRated(widget.swapId, currentUid);
                });
              },
              icon: const Icon(Icons.star_rounded),
              label: const Text('Rate this exchange'),
            ),
          );
        },
      );
    }

    if (status == ChatStatus.accepted) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StatusPanel(
            icon: Icons.handshake_outlined,
            iconColor: theme.colorScheme.primary,
            title: 'Books are reserved',
            message:
            'Use this chat to arrange where and when to meet. Only complete the exchange after both people have physically traded the books.',
            action: FilledButton.icon(
              onPressed: context.watch<SwapProvider>().isLoading
                  ? null
                  : () async {
                try {
                  await context
                      .read<SwapProvider>()
                      .completePhysicalExchange(widget.swapId);

                  if (!context.mounted) return;

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Exchange completed!'),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  );
                } catch (e) {
                  if (!context.mounted) return;

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        e.toString().replaceAll('Exception: ', ''),
                      ),
                      backgroundColor: theme.colorScheme.error,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.done_all_rounded),
              label: const Text('Mark as completed'),
            ),
          ),
          ChatInputBar(
            controller: _controller,
            onChanged: () => _chatProvider.onTyping(widget.swapId),
            onSend: _sendText,
            onCounterOffer: null,
          ),
        ],
      );
    }

    if (status == ChatStatus.cancelled) {
      return _StatusPanel(
        icon: Icons.cancel_outlined,
        iconColor: theme.colorScheme.error,
        title: 'Swap rejected',
        message: 'This swap request was rejected.',
      );
    }

    return ChatInputBar(
      controller: _controller,
      onChanged: () => _chatProvider.onTyping(widget.swapId),
      onSend: _sendText,
      onCounterOffer: null,
    );
  }
}

class _ChatHeader extends StatelessWidget {
  final String name;
  final String? photoUrl;
  final VoidCallback onBack;
  final VoidCallback onProfileTap;

  const _ChatHeader({
    required this.name,
    required this.photoUrl,
    required this.onBack,
    required this.onProfileTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.12),
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          Expanded(
            child: InkWell(
              onTap: onProfileTap,
              borderRadius: BorderRadius.circular(18),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 21,
                      backgroundColor: theme.colorScheme.primaryContainer,
                      backgroundImage: photoUrl != null && photoUrl!.isNotEmpty
                          ? NetworkImage(photoUrl!)
                          : null,
                      child: photoUrl == null || photoUrl!.isEmpty
                          ? Text(
                        initial,
                        style: TextStyle(
                          color: theme.colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.w900,
                        ),
                      )
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.38),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CounterOfferBookTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? coverUrl;
  final VoidCallback onTap;

  const _CounterOfferBookTile({
    required this.title,
    required this.subtitle,
    required this.coverUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.55),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: 44,
                  height: 62,
                  color: theme.colorScheme.primary.withValues(alpha: 0.08),
                  child: coverUrl != null && coverUrl!.isNotEmpty
                      ? Image.network(
                    coverUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Icon(
                      Icons.menu_book_rounded,
                      color: theme.colorScheme.primary,
                    ),
                  )
                      : Icon(
                    Icons.menu_book_rounded,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.62,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.36),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusPanel extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String message;
  final Widget? action;

  const _StatusPanel({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.message,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.14),
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: iconColor, size: 24),
          const SizedBox(height: 6),
          Text(
            title,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.62),
            ),
          ),
          if (action != null) ...[
            const SizedBox(height: 12),
            SizedBox(width: double.infinity, child: action!),
          ],
        ],
      ),
    );
  }
}

class _EmptyChatState extends StatelessWidget {
  const _EmptyChatState();

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
              width: 78,
              height: 78,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.chat_bubble_outline_rounded,
                size: 38,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'No messages yet',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start the conversation and arrange your book swap.',
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

class _ChatLoadingState extends StatelessWidget {
  const _ChatLoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(strokeWidth: 2),
    );
  }
}