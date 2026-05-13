import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/chat_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../books/data/services/browse_service.dart';
import '../../../books/domain/models/book.dart';
import '../../../books/presentation/providers/book_shelf_provider.dart';
import '../../data/services/chat_service.dart';
import '../../domain/models/chat_message.dart';
import '../../domain/models/chat_metadata.dart';
import '../../../auth/presentation/screens/public_profile_screen.dart';
import '../../../../features/ratings/presentation/screens/rate_exchange_screen.dart';
import '../../../../features/ratings/presentation/providers/rating_provider.dart';

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
  final _scrollController = ScrollController();
  late final ChatProvider _chatProvider;

  @override
  void initState() {
    super.initState();
    _chatProvider = context.read<ChatProvider>();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _chatProvider.markRead(widget.swapId);
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _chatProvider.markRead(widget.swapId);
    }
  }

  @override
  void dispose() {
    _chatProvider.stopTyping(widget.swapId);
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  bool _isAtBottom() {
    if (!_scrollController.hasClients) return true;
    final pos = _scrollController.position;
    return pos.pixels >= pos.maxScrollExtent - 80;
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendText() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    await context
        .read<ChatProvider>()
        .sendText(swapId: widget.swapId, text: text);
    _scrollToBottom();
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
                      await context.read<ChatProvider>().sendCounterOffer(
                        swapId: widget.swapId,
                        bookOfferedId: offeredBook.id,
                        bookOfferedOwnerId: currentUid,
                        bookWantedId: bookWantedId,
                      );
                      _scrollToBottom();
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

  Widget _buildStandardInputBar(ChatProvider chatProvider) {
    return _InputBar(
      controller: _controller,
      onChanged: () => chatProvider.onTyping(widget.swapId),
      onSend: _sendText,
      onCounterOffer: null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUid = context.read<AuthProvider>().user?.uid ?? '';
    final chatProvider = context.read<ChatProvider>();

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
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<ChatMessage>>(
              stream: chatProvider.getMessages(widget.swapId),
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
                if (_isAtBottom()) _scrollToBottom();

                return StreamBuilder<Map<String, DateTime>>(
                  stream: chatProvider.lastReadStream(widget.swapId),
                  builder: (context, readSnap) {
                    final lastReadAt = readSnap.data ?? {};
                    final otherLastRead =
                    lastReadAt[widget.otherUserId];

                    return ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final message = messages[index];
                        final isMe = message.senderId == currentUid;
                        final isLast = index == messages.length - 1;
                        final isSeen = isMe &&
                            isLast &&
                            otherLastRead != null &&
                            otherLastRead
                                .isAfter(message.createdAt);

                        if (message.type == MessageType.text) {
                          return _TextBubble(
                            message: message,
                            isMe: isMe,
                            showSeen: isSeen,
                          );
                        }

                        return _ProposalCard(
                          message: message,
                          isMe: isMe,
                          swapId: widget.swapId,
                          currentUid: currentUid,
                          otherUserId: widget.otherUserId,
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
                );
              },
            ),
          ),
          StreamBuilder<List<String>>(
            stream: chatProvider.typingStream(widget.swapId),
            builder: (context, snap) {
              final typing = snap.data ?? [];
              if (typing.isEmpty) return const SizedBox.shrink();
              return Padding(
                padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: _TypingIndicator(),
                ),
              );
            },
          ),

          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('chats')
                .doc(widget.swapId)
                .snapshots(),
            builder: (context, chatSnap) {
              if (!chatSnap.hasData || !chatSnap.data!.exists) {
                return _buildStandardInputBar(chatProvider);
              }

              final data = chatSnap.data!.data() as Map<String, dynamic>;
              final status = ChatStatus.values.byName(
                data['status'] as String? ?? 'active',
              );

              if (status == ChatStatus.completed) {
                return FutureBuilder<bool>(
                  future: context.read<RatingProvider>().hasRated(widget.swapId, currentUid),
                  builder: (context, ratingSnap) {
                    final hasRated = ratingSnap.data ?? false;

                    if (hasRated) {
                      return Container(
                        padding: const EdgeInsets.all(16),
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        child: const Center(
                          child: Text(
                            'You have already rated this exchange. Thank you!',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      );
                    }

                    return Container(
                      padding: const EdgeInsets.all(16),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        border: Border(
                          top: BorderSide(
                            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                          ),
                        ),
                      ),
                      child: FilledButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => RateExchangeScreen(
                                swapId: widget.swapId,
                                revieweeId: widget.otherUserId,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.star),
                        label: const Text('Rate this exchange'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    );
                  },
                );
              } else if (status == ChatStatus.cancelled) {
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

              // If active, show the normal text input
              return _buildStandardInputBar(chatProvider);
            },
          ),
        ],
      ),
    );
  }
}

