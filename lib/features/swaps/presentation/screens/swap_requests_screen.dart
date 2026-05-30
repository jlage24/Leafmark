import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../books/data/services/browse_service.dart';
import '../../../books/domain/models/book.dart';
import '../../domain/models/swap_request.dart';
import '../providers/swap_provider.dart';

class SwapRequestsScreen extends StatefulWidget {
  const SwapRequestsScreen({super.key});

  @override
  State<SwapRequestsScreen> createState() => _SwapRequestsScreenState();
}

class _SwapRequestsScreenState extends State<SwapRequestsScreen> {
  late final Stream<List<SwapRequest>> _incoming;
  late final Stream<List<SwapRequest>> _outgoing;

  @override
  void initState() {
    super.initState();

    final uid = context.read<AuthProvider>().user?.uid ?? '';
    final provider = context.read<SwapProvider>();

    _incoming = provider.incoming(uid);
    _outgoing = provider.outgoing(uid);
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              const _SwapRequestsHeader(),
              const _SwapTabs(),
              Expanded(
                child: TabBarView(
                  children: [
                    _RequestList(stream: _incoming, isIncoming: true),
                    _RequestList(stream: _outgoing, isIncoming: false),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SwapRequestsHeader extends StatelessWidget {
  const _SwapRequestsHeader();

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
              Icons.swap_horiz_rounded,
              color: theme.colorScheme.primary,
              size: 30,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Swap Requests',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Track your incoming and outgoing swaps.',
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

class _SwapTabs extends StatelessWidget {
  const _SwapTabs();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: TabBar(
        tabs: [
          Tab(text: 'Incoming'),
          Tab(text: 'Outgoing'),
        ],
      ),
    );
  }
}

class _RequestList extends StatelessWidget {
  final Stream<List<SwapRequest>> stream;
  final bool isIncoming;

  const _RequestList({
    required this.stream,
    required this.isIncoming,
  });

  @override
  Widget build(BuildContext context) {
    final swapProvider = context.read<SwapProvider>();
    final browseService = BrowseService();

    return StreamBuilder<List<SwapRequest>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _RequestsLoadingState();
        }

        if (snapshot.hasError) {
          return const _RequestsMessageState(
            icon: Icons.error_outline_rounded,
            title: 'Could not load requests',
            message: 'Something went wrong. Please try again later.',
          );
        }

        final requests = snapshot.data ?? [];

        if (requests.isEmpty) {
          return _RequestsMessageState(
            icon: isIncoming
                ? Icons.move_to_inbox_outlined
                : Icons.outbox_outlined,
            title: isIncoming ? 'No incoming requests' : 'No outgoing requests',
            message: isIncoming
                ? 'When someone proposes a swap, it will appear here.'
                : 'Swaps you propose to other readers will appear here.',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final request = requests[index];

            return FutureBuilder<Book?>(
              future: browseService.fetchBook(
                request.ownerId,
                request.bookWantedId,
              ),
              builder: (context, bookSnapshot) {
                final book = bookSnapshot.data;

                return FutureBuilder<String?>(
                  future: isIncoming
                      ? browseService.fetchDisplayName(request.requesterId)
                      : Future.value(book?.ownerName),
                  builder: (context, nameSnapshot) {
                    final name = nameSnapshot.data ??
                        (isIncoming ? request.requesterId : request.ownerId);

                    return _RequestCard(
                      request: request,
                      book: book,
                      name: name,
                      isIncoming: isIncoming,
                      onAccept: () async {
                        try {
                          await swapProvider.accept(request);
                        } catch (e) {
                          if (!context.mounted) return;

                          _showErrorSnackBar(
                            context,
                            'Failed to accept swap.',
                          );
                        }
                      },
                      onReject: () async {
                        try {
                          await swapProvider.reject(request.id);
                        } catch (e) {
                          if (!context.mounted) return;

                          _showErrorSnackBar(
                            context,
                            'Failed to reject swap.',
                          );
                        }
                      },
                      onCancel: () async {
                        try {
                          await swapProvider.cancel(request.id);
                        } catch (e) {
                          if (!context.mounted) return;

                          _showErrorSnackBar(
                            context,
                            'Failed to cancel swap.',
                          );
                        }
                      },
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  void _showErrorSnackBar(BuildContext context, String message) {
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
}

class _RequestCard extends StatelessWidget {
  final SwapRequest request;
  final Book? book;
  final String name;
  final bool isIncoming;
  final VoidCallback onAccept;
  final VoidCallback onReject;
  final VoidCallback onCancel;

  const _RequestCard({
    required this.request,
    required this.book,
    required this.name,
    required this.isIncoming,
    required this.onAccept,
    required this.onReject,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPending = request.status == SwapStatus.pending;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              children: [
                _BookCover(coverUrl: book?.coverUrl),
                const SizedBox(width: 14),
                Expanded(
                  child: _RequestInfo(
                    title: book?.title ?? 'Loading book...',
                    name: name,
                    isIncoming: isIncoming,
                    status: request.status,
                  ),
                ),
              ],
            ),
            if (isPending) ...[
              const SizedBox(height: 14),
              isIncoming
                  ? _IncomingActions(
                onAccept: onAccept,
                onReject: onReject,
              )
                  : _OutgoingActions(onCancel: onCancel),
            ],
          ],
        ),
      ),
    );
  }
}

class _BookCover extends StatelessWidget {
  final String? coverUrl;

  const _BookCover({required this.coverUrl});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 66,
        height: 96,
        color: theme.colorScheme.primary.withValues(alpha: 0.08),
        child: coverUrl != null && coverUrl!.isNotEmpty
            ? Image.network(
          coverUrl!,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Icon(
            Icons.menu_book_rounded,
            color: theme.colorScheme.primary,
            size: 34,
          ),
        )
            : Icon(
          Icons.menu_book_rounded,
          color: theme.colorScheme.primary,
          size: 34,
        ),
      ),
    );
  }
}

class _RequestInfo extends StatelessWidget {
  final String title;
  final String name;
  final bool isIncoming;
  final SwapStatus status;

  const _RequestInfo({
    required this.title,
    required this.name,
    required this.isIncoming,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final directionLabel = isIncoming ? 'From $name' : 'To $name';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w900,
            height: 1.15,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          directionLabel,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.62),
          ),
        ),
        const SizedBox(height: 10),
        _StatusBadge(status: status),
      ],
    );
  }
}

class _IncomingActions extends StatelessWidget {
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const _IncomingActions({
    required this.onAccept,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onReject,
            icon: const Icon(Icons.close_rounded),
            label: const Text('Reject'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: FilledButton.icon(
            onPressed: onAccept,
            icon: const Icon(Icons.check_rounded),
            label: const Text('Accept'),
          ),
        ),
      ],
    );
  }
}

