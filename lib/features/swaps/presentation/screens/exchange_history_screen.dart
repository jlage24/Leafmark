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
            itemBuilder: (context, i) =>
                _HistoryTile(swap: swaps[i], uid: _uid),
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

    final bookOwnerId = swap.ownerId;
    final bookId = swap.bookWantedId;
    final partnerUid = isRequester ? swap.ownerId : swap.requesterId;

    return FutureBuilder<List<dynamic>>(
      future: Future.wait([
        browseService.fetchBook(bookOwnerId, bookId),
        browseService.fetchDisplayName(partnerUid),
      ]),
      builder: (context, snapshot) {
        final book = snapshot.data?[0] as Book?;
        final partnerName = snapshot.data?[1] as String? ?? '...';

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: book?.coverUrl != null
                      ? Image.network(
                    book!.coverUrl!,
                    width: 60,
                    height: 90,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _placeholder(),
                  )
                      : _placeholder(),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        book?.title ?? 'Loading...',
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
                        DateFormat('dd MMM yyyy').format(swap.createdAt),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[500],
                        ),
                      ),
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

  Widget _placeholder() {
    return Container(
      width: 60,
      height: 90,
      color: Colors.grey[300],
      child: const Icon(Icons.book, color: Colors.grey),
    );
  }
}