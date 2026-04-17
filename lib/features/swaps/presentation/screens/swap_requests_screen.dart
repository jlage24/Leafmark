import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/models/swap_request.dart';
import '../providers/swap_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class SwapRequestsScreen extends StatelessWidget {
  const SwapRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = context.read<AuthProvider>().user?.uid ?? '';
    final theme = Theme.of(context);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Swap Requests'),
          bottom: const TabBar(
            tabs: [Tab(text: 'Incoming'), Tab(text: 'Outgoing')],
          ),
        ),
        body: TabBarView(
          children: [
            _RequestList(stream: context.read<SwapProvider>().incoming(uid), isIncoming: true),
            _RequestList(stream: context.read<SwapProvider>().outgoing(uid), isIncoming: false),
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
    final colorScheme = Theme.of(context).colorScheme;

    return StreamBuilder<List<SwapRequest>>(
      stream: stream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final reqs = snapshot.data!;
        if (reqs.isEmpty) return const Center(child: Text('No requests yet.'));

        return ListView.builder(
          itemCount: reqs.length,
          itemBuilder: (context, index) {
            final req = reqs[index];
            return Card(
              child: ListTile(
                title: Text('Book ID: ${req.bookWantedId}'),
                subtitle: Text('Status: ${req.status.name}'),
                trailing: isIncoming && req.status == SwapStatus.pending
                    ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.check, color: Colors.green),
                      onPressed: () => swapP.accept(req.id),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.red),
                      onPressed: () => swapP.reject(req.id),
                    ),
                  ],
                )
                    : !isIncoming && req.status == SwapStatus.pending
                    ? TextButton(
                  onPressed: () => swapP.cancel(req.id),
                  child: Text('Cancel', style: TextStyle(color: colorScheme.error)),
                )
                    : null,
              ),
            );
          },
        );
      },
    );
  }
}