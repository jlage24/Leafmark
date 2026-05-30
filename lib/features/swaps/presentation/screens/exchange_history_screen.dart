import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../books/data/services/browse_service.dart';
import '../../../books/domain/models/book.dart';
import '../../domain/models/swap_request.dart';
import '../providers/swap_provider.dart';

class ExchangeHistoryScreen extends StatefulWidget {
  const ExchangeHistoryScreen({super.key});

  @override
  State<ExchangeHistoryScreen> createState() => _ExchangeHistoryScreenState();
}

class _ExchangeHistoryScreenState extends State<ExchangeHistoryScreen> {
  late final Stream<List<SwapRequest>> _history;
  late final String _uid;

  @override
  void initState() {
    super.initState();
    _uid = context.read<AuthProvider>().user?.uid ?? '';
    _history = context.read<SwapProvider>().exchangeHistory(_uid);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const _HistoryHeader(),
            Expanded(
              child: StreamBuilder<List<SwapRequest>>(
                stream: _history,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const _HistoryLoadingState();
                  }

                  if (snapshot.hasError) {
                    return const _HistoryMessageState(
                      icon: Icons.error_outline_rounded,
                      title: 'Could not load history',
                      message: 'Something went wrong. Please try again later.',
                    );
                  }

                  final swaps = snapshot.data ?? [];

                  if (swaps.isEmpty) {
                    return const _HistoryMessageState(
                      icon: Icons.history_rounded,
                      title: 'No completed exchanges yet',
                      message: 'Completed book swaps will appear here.',
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.only(bottom: 16),
                    itemCount: swaps.length,
                    itemBuilder: (context, index) {
                      return _HistoryTile(swap: swaps[index], uid: _uid);
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

class _HistoryHeader extends StatelessWidget {
  const _HistoryHeader();

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
              Icons.history_rounded,
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
                  'Exchange History',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Your completed book swaps.',
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

class _HistoryTile extends StatelessWidget {
  final SwapRequest swap;
  final String uid;

  const _HistoryTile({
    required this.swap,
    required this.uid,
  });

  @override
  Widget build(BuildContext context) {
    final browseService = BrowseService();
    final isRequester = swap.requesterId == uid;

    final receivedBookOwnerId = isRequester ? swap.requesterId : swap.ownerId;
    final receivedBookId = isRequester ? swap.bookWantedId : swap.bookOfferedId;
    final partnerUid = isRequester ? swap.ownerId : swap.requesterId;

    return FutureBuilder<_HistoryData>(
      future: _loadHistoryData(
        browseService: browseService,
        bookOwnerId: receivedBookOwnerId,
        bookId: receivedBookId,
        partnerUid: partnerUid,
      ),
      builder: (context, snapshot) {
        final data = snapshot.data;
        final book = data?.book;
        final partnerName = data?.partnerName ?? 'LeafMark user';
        final completedDate = swap.completedAt ?? swap.createdAt;

        return _HistoryCard(
          book: book,
          partnerName: partnerName,
          date: completedDate,
          isLoading: snapshot.connectionState == ConnectionState.waiting,
        );
      },
    );
  }

  Future<_HistoryData> _loadHistoryData({
    required BrowseService browseService,
    required String bookOwnerId,
    required String bookId,
    required String partnerUid,
  }) async {
    final results = await Future.wait<dynamic>([
      browseService.fetchBook(bookOwnerId, bookId),
      browseService.fetchDisplayName(partnerUid),
    ]);

    return _HistoryData(
      book: results[0] as Book?,
      partnerName: results[1] as String? ?? 'LeafMark user',
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final Book? book;
  final String partnerName;
  final DateTime date;
  final bool isLoading;

  const _HistoryCard({
    required this.book,
    required this.partnerName,
    required this.date,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
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
        child: Row(
          children: [
            _BookCover(book: book),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    book?.title ??
                        (isLoading ? 'Loading exchanged book...' : 'Exchanged book'),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.person_outline_rounded,
                        size: 16,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'With $partnerName',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.62),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 14,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        DateFormat('dd MMM yyyy').format(date),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.52),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 9),
                  const _CompletedBadge(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryData {
  final Book? book;
  final String partnerName;

  const _HistoryData({
    required this.book,
    required this.partnerName,
  });
}

class _BookCover extends StatelessWidget {
  final Book? book;

  const _BookCover({required this.book});

  @override
  Widget build(BuildContext context) {
    final displayUrl = book?.conditionPhotoUrls.isNotEmpty == true
        ? book!.conditionPhotoUrls.first
        : book?.coverUrl;

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 66,
        height: 96,
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
        child: displayUrl == null || displayUrl.isEmpty
            ? const _PlaceholderCover()
            : Image.network(
          displayUrl,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
          const _PlaceholderCover(),
        ),
      ),
    );
  }
}

class _CompletedBadge extends StatelessWidget {
  const _CompletedBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.green.withValues(alpha: 0.35)),
      ),
      child: Text(
        'COMPLETED',
        style: TextStyle(
          color: Colors.green.shade700,
          fontSize: 11,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

class _PlaceholderCover extends StatelessWidget {
  const _PlaceholderCover();

  @override
  Widget build(BuildContext context) {
    return Icon(
      Icons.menu_book_rounded,
      color: Theme.of(context).colorScheme.primary,
      size: 34,
    );
  }
}

class _HistoryLoadingState extends StatelessWidget {
  const _HistoryLoadingState();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 16),
      itemCount: 4,
      itemBuilder: (context, index) => const _LoadingHistoryCard(),
    );
  }
}

class _LoadingHistoryCard extends StatelessWidget {
  const _LoadingHistoryCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final baseColor = theme.colorScheme.onSurface.withValues(alpha: 0.08);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
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
                _LoadingLine(widthFactor: 0.78),
                SizedBox(height: 10),
                _LoadingLine(widthFactor: 0.48),
                SizedBox(height: 10),
                _LoadingLine(widthFactor: 0.34),
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

class _HistoryMessageState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _HistoryMessageState({
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