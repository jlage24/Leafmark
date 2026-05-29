import 'package:flutter/material.dart';
import '../../../books/data/services/browse_service.dart';
import '../../../books/domain/models/book.dart';
import '../../../swaps/data/services/swap_service.dart';
import '../../domain/models/chat_message.dart';
import '../../domain/models/chat_metadata.dart';

// ─── Typing Indicator ────────────────────────────────────────────────────────
class TypingIndicator extends StatefulWidget {
  const TypingIndicator({super.key});

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
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
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color =
    Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4);
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
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ─── Text Bubble ─────────────────────────────────────────────────────────────
class TextBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMe;
  final bool showSeen;

  const TextBubble({
    super.key,
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
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
        if (isMe && showSeen)
          Padding(
            padding: const EdgeInsets.only(right: 4, bottom: 6),
            child: Text(
              '✓✓ Seen',
              style: TextStyle(fontSize: 10, color: colorScheme.primary),
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

// ─── Proposal Card ────────────────────────────────────────────────────────────
class ProposalCard extends StatefulWidget {
  final ChatMessage message;
  final bool isMe;
  final String swapId;
  final String currentUid;
  final String otherUserId;
  final ChatStatus chatStatus;
  final VoidCallback? onCounter;

  const ProposalCard({
    super.key,
    required this.message,
    required this.isMe,
    required this.swapId,
    required this.currentUid,
    required this.otherUserId,
    required this.chatStatus,
    this.onCounter,
  });

  @override
  State<ProposalCard> createState() => _ProposalCardState();
}

class _ProposalCardState extends State<ProposalCard> {
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
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(
              isProposal ? Icons.swap_horiz_rounded : Icons.replay_rounded,
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
              BookMini(
                bookId: widget.message.bookOfferedId ?? '',
                ownerIds: _offeredBookOwnerCandidates(),
                browseService: _browseService,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Icon(Icons.swap_horiz_rounded,
                    color: colorScheme.primary, size: 24),
              ),
              BookMini(
                bookId: widget.message.bookWantedId ?? '',
                ownerIds: _wantedBookOwnerCandidates(),
                browseService: _browseService,
              ),
            ],
          ),
          if (!widget.isMe) ...[
            const SizedBox(height: 12),
            ActionButtons(
              swapId: widget.swapId,
              message: widget.message,
              currentUid: widget.currentUid,
              otherUserId: widget.otherUserId,
              chatStatus: widget.chatStatus,
              onCounter: widget.onCounter,
            ),
          ],
        ],
      ),
    );
  }

  List<String> _offeredBookOwnerCandidates() {
    final originalOwnerId = widget.message.bookOfferedOwnerId ??
        (widget.isMe ? widget.currentUid : widget.otherUserId);

    final otherParticipantId = originalOwnerId == widget.currentUid
        ? widget.otherUserId
        : widget.currentUid;

    return _uniqueNonEmpty([originalOwnerId, otherParticipantId]);
  }

  List<String> _wantedBookOwnerCandidates() {
    final offeredOwnerId = widget.message.bookOfferedOwnerId ??
        (widget.isMe ? widget.currentUid : widget.otherUserId);

    final originalWantedOwnerId = offeredOwnerId == widget.currentUid
        ? widget.otherUserId
        : widget.currentUid;

    return _uniqueNonEmpty([originalWantedOwnerId, offeredOwnerId]);
  }

  List<String> _uniqueNonEmpty(List<String?> values) {
    final result = <String>[];

    for (final value in values) {
      if (value == null || value.isEmpty || result.contains(value)) continue;
      result.add(value);
    }

    return result;
  }
}

// ─── Action Buttons ───────────────────────────────────────────────────────────
class ActionButtons extends StatelessWidget {
  final String swapId;
  final ChatMessage message;
  final String currentUid;
  final String otherUserId;
  final ChatStatus chatStatus;
  final VoidCallback? onCounter;

  const ActionButtons({
    super.key,
    required this.swapId,
    required this.message,
    required this.currentUid,
    required this.otherUserId,
    required this.chatStatus,
    this.onCounter,
  });

  Future<void> _handleAccept(BuildContext context) async {
    try {
      await SwapService().acceptSwapById(swapId);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to accept swap: $e')),
      );
    }
  }

  Future<void> _handleReject(BuildContext context) async {
    try {
      await SwapService().rejectSwapById(swapId);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to reject swap: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (chatStatus != ChatStatus.active) {
      final info = _statusInfo();

      return Align(
        alignment: Alignment.center,
        child: Text(
          info.message,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            color: info.color,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

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

  _ProposalStatusInfo _statusInfo() {
    switch (chatStatus) {
      case ChatStatus.accepted:
        return _ProposalStatusInfo(
          message: '✅ Swap accepted — books reserved until the exchange is completed',
          color: Colors.green.shade700,
        );
      case ChatStatus.completed:
        return _ProposalStatusInfo(
          message: '🎉 Exchange completed',
          color: Colors.green.shade700,
        );
      case ChatStatus.cancelled:
        return _ProposalStatusInfo(
          message: '❌ Swap rejected',
          color: Colors.red.shade700,
        );
      case ChatStatus.active:
        return _ProposalStatusInfo(
          message: '',
          color: Colors.grey,
        );
    }
  }
}

class _ProposalStatusInfo {
  final String message;
  final Color color;

  const _ProposalStatusInfo({
    required this.message,
    required this.color,
  });
}

// ─── Book Mini ────────────────────────────────────────────────────────────────
class BookMini extends StatelessWidget {
  final String bookId;
  final List<String> ownerIds;
  final BrowseService browseService;

  const BookMini({
    super.key,
    required this.bookId,
    required this.ownerIds,
    required this.browseService,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Book?>(
      future: _fetchBookFromAnyOwner(),
      builder: (context, snapshot) {
        final book = snapshot.data;
        final displayUrl = book?.conditionPhotoUrls.isNotEmpty == true
            ? book!.conditionPhotoUrls.first
            : book?.coverUrl;

        return Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: displayUrl != null
                  ? Image.network(
                displayUrl,
                width: 48,
                height: 68,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    _placeholder(),
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
                        : 'Book unavailable'),
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

  Future<Book?> _fetchBookFromAnyOwner() async {
    if (bookId.isEmpty) return null;

    for (final ownerId in ownerIds) {
      if (ownerId.isEmpty) continue;

      final book = await browseService.fetchBook(ownerId, bookId);
      if (book != null) return book;
    }

    return null;
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

// ─── Chat Input Bar ───────────────────────────────────────────────────────────
class ChatInputBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final VoidCallback onChanged;
  final VoidCallback? onCounterOffer;

  const ChatInputBar({
    super.key,
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