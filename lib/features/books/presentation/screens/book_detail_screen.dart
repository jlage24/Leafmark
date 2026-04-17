import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/models/book.dart';
import '../../../swaps/domain/models/swap_request.dart';
import '../../../swaps/presentation/providers/swap_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class BookDetailScreen extends StatelessWidget {
  final Book book;
  final bool isOwner;

  const BookDetailScreen({
    super.key,
    required this.book,
    required this.isOwner,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final swapProvider = context.watch<SwapProvider>();
    final authProvider = context.read<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(book.title),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Cover
            ClipRRect(
              borderRadius: BorderRadius.circular(10.0),
              child: book.coverUrl != null
                  ? Image.network(
                book.coverUrl!,
                height: 220,
                fit: BoxFit.cover,
                errorBuilder: (context, error, _) => const _PlaceholderCover(),
              )
                  : const _PlaceholderCover(),
            ),

            const SizedBox(height: 24),

            // Title
            Text(
              book.title,
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 6),

            // Authors
            Text(
              book.authors,
              style: textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 20),

            // Meta chips row
            Wrap(
              spacing: 10,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                _MetaChip(
                  icon: Icons.star_outline_rounded,
                  label: book.condition.label,
                  color: _conditionColor(book.condition),
                ),
                if (book.ownerName != null)
                  _MetaChip(
                    icon: Icons.person_outline_rounded,
                    label: book.ownerName!,
                    color: colorScheme.primary,
                  ),
                _MetaChip(
                  icon: Icons.qr_code_rounded,
                  label: book.isbn,
                  color: Colors.grey,
                ),
              ],
            ),

            // Notes
            if (book.notes != null && book.notes!.isNotEmpty) ...[
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: colorScheme.primary.withValues(alpha: 0.15),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.notes_rounded,
                        size: 18, color: colorScheme.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        book.notes!,
                        style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.75),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 36),

            // Action button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: isOwner
                  ? OutlinedButton.icon(
                onPressed: null,
                icon: const Icon(Icons.check_circle_outline_rounded),
                label: const Text('This book is on your shelf'),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              )
                  : FilledButton.icon(
                onPressed: swapProvider.isLoading
                    ? null
                    : () async {
                  try {
                    final request = SwapRequest(
                      id: '',
                      requesterId: authProvider.user!.uid,
                      ownerId: book.ownerId ?? '',
                      bookOfferedId: 'temporary_id',
                      bookWantedId: book.id,
                      status: SwapStatus.pending,
                      createdAt: DateTime.now(),
                    );
                    await swapProvider.sendRequest(request);

                    if (context.mounted) {
                      _showResultDialog(
                        context,
                        title: 'Request Sent!',
                        message: 'Your swap request for "${book.title}" was successfully sent to ${book.ownerName ?? 'the owner'}.\n\nYou can track it in your Swap Requests.',
                        icon: Icons.check_circle_outline_rounded,
                        iconColor: Colors.green,
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      final errorMsg = e.toString();

                      if (errorMsg.contains('already exists') || errorMsg.contains('Já enviaste')) {
                        _showResultDialog(
                          context,
                          title: 'Already Requested!',
                          message: 'You have already sent a pending request for "${book.title}". Please wait for the owner to respond.',
                          icon: Icons.info_outline_rounded,
                          iconColor: Colors.orange,
                        );
                      } else {
                        // Qualquer outro erro (ex: falha de rede)
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(errorMsg.replaceAll('Exception: ', '')),
                            backgroundColor: colorScheme.error,
                          ),
                        );
                      }
                    }
                  }
                },
                icon: swapProvider.isLoading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.swap_horiz_rounded),
                label: const Text('Request Swap'),
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _showResultDialog(
      BuildContext context, {
        required String title,
        required String message,
        required IconData icon,
        required Color iconColor,
      }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: Icon(icon, color: iconColor, size: 54),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(message, textAlign: TextAlign.center, style: const TextStyle(fontSize: 15)),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          FilledButton(
            style: FilledButton.styleFrom(
              minimumSize: const Size(120, 44),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text('Awesome'),
          ),
        ],
      ),
    );
  }

  Color _conditionColor(BookCondition condition) {
    switch (condition) {
      case BookCondition.mint:
        return Colors.green[700]!;
      case BookCondition.good:
        return Colors.blue[700]!;
      case BookCondition.fair:
        return Colors.orange[700]!;
      case BookCondition.poor:
        return Colors.red[700]!;
    }
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _MetaChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _PlaceholderCover extends StatelessWidget {
  const _PlaceholderCover();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 220,
      width: 150,
      color: Colors.grey[200],
      child: const Icon(Icons.book_outlined, size: 64, color: Colors.grey),
    );
  }
}