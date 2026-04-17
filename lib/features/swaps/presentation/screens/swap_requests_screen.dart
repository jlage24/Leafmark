import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/models/swap_request.dart';
import '../providers/swap_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../data/dummy_data.dart';

class SwapRequestsScreen extends StatelessWidget {
  const SwapRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = context.read<AuthProvider>().user?.uid ?? '';

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Swap Requests'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Incoming'),
              Tab(text: 'Outgoing'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _RequestList(
              stream: context.read<SwapProvider>().incoming(uid),
              isIncoming: true,
            ),
            _RequestList(
              stream: context.read<SwapProvider>().outgoing(uid),
              isIncoming: false,
            ),
          ],
        ),
      ),
    );
  }
}

class _RequestList extends StatelessWidget {
  final Stream<List<SwapRequest>> stream;
  final bool isIncoming;

  const _RequestList({required this.stream, required this.isIncoming});

  @override
  Widget build(BuildContext context) {
    final swapP = context.read<SwapProvider>();

    return StreamBuilder<List<SwapRequest>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final reqs = snapshot.data ?? [];
        if (reqs.isEmpty) {
          return Center(
            child: Text(
              isIncoming ? 'No incoming requests yet.' : 'You haven\'t sent any requests.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: reqs.length,
          itemBuilder: (context, index) {
            final req = reqs[index];
            final book = findBookById(req.bookWantedId);

            final otherPerson = isIncoming
                ? req.requesterId
                : (book?.ownerName ?? req.ownerId);

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    // 1. Foto do Livro
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: book?.coverUrl != null
                          ? Image.network(
                        book!.coverUrl!,
                        width: 60,
                        height: 90,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => _placeholder(),
                      )
                          : _placeholder(),
                    ),
                    const SizedBox(width: 16),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            book?.title ?? 'Unknown Book',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isIncoming
                                ? 'From: $otherPerson'
                                : 'To: $otherPerson',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: 8),
                          _StatusBadge(status: req.status),
                        ],
                      ),
                    ),

                    if (req.status == SwapStatus.pending)
                      Column(
                        children: isIncoming
                            ? [
                          IconButton(
                            icon: const Icon(Icons.check_circle, color: Colors.green, size: 30),
                            onPressed: () => swapP.accept(req.id),
                            tooltip: 'Accept Request',
                          ),
                          IconButton(
                            icon: const Icon(Icons.cancel, color: Colors.red, size: 30),
                            onPressed: () => swapP.reject(req.id),
                            tooltip: 'Reject Request',
                          ),
                        ]
                            : [
                          TextButton(
                            onPressed: () => swapP.cancel(req.id),
                            child: const Text('Cancel', style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            );
          },
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

// Widget auxiliar para mostrar o badge de status (Accepted, Pending, Rejected)
class _StatusBadge extends StatelessWidget {
  final SwapStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case SwapStatus.accepted: color = Colors.green; break;
      case SwapStatus.rejected: color = Colors.red; break;
      case SwapStatus.pending: color = Colors.orange; break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        status.name.toUpperCase(),
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}