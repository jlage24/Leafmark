import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/models/book.dart';
import '../../../swaps/domain/models/swap_request.dart';
import '../../../swaps/presentation/providers/swap_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../swaps/data/services/swap_service.dart';
import '../../../chat/presentation/providers/chat_provider.dart';
import '../../../chat/presentation/screens/chat_screen.dart';
import '../providers/book_shelf_provider.dart';

class BookDetailScreen extends StatelessWidget {
  final Book book;
  final bool isOwner;
  final bool isCatalogView;

  const BookDetailScreen({
    super.key,
    required this.book,
    required this.isOwner,
    this.isCatalogView = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final swapProvider = context.watch<SwapProvider>();
    final authProvider = context.read<AuthProvider>();

    return Scaffold(
      appBar: AppBar(title: Text(book.title)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
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
            Text(
              book.title,
              style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              book.authors,
              style: textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 10,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                if (!isCatalogView) ...[
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
                ],
                if (book.isbn.isNotEmpty)
                  _MetaChip(
                    icon: Icons.qr_code_rounded,
                    label: book.isbn,
                    color: Colors.grey,
                  ),
              ],
            ),
            if (!isCatalogView && book.notes != null && book.notes!.isNotEmpty) ...[
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colorScheme.primary.withValues(alpha: 0.15)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.notes_rounded, size: 18, color: colorScheme.primary),
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
            if (!isCatalogView) ...[
              const SizedBox(height: 36),
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
                      : () => _showBookPickerSheet(context, authProvider),
                  icon: swapProvider.isLoading
                      ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.swap_horiz_rounded),
                  label: const Text('Request Swap'),
                ),
              ),
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _showBookPickerSheet(BuildContext context, AuthProvider authProvider) {
    final shelfBooks = context.read<BookShelfProvider>().books;

    if (shelfBooks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You need books on your shelf to propose a swap.'),
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
      builder: (sheetCtx) {
        return SafeArea(
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
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
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
                          errorBuilder: (_, __, ___) =>
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
                      onTap: () {
                        Navigator.pop(sheetCtx);
                        _submitSwap(context, authProvider, offeredBook);
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Future<void> _submitSwap(
      BuildContext context,
      AuthProvider authProvider,
      Book offeredBook,
      ) async {
    final swapProvider = context.read<SwapProvider>();
    final chatProvider = context.read<ChatProvider>();
    final colorScheme = Theme.of(context).colorScheme;

    try {
      final request = SwapRequest(
        id: '',
        requesterId: authProvider.user!.uid,
        ownerId: book.ownerId ?? '',
        bookOfferedId: offeredBook.id,
        bookWantedId: book.id,
        status: SwapStatus.pending,
        createdAt: DateTime.now(),
      );

      final swapId = await swapProvider.sendRequest(request);

      await chatProvider.createChat(
        swapId: swapId,
        participantIds: [authProvider.user!.uid, book.ownerId ?? ''],
      );

      await chatProvider.sendProposal(
        swapId: swapId,
        bookOfferedId: offeredBook.id,
        bookOfferedOwnerId: authProvider.user!.uid,
        bookWantedId: book.id,
      );

      if (context.mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ChatScreen(swapId: swapId, otherUserName: book.ownerName ?? ''),
          ),
        );
      }
    } on DuplicateSwapException {
      if (context.mounted) {
        _showResultDialog(
          context,
          title: 'Already Requested!',
          message: 'You already have a pending request for this book.',
          icon: Icons.info_outline_rounded,
          iconColor: Colors.orange,
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: colorScheme.error,
          ),
        );
      }
    }
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
            style: FilledButton.styleFrom(minimumSize: const Size(120, 44)),
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
      case BookCondition.mint: return Colors.green[700]!;
      case BookCondition.good: return Colors.blue[700]!;
      case BookCondition.fair: return Colors.orange[700]!;
      case BookCondition.poor: return Colors.red[700]!;
    }
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _MetaChip({required this.icon, required this.label, required this.color});

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
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: color),
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