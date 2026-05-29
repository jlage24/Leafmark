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
      appBar: AppBar(
        title: const Text('Exchange History'),
      ),
      body: StreamBuilder<List<SwapRequest>>(
        stream: _history,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final swaps = snapshot.data ?? [];

          if (swaps.isEmpty) {
            return Center(
              child: Text(
                'No completed exchanges yet.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: swaps.length,
            itemBuilder: (context, index) {
              return _HistoryTile(swap: swaps[index], uid: _uid);
            },
          );
        },
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  final SwapRequest swap;
  final String uid;

  const _HistoryTile({required this.swap, required this.uid});

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

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: _BookCover(book: book),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        book?.title ??
                            (snapshot.connectionState == ConnectionState.waiting
                                ? 'Loading exchanged book...'
                                : 'Exchanged book'),
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'With $partnerName',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('dd MMM yyyy').format(completedDate),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[500],
                        ),
                      ),
                      const SizedBox(height: 6),
                      const _CompletedBadge(),
                    ],
                  ),
                ),
              ],
            ),
          ),
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

class _HistoryData {
  final Book? book;
  final String partnerName;

  const _HistoryData({required this.book, required this.partnerName});
}

class _BookCover extends StatelessWidget {
  final Book? book;

  const _BookCover({required this.book});

  @override
  Widget build(BuildContext context) {
    final displayUrl = book?.conditionPhotoUrls.isNotEmpty == true
        ? book!.conditionPhotoUrls.first
        : book?.coverUrl;

    if (displayUrl == null || displayUrl.isEmpty) {
      return const _PlaceholderCover();
    }

    return Image.network(
      displayUrl,
      width: 60,
      height: 90,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => const _PlaceholderCover(),
    );
  }
}

class _CompletedBadge extends StatelessWidget {
  const _CompletedBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.green.withValues(alpha: 0.45)),
      ),
      child: Text(
        'COMPLETED',
        style: TextStyle(
          color: Colors.green.shade700,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _PlaceholderCover extends StatelessWidget {
  const _PlaceholderCover();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 60,
      height: 90,
      color: Colors.grey[300],
      child: const Icon(Icons.book, color: Colors.grey),
    );
  }
}