class _TypingIndicator extends StatefulWidget {
  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with TickerProviderStateMixin {
  late final List<AnimationController> _controllers;
  late final List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      3,
          (i) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 400),
      ),
    );
    _animations = _controllers
        .map((c) => Tween<double>(begin: 0, end: -6).animate(
      CurvedAnimation(parent: c, curve: Curves.easeInOut),
    ))
        .toList();

    for (int i = 0; i < 3; i++) {
      Future.delayed(Duration(milliseconds: i * 150), () {
        if (mounted) _controllers[i].repeat(reverse: true);
      });
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
          bottomRight: Radius.circular(16),
          bottomLeft: Radius.circular(4),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (i) {
          return AnimatedBuilder(
            animation: _animations[i],
            builder: (context, child) => Transform.translate(
              offset: Offset(0, _animations[i].value),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _TextBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMe;
  final bool showSeen;

  const _TextBubble({
    required this.message,
    required this.isMe,
    this.showSeen = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment:
      isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Align(
          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.only(bottom: 2),
            padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.72),
            decoration: BoxDecoration(
              color: isMe
                  ? colorScheme.primary
                  : colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(isMe ? 16 : 4),
                bottomRight: Radius.circular(isMe ? 4 : 16),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  message.text ?? '',
                  style: TextStyle(
                    fontSize: 14,
                    color: isMe ? Colors.white : colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatTime(message.createdAt),
                  style: TextStyle(
                    fontSize: 10,
                    color: isMe
                        ? Colors.white.withValues(alpha: 0.7)
                        : colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (isMe)
          Padding(
            padding: const EdgeInsets.only(right: 4, bottom: 6),
            child: Text(
              showSeen ? '✓✓ Seen' : '✓ Sent',
              style: TextStyle(
                fontSize: 10,
                color: showSeen
                    ? colorScheme.primary
                    : colorScheme.onSurface.withValues(alpha: 0.4),
              ),
            ),
          ),
      ],
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

class _ProposalCard extends StatefulWidget {
  final ChatMessage message;
  final bool isMe;
  final String swapId;
  final String currentUid;
  final String otherUserId;
  final VoidCallback? onCounter;

  const _ProposalCard({
    required this.message,
    required this.isMe,
    required this.swapId,
    required this.currentUid,
    required this.otherUserId,
    this.onCounter,
  });

  @override
  State<_ProposalCard> createState() => _ProposalCardState();
}

class _ProposalCardState extends State<_ProposalCard> {
  final BrowseService _browseService = BrowseService();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isProposal = widget.message.type == MessageType.proposal;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border:
        Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(
              isProposal
                  ? Icons.swap_horiz_rounded
                  : Icons.replay_rounded,
              size: 15,
              color: colorScheme.primary,
            ),
            const SizedBox(width: 6),
            Text(
              isProposal ? 'Swap proposal' : 'Counter offer',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: colorScheme.primary,
                letterSpacing: 0.5,
              ),
            ),
          ]),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _BookMini(
                bookId: widget.message.bookOfferedId ?? '',
                ownerId: widget.isMe
                    ? widget.currentUid
                    : widget.otherUserId,
                browseService: _browseService,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Icon(Icons.swap_horiz_rounded,
                    color: colorScheme.primary, size: 24),
              ),
              _BookMini(
                bookId: widget.message.bookWantedId ?? '',
                ownerId: widget.isMe
                    ? widget.otherUserId
                    : widget.currentUid,
                browseService: _browseService,
              ),
            ],
          ),
          if (!widget.isMe) ...[
            const SizedBox(height: 12),
            _ActionButtons(
              swapId: widget.swapId,
              message: widget.message,
              currentUid: widget.currentUid,
              otherUserId: widget.otherUserId,
              onCounter: widget.onCounter,
            ),
          ],
        ],
      ),
    );
  }
}

class _ActionButtons extends StatelessWidget {
  final String swapId;
  final ChatMessage message;
  final String currentUid;
  final String otherUserId;
  final VoidCallback? onCounter;

