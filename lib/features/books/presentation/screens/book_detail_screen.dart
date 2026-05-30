import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/models/book.dart';
import '../../../swaps/domain/models/swap_request.dart';
import '../../../swaps/presentation/providers/swap_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/presentation/screens/public_profile_screen.dart';
import '../../../swaps/data/services/swap_service.dart';
import '../../../chat/presentation/providers/chat_provider.dart';
import '../../../chat/presentation/screens/chat_screen.dart';
import '../providers/book_shelf_provider.dart';
import 'edit_book_listing_screen.dart';

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

  List<String> get _galleryUrls {
    final urls = <String>[
      ...book.conditionPhotoUrls,
      if (book.coverUrl != null && book.coverUrl!.isNotEmpty) book.coverUrl!,
    ];

    return urls.toSet().toList();
  }

  @override
  Widget build(BuildContext context) {
    final swapProvider = context.watch<SwapProvider>();
    final authProvider = context.read<AuthProvider>();
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _BookGalleryAppBar(
            title: book.title,
            imageUrls: _galleryUrls,
            isReserved: book.isLocked,
            hasRealPhotos: book.conditionPhotoUrls.isNotEmpty,
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _TitleSection(book: book),
                  const SizedBox(height: 18),
                  _MetaSection(book: book),
                  const SizedBox(height: 24),
                  if (!isCatalogView && book.ownerId != null) ...[
                    _OwnerCard(book: book, isOwner: isOwner),
                    const SizedBox(height: 24),
                  ],
                  _InfoSection(book: book),
                  if (book.notes != null && book.notes!.trim().isNotEmpty) ...[
                    const SizedBox(height: 24),
                    _NotesSection(notes: book.notes!),
                  ],
                  const SizedBox(height: 24),
                  _SwapReadinessSection(
                    isOwner: isOwner,
                    isReserved: book.isLocked,
                    hasRealPhotos: book.conditionPhotoUrls.isNotEmpty,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: isCatalogView
          ? null
          : _BottomActionBar(
        isOwner: isOwner,
        isReserved: book.isLocked,
        isLoading: swapProvider.isLoading,
        bottomPadding: bottomPadding,
        onViewOwner: book.ownerId == null
            ? null
            : () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PublicProfileScreen(
              userId: book.ownerId!,
              displayName: book.ownerName ?? 'LeafMark user',
            ),
          ),
        ),
        onRequestSwap: isOwner || book.isLocked
            ? null
            : () => _showBookPickerSheet(context, authProvider),
        onEditListing: isOwner && !book.isLocked
            ? () async {
          final updatedBook = await Navigator.push<Book>(
            context,
            MaterialPageRoute(
              builder: (_) => EditBookListingScreen(book: book),
            ),
          );

          if (updatedBook != null && context.mounted) {
            Navigator.pop(context);
          }
        }
            : null,
      ),
    );
  }

  void _showBookPickerSheet(BuildContext context, AuthProvider authProvider) {
    final shelfBooks = context.read<BookShelfProvider>().availableBooks;

    if (shelfBooks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You need available books on your shelf to propose a swap.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetCtx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.68,
          minChildSize: 0.42,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
              child: Column(
                children: [
                  Text(
                    'Choose a book to offer',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Pick one of your available books to start a swap request.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.62),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.separated(
                      controller: scrollController,
                      itemCount: shelfBooks.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 8),
                      itemBuilder: (ctx, index) {
                        final offeredBook = shelfBooks[index];
                        final displayUrl = offeredBook.conditionPhotoUrls.isNotEmpty
                            ? offeredBook.conditionPhotoUrls.first
                            : offeredBook.coverUrl;

                        return Material(
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest
                              .withValues(alpha: 0.55),
                          borderRadius: BorderRadius.circular(18),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            leading: _MiniBookCover(url: displayUrl),
                            title: Text(
                              offeredBook.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.w800),
                            ),
                            subtitle: Text(
                              '${offeredBook.authors} · ${offeredBook.condition.label}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: const Icon(Icons.chevron_right_rounded),
                            onTap: () {
                              Navigator.pop(sheetCtx);
                              _submitSwap(context, authProvider, offeredBook);
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
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
            builder: (_) => ChatScreen(
              swapId: swapId,
              otherUserName: book.ownerName ?? 'LeafMark user',
              otherUserId: book.ownerId ?? '',
            ),
          ),
        );
      }
    } on DuplicateSwapException {
      if (context.mounted) {
        _showResultDialog(
          context,
          title: 'Already requested',
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
            behavior: SnackBarBehavior.floating,
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
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        icon: Icon(icon, color: iconColor, size: 52),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(message, textAlign: TextAlign.center),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}

class _BookGalleryAppBar extends StatefulWidget {
  final String title;
  final List<String> imageUrls;
  final bool isReserved;
  final bool hasRealPhotos;

  const _BookGalleryAppBar({
    required this.title,
    required this.imageUrls,
    required this.isReserved,
    required this.hasRealPhotos,
  });

  @override
  State<_BookGalleryAppBar> createState() => _BookGalleryAppBarState();
}

class _BookGalleryAppBarState extends State<_BookGalleryAppBar> {
  final _controller = PageController();
  int _currentIndex = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasImages = widget.imageUrls.isNotEmpty;

    return SliverAppBar(
      expandedHeight: 390,
      pinned: true,
      stretch: true,
      elevation: 0,
      title: Text(
        widget.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            if (hasImages)
              PageView.builder(
                controller: _controller,
                physics: const PageScrollPhysics(),
                itemCount: widget.imageUrls.length,
                onPageChanged: (index) => setState(() => _currentIndex = index),
                itemBuilder: (context, index) {
                  return Image.network(
                    widget.imageUrls[index],
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                    const _PlaceholderCover(),
                  );
                },
              )
            else
              const _PlaceholderCover(),
            const IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black54,
                      Colors.transparent,
                      Colors.black87,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 20,
              child: Row(
                children: [
                  if (widget.isReserved)
                    const _StatusPill(
                      icon: Icons.lock_outline_rounded,
                      label: 'Reserved',
                      color: Colors.orange,
                    )
                  else
                    _StatusPill(
                      icon: widget.hasRealPhotos
                          ? Icons.verified_outlined
                          : Icons.info_outline_rounded,
                      label: widget.hasRealPhotos ? 'Real photos' : 'Cover only',
                      color: widget.hasRealPhotos ? Colors.green : Colors.blueGrey,
                    ),
                  const Spacer(),
                  if (hasImages && widget.imageUrls.length > 1)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '${_currentIndex + 1}/${widget.imageUrls.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (hasImages && widget.imageUrls.length > 1)
              Positioned(
                left: 0,
                right: 0,
                bottom: 58,
                child: IgnorePointer(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(widget.imageUrls.length, (index) {
                      final selected = index == _currentIndex;

                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: selected ? 18 : 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: selected
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.55),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      );
                    }),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TitleSection extends StatelessWidget {
  final Book book;

  const _TitleSection({required this.book});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          book.title,
          style: textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w900,
            height: 1.08,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          book.authors,
          style: textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.64),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _MetaSection extends StatelessWidget {
  final Book book;

  const _MetaSection({required this.book});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _MetaChip(
          icon: Icons.auto_awesome_outlined,
          label: book.condition.label,
          color: _conditionColor(book.condition),
        ),
        if (book.category != null && book.category!.trim().isNotEmpty)
          _MetaChip(
            icon: Icons.auto_stories_outlined,
            label: book.category!,
            color: Colors.deepPurple,
          ),
        if (book.location != null && book.location!.trim().isNotEmpty)
          _MetaChip(
            icon: Icons.place_outlined,
            label: book.location!,
            color: Colors.teal,
          ),
        if (book.isbn.trim().isNotEmpty)
          _MetaChip(
            icon: Icons.qr_code_rounded,
            label: book.isbn,
            color: Colors.blueGrey,
          ),
      ],
    );
  }

  Color _conditionColor(BookCondition condition) {
    switch (condition) {
      case BookCondition.mint:
        return Colors.green.shade700;
      case BookCondition.good:
        return Colors.blue.shade700;
      case BookCondition.fair:
        return Colors.orange.shade700;
      case BookCondition.poor:
        return Colors.red.shade700;
    }
  }
}

class _OwnerCard extends StatelessWidget {
  final Book book;
  final bool isOwner;

  const _OwnerCard({
    required this.book,
    required this.isOwner,
  });

  @override
  Widget build(BuildContext context) {
    final ownerName = book.ownerName ?? 'LeafMark user';
    final initial = ownerName.trim().isNotEmpty
        ? ownerName.trim()[0].toUpperCase()
        : '?';

    return Material(
      color: Theme.of(context)
          .colorScheme
          .surfaceContainerHighest
          .withValues(alpha: 0.55),
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: book.ownerId == null
            ? null
            : () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PublicProfileScreen(
              userId: book.ownerId!,
              displayName: ownerName,
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 25,
                child: Text(
                  initial,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isOwner ? 'Listed by you' : 'Listed by $ownerName',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isOwner
                          ? 'This book is currently on your shelf.'
                          : 'View profile, shelf, reviews and wishlist.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.62),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  final Book book;

  const _InfoSection({required this.book});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Book details',
      child: Column(
        children: [
          _InfoRow(
            icon: Icons.menu_book_outlined,
            label: 'Title',
            value: book.title,
          ),
          _InfoRow(
            icon: Icons.person_outline,
            label: 'Author(s)',
            value: book.authors,
          ),
          if (book.category != null && book.category!.trim().isNotEmpty)
            _InfoRow(
              icon: Icons.auto_stories_outlined,
              label: 'Category',
              value: book.category!,
            ),
          _InfoRow(
            icon: Icons.auto_awesome_outlined,
            label: 'Condition',
            value: book.condition.label,
          ),
          if (book.location != null && book.location!.trim().isNotEmpty)
            _InfoRow(
              icon: Icons.place_outlined,
              label: 'Location',
              value: book.location!,
            ),
          if (book.isbn.trim().isNotEmpty)
            _InfoRow(
              icon: Icons.qr_code_rounded,
              label: 'ISBN',
              value: book.isbn,
              isLast: true,
            ),
        ],
      ),
    );
  }
}

class _NotesSection extends StatelessWidget {
  final String notes;

  const _NotesSection({required this.notes});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Condition notes',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.notes_rounded,
            size: 20,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              notes,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}

class _SwapReadinessSection extends StatelessWidget {
  final bool isOwner;
  final bool isReserved;
  final bool hasRealPhotos;

  const _SwapReadinessSection({
    required this.isOwner,
    required this.isReserved,
    required this.hasRealPhotos,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    IconData icon;
    Color color;
    String title;
    String message;

    if (isOwner) {
      icon = Icons.inventory_2_outlined;
      color = theme.colorScheme.primary;
      title = 'Your listing';
      message = 'Other readers can find this book and propose a swap.';
    } else if (isReserved) {
      icon = Icons.lock_outline_rounded;
      color = Colors.orange.shade700;
      title = 'Currently reserved';
      message = 'This book is involved in another swap and cannot be requested right now.';
    } else if (hasRealPhotos) {
      icon = Icons.verified_outlined;
      color = Colors.green.shade700;
      title = 'Ready to swap';
      message = 'This listing includes real condition photos uploaded by the owner.';
    } else {
      icon = Icons.info_outline_rounded;
      color = Colors.blueGrey.shade700;
      title = 'Ask before swapping';
      message = 'This listing only shows the cover. You can ask for more details in chat.';
    }

    return _SectionCard(
      title: 'Swap confidence',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.68),
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

class _BottomActionBar extends StatelessWidget {
  final bool isOwner;
  final bool isReserved;
  final bool isLoading;
  final double bottomPadding;
  final VoidCallback? onViewOwner;
  final VoidCallback? onRequestSwap;
  final VoidCallback? onEditListing;

  const _BottomActionBar({
    required this.isOwner,
    required this.isReserved,
    required this.isLoading,
    required this.bottomPadding,
    required this.onViewOwner,
    required this.onRequestSwap,
    required this.onEditListing,
  });

  @override
  Widget build(BuildContext context) {
    final disabledText = isReserved ? 'Reserved' : null;

    final primaryLabel = isOwner ? 'Edit listing' : 'Request swap';
    final primaryIcon = isOwner
        ? Icons.edit_outlined
        : Icons.swap_horiz_rounded;
    final primaryAction = isOwner ? onEditListing : onRequestSwap;

    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + bottomPadding),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            blurRadius: 18,
            offset: const Offset(0, -4),
            color: Colors.black.withValues(alpha: 0.08),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onViewOwner,
              icon: Icon(
                isOwner
                    ? Icons.inventory_2_outlined
                    : Icons.person_outline_rounded,
              ),
              label: Text(isOwner ? 'My shelf' : 'Owner'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: FilledButton.icon(
              onPressed: disabledText != null || isLoading ? null : primaryAction,
              icon: isLoading
                  ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
                  : Icon(primaryIcon),
              label: Text(disabledText ?? primaryLabel),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(22),
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
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isLast;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 19, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          SizedBox(
            width: 86,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.58),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
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
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _StatusPill({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          Icon(icon, size: 15, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniBookCover extends StatelessWidget {
  final String? url;

  const _MiniBookCover({required this.url});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: url != null
          ? Image.network(
        url!,
        width: 42,
        height: 60,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
        const _MiniPlaceholderCover(),
      )
          : const _MiniPlaceholderCover(),
    );
  }
}

class _MiniPlaceholderCover extends StatelessWidget {
  const _MiniPlaceholderCover();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 60,
      color: Colors.grey[200],
      child: const Icon(Icons.book_outlined, color: Colors.grey),
    );
  }
}

class _PlaceholderCover extends StatelessWidget {
  const _PlaceholderCover();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[200],
      child: const Center(
        child: Icon(Icons.book_outlined, size: 80, color: Colors.grey),
      ),
    );
  }
}