class _OutgoingActions extends StatelessWidget {
  final VoidCallback onCancel;

  const _OutgoingActions({required this.onCancel});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onCancel,
        icon: Icon(
          Icons.cancel_outlined,
          color: theme.colorScheme.error,
        ),
        label: Text(
          'Cancel request',
          style: TextStyle(color: theme.colorScheme.error),
        ),
        style: OutlinedButton.styleFrom(
          side: BorderSide(
            color: theme.colorScheme.error.withValues(alpha: 0.45),
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final SwapStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(status);
    final label = _statusLabel(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  Color _statusColor(SwapStatus status) {
    switch (status) {
      case SwapStatus.pending:
        return Colors.orange;
      case SwapStatus.accepted:
        return Colors.blue;
      case SwapStatus.completed:
        return Colors.green;
      case SwapStatus.rejected:
      case SwapStatus.cancelled:
        return Colors.red;
    }
  }

  String _statusLabel(SwapStatus status) {
    switch (status) {
      case SwapStatus.pending:
        return 'PENDING';
      case SwapStatus.accepted:
        return 'ACCEPTED';
      case SwapStatus.completed:
        return 'COMPLETED';
      case SwapStatus.rejected:
        return 'REJECTED';
      case SwapStatus.cancelled:
        return 'CANCELLED';
    }
  }
}

class _RequestsLoadingState extends StatelessWidget {
  const _RequestsLoadingState();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      itemCount: 4,
      itemBuilder: (context, index) {
        return const _LoadingRequestCard();
      },
    );
  }
}

class _LoadingRequestCard extends StatelessWidget {
  const _LoadingRequestCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final baseColor = theme.colorScheme.onSurface.withValues(alpha: 0.08);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Container(
            width: 66,
            height: 96,
            decoration: BoxDecoration(
              color: baseColor,
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                _LoadingLine(widthFactor: 0.82),
                SizedBox(height: 10),
                _LoadingLine(widthFactor: 0.46),
                SizedBox(height: 16),
                _LoadingLine(widthFactor: 0.32),
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

class _RequestsMessageState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _RequestsMessageState({
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
              child: Icon(
                icon,
                size: 38,
                color: theme.colorScheme.primary,
              ),
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