  const _ActionButtons({
    required this.swapId,
    required this.message,
    required this.currentUid,
    required this.otherUserId,
    this.onCounter,
  });

  String get _bookOfferedId => message.bookOfferedId ?? '';
  String get _bookOfferedOwnerId => otherUserId;
  String get _bookWantedId => message.bookWantedId ?? '';
  String get _bookWantedOwnerId => currentUid;

  Future<void> _handleAccept(BuildContext context) async {
    final chatService = ChatService();
    try {
      await chatService.acceptSwap(
        swapId: swapId,
        bookOfferedId: _bookOfferedId,
        bookOfferedOwnerId: _bookOfferedOwnerId,
        bookWantedId: _bookWantedId,
        bookWantedOwnerId: _bookWantedOwnerId,
      );
    } on BookAlreadyLockedException {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              '⚠️ One of these books is already reserved for another swap.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Something went wrong: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _handleReject(BuildContext context) async {
    final chatService = ChatService();
    await chatService.cancelSwap(
      swapId: swapId,
      bookOfferedId: _bookOfferedId,
      bookOfferedOwnerId: _bookOfferedOwnerId,
      bookWantedId: _bookWantedId,
      bookWantedOwnerId: _bookWantedOwnerId,
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('chats')
          .doc(swapId)
          .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData || !snap.data!.exists) {
          return _buttons(context, ChatStatus.active);
        }

        final data = snap.data!.data() as Map<String, dynamic>;
        final status = ChatStatus.values.byName(
          data['status'] as String? ?? 'active',
        );

        if (status != ChatStatus.active) {
          return Align(
            alignment: Alignment.center,
            child: Text(
              status == ChatStatus.completed
                  ? '✅ Swap accepted — books reserved'
                  : '❌ Swap rejected',
              style: TextStyle(
                fontSize: 12,
                color: status == ChatStatus.completed
                    ? Colors.green[700]
                    : Colors.red[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          );
        }

        return _buttons(context, status);
      },
    );
  }

  Widget _buttons(BuildContext context, ChatStatus status) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => _handleReject(context),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
            ),
            child: const Text('Reject'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton(
            onPressed: onCounter,
            child: const Text('Counter'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: FilledButton(
            onPressed: () => _handleAccept(context),
            child: const Text('Accept'),
          ),
        ),
      ],
    );
  }
}

class _BookMini extends StatelessWidget {
  final String bookId;
  final String ownerId;
  final BrowseService browseService;

  const _BookMini({
    required this.bookId,
    required this.ownerId,
    required this.browseService,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Book?>(
      future: browseService.fetchBook(ownerId, bookId),
      builder: (context, snapshot) {
        final book = snapshot.data;
        return Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: book?.coverUrl != null
                  ? Image.network(
                book!.coverUrl!,
                width: 48,
                height: 68,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => _placeholder(),
              )
                  : _placeholder(),
            ),
            const SizedBox(height: 6),
            SizedBox(
              width: 80,
              child: Text(
                book?.title ??
                    (snapshot.connectionState == ConnectionState.waiting
                        ? '...'
                        : '—'),
                style: const TextStyle(fontSize: 11),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _placeholder() => Container(
    width: 48,
    height: 68,
    decoration: BoxDecoration(
      color: Colors.grey[200],
      borderRadius: BorderRadius.circular(6),
    ),
    child: const Icon(Icons.book, color: Colors.grey),
  );
}

class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final VoidCallback onChanged;
  final VoidCallback? onCounterOffer;

  const _InputBar({
    required this.controller,
    required this.onSend,
    required this.onChanged,
    required this.onCounterOffer,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              onPressed: onCounterOffer,
              icon: const Icon(Icons.swap_horiz_rounded),
              tooltip: 'Counter offer',
              color: onCounterOffer != null
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.3),
            ),
            Expanded(
              child: TextField(
                controller: controller,
                textCapitalization: TextCapitalization.sentences,
                onChanged: (_) => onChanged(),
                decoration: InputDecoration(
                  hintText: 'Message...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                ),
                onSubmitted: (_) => onSend(),
              ),
            ),
            IconButton(
              onPressed: onSend,
              icon: const Icon(Icons.send_rounded),
              color: Theme.of(context).colorScheme.primary,
            ),
          ],
        ),
      ),
    );
  }
}