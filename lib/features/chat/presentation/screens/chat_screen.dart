import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../books/presentation/providers/book_shelf_provider.dart';
import '../../domain/models/chat_message.dart';
import '../../domain/models/chat_metadata.dart';
import '../../../auth/presentation/screens/public_profile_screen.dart';
import '../../../../features/ratings/presentation/screens/rate_exchange_screen.dart';
import '../../../../features/ratings/presentation/providers/rating_provider.dart';
import '../../../../features/swaps/presentation/providers/swap_provider.dart';
import '../components/chat_components.dart';

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
  String? _otherUserPhotoUrl;
  StreamSubscription? _messagesSubscription;

  late final Stream<ChatMetadata?> _metaStream;
  late final Stream<List<ChatMessage>> _messagesStream;

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

    // Initial markRead
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
      if (mounted) {
        setState(() => _otherUserPhotoUrl = info['photoUrl']);
      }
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
    await _chatProvider.sendText(swapId: widget.swapId, text: text);
  }

  void _showCounterOfferSheet({required String bookWantedId}) {
    final shelfBooks = context.read<BookShelfProvider>().availableBooks;
    final currentUid = context.read<AuthProvider>().user?.uid ?? '';

    if (shelfBooks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'You have no available books to offer. Books reserved for other swaps are hidden.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 10),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                'Which book do you want to offer?',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            const Divider(height: 1),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.45,
              ),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: shelfBooks.length,
                itemBuilder: (ctx, index) {
                  final offeredBook = shelfBooks[index];
                  return ListTile(
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: offeredBook.coverUrl != null
                          ? Image.network(
                        offeredBook.coverUrl!,
                        width: 36,
                        height: 52,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.book, size: 36),
                      )
                          : const Icon(Icons.book, size: 36),
                    ),
                    title: Text(
                      offeredBook.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    subtitle: Text(offeredBook.condition.label),
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
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUid = context.read<AuthProvider>().user?.uid ?? '';

    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PublicProfileScreen(
                userId: widget.otherUserId,
                displayName: widget.otherUserName,
              ),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 16,
                backgroundImage: _otherUserPhotoUrl != null
                    ? NetworkImage(_otherUserPhotoUrl!)
                    : null,
                child: _otherUserPhotoUrl == null
                    ? Text(
                  widget.otherUserName.isNotEmpty
                      ? widget.otherUserName[0].toUpperCase()
                      : '?',
                  style: const TextStyle(fontSize: 13),
                )
                    : null,
              ),
              const SizedBox(width: 8),
              Text(
                widget.otherUserName,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right,
                size: 16,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.4),
              ),
            ],
          ),
        ),
      ),
      body: StreamBuilder<ChatMetadata?>(
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
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final messages = snapshot.data ?? [];

                    if (messages.isEmpty) {
                      return const Center(
                        child: Text(
                          'No messages yet.\nStart the conversation! 📚',
                          textAlign: TextAlign.center,
                        ),
                      );
                    }

                    return ListView.builder(
                      reverse: true,
                      padding: const EdgeInsets.all(16),
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
                            bookWantedId: message.bookOfferedId ?? '',
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              if (typingUids.isNotEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
    );
  }

  Widget _buildInputArea(
      BuildContext context, ChatStatus status, String currentUid) {
    if (status == ChatStatus.completed) {
      return FutureBuilder<bool>(
        future: _hasRatedFuture,
        builder: (context, ratingSnap) {
          final hasRated = ratingSnap.data ?? false;

          return Container(
            padding: const EdgeInsets.all(16),
            width: double.infinity,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(
                top: BorderSide(
                  color: Theme.of(context)
                      .colorScheme
                      .outline
                      .withValues(alpha: 0.2),
                ),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      color: Colors.green.shade700,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Exchange was a success!',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: Colors.green.shade700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  hasRated
                      ? 'You have already rated this exchange. Thank you!'
                      : 'The books have been exchanged. You can now rate this swap.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (!hasRated) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
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
                        if (mounted) {
                          setState(() {
                            _hasRatedFuture = context
                                .read<RatingProvider>()
                                .hasRated(widget.swapId, currentUid);
                          });
                        }
                      },
                      icon: const Icon(Icons.star),
                      label: const Text('Rate this exchange'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      );
    }

    if (status == ChatStatus.accepted) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            width: double.infinity,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              border: Border(
                top: BorderSide(
                  color: Theme.of(context)
                      .colorScheme
                      .outline
                      .withValues(alpha: 0.2),
                ),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Books are reserved for this swap.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Use this chat to arrange where and when to meet. Only complete the exchange after both people have physically traded the books.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: context.watch<SwapProvider>().isLoading
                        ? null
                        : () async {
                      try {
                        await context
                            .read<SwapProvider>()
                            .completePhysicalExchange(widget.swapId);

                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Exchange completed!'),
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                e.toString().replaceAll('Exception: ', ''),
                              ),
                              backgroundColor:
                              Theme.of(context).colorScheme.error,
                            ),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.handshake_outlined),
                    label: const Text('Mark exchange as completed'),
                  ),
                ),
              ],
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
      return Container(
        padding: const EdgeInsets.all(16),
        color: Theme.of(context).colorScheme.errorContainer,
        child: Center(
          child: Text(
            'This swap request was rejected.',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onErrorContainer),
          ),
        ),
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