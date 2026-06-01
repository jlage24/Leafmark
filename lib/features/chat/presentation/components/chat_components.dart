import 'package:flutter/material.dart';

import '../../../books/data/services/browse_service.dart';
import '../../../books/domain/models/book.dart';
import '../../../swaps/data/services/swap_service.dart';
import '../../domain/models/chat_message.dart';
import '../../domain/models/chat_metadata.dart';

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
          (index) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 420),
      ),
    );

    _animations = _controllers
        .map(
          (controller) => Tween<double>(begin: 0, end: -6).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeInOut),
      ),
    )
        .toList();

    for (var i = 0; i < 3; i++) {
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
    final theme = Theme.of(context);
    final dotColor = theme.colorScheme.onSurface.withValues(alpha: 0.42);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.85),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(18),
          topRight: Radius.circular(18),
          bottomRight: Radius.circular(18),
          bottomLeft: Radius.circular(6),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (index) {
          return AnimatedBuilder(
            animation: _animations[index],
            builder: (context, child) => Transform.translate(
              offset: Offset(0, _animations[index].value),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: dotColor,
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
    final theme = Theme.of(context);
    final bubbleColor =
    isMe ? theme.colorScheme.primary : theme.colorScheme.surfaceContainerHighest;
    final textColor = isMe ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface;

    return Column(
      crossAxisAlignment:
      isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Align(
          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.only(bottom: 3),
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 7),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.74,
            ),
            decoration: BoxDecoration(
              color: bubbleColor,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(19),
                topRight: const Radius.circular(19),
                bottomLeft: Radius.circular(isMe ? 19 : 6),
                bottomRight: Radius.circular(isMe ? 6 : 19),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isMe ? 0.07 : 0.035),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  message.text ?? '',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: textColor,
                    height: 1.28,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  _formatTime(message.createdAt),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: textColor.withValues(alpha: 0.68),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (isMe && showSeen)
          Padding(
            padding: const EdgeInsets.only(right: 6, bottom: 7),
            child: Text(
              '✓✓ Seen',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w700,
                fontSize: 10,
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
    final theme = Theme.of(context);
    final isProposal = widget.message.type == MessageType.proposal;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.12),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.045),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ProposalHeader(isProposal: isProposal),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: BookMini(
                  bookId: widget.message.bookOfferedId ?? '',
                  ownerIds: _offeredBookOwnerCandidates(),
                  browseService: _browseService,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.swap_horiz_rounded,
                    color: theme.colorScheme.primary,
                    size: 22,
                  ),
                ),
              ),
              Expanded(
                child: BookMini(
                  bookId: widget.message.bookWantedId ?? '',
                  ownerIds: _wantedBookOwnerCandidates(),
                  browseService: _browseService,
                ),
              ),
            ],
          ),
          if (!widget.isMe) ...[
            const SizedBox(height: 14),
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

class _ProposalHeader extends StatelessWidget {
  final bool isProposal;

  const _ProposalHeader({required this.isProposal});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            isProposal ? Icons.swap_horiz_rounded : Icons.replay_rounded,
            size: 19,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            isProposal ? 'Swap proposal' : 'Counter offer',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

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
      await SwapService().acceptOfferFromMessage(
        swapId: swapId,
        message: message,
        currentUid: currentUid,
      );
    } catch (e) {
      if (!context.mounted) return;
      _showError(context, 'Failed to accept swap: $e');
    }
  }

  Future<void> _handleReject(BuildContext context) async {
    try {
      await SwapService().rejectSwapById(swapId);
    } catch (e) {
      if (!context.mounted) return;
      _showError(context, 'Failed to reject swap: $e');
    }
  }

  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (chatStatus != ChatStatus.active) {
      final info = _statusInfo();

      return _ProposalStatusBadge(info: info);
    }

    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _handleReject(context),
            icon: const Icon(Icons.close_rounded, size: 17),
            label: const FittedBox(
              fit: BoxFit.scaleDown,
              child: Text('Reject'),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red.shade700,
              side: BorderSide(color: Colors.red.withValues(alpha: 0.45)),
              padding: const EdgeInsets.symmetric(horizontal: 4),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onCounter,
            icon: const Icon(Icons.compare_arrows_rounded, size: 17),
            label: const FittedBox(
              fit: BoxFit.scaleDown,
              child: Text('Counter'),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 4),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: FilledButton.icon(
            onPressed: () => _handleAccept(context),
            icon: const Icon(Icons.check_rounded, size: 17),
            label: const FittedBox(
              fit: BoxFit.scaleDown,
              child: Text('Accept'),
            ),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 4),
            ),
          ),
        ),
      ],
    );
  }

  _ProposalStatusInfo _statusInfo() {
    switch (chatStatus) {
      case ChatStatus.accepted:
        return _ProposalStatusInfo(
          icon: Icons.handshake_outlined,
          message: 'Swap accepted — books reserved',
          color: Colors.green.shade700,
        );
      case ChatStatus.completed:
        return _ProposalStatusInfo(
          icon: Icons.celebration_outlined,
          message: 'Exchange completed',
          color: Colors.green.shade700,
        );
      case ChatStatus.cancelled:
        return _ProposalStatusInfo(
          icon: Icons.cancel_outlined,
          message: 'Swap rejected',
          color: Colors.red.shade700,
        );
      case ChatStatus.active:
        return _ProposalStatusInfo(
          icon: Icons.info_outline_rounded,
          message: '',
          color: Colors.grey,
        );
    }
  }
}

class _ProposalStatusBadge extends StatelessWidget {
  final _ProposalStatusInfo info;

  const _ProposalStatusBadge({required this.info});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: info.color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: info.color.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(info.icon, size: 17, color: info.color),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              info.message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: info.color,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProposalStatusInfo {
  final IconData icon;
  final String message;
  final Color color;

  const _ProposalStatusInfo({
    required this.icon,
    required this.message,
    required this.color,
  });
}

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
              borderRadius: BorderRadius.circular(14),
              child: Container(
                width: 62,
                height: 88,
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
                child: displayUrl != null && displayUrl.isNotEmpty
                    ? Image.network(
                  displayUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      _placeholder(context),
                )
                    : _placeholder(context),
              ),
            ),
            const SizedBox(height: 7),
            Text(
              book?.title ??
                  (snapshot.connectionState == ConnectionState.waiting
                      ? 'Loading...'
                      : 'Book unavailable'),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
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

  Widget _placeholder(BuildContext context) {
    return Icon(
      Icons.menu_book_rounded,
      color: Theme.of(context).colorScheme.primary,
      size: 28,
    );
  }
}

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
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.12),
          ),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              onPressed: onCounterOffer,
              tooltip: 'Counter offer',
              icon: const Icon(Icons.swap_horiz_rounded),
              color: onCounterOffer != null
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurface.withValues(alpha: 0.28),
            ),
            Expanded(
              child: TextField(
                controller: controller,
                textCapitalization: TextCapitalization.sentences,
                onChanged: (_) => onChanged(),
                decoration: InputDecoration(
                  hintText: 'Message...',
                  filled: true,
                  fillColor: theme.colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.75),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(999),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 11,
                  ),
                ),
                onSubmitted: (_) => onSend(),
              ),
            ),
            const SizedBox(width: 4),
            IconButton.filled(
              onPressed: onSend,
              icon: const Icon(Icons.send_rounded, size: 20),
              color: theme.colorScheme.onPrimary,
              style: IconButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}