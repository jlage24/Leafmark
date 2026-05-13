import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:provider/provider.dart';
import '../../../../core/app_theme.dart';
import '../../../books/domain/models/book.dart';
import '../../../books/presentation/screens/book_detail_screen.dart';
import '../../../ratings/data/services/rating_service.dart';
import '../../../ratings/domain/models/rating.dart';
import '../../../ratings/presentation/providers/rating_provider.dart';

class PublicProfileScreen extends StatefulWidget {
  final String userId;
  final String displayName;

  const PublicProfileScreen({
    super.key,
    required this.userId,
    required this.displayName,
  });

  @override
  State<PublicProfileScreen> createState() => _PublicProfileScreenState();
}

class _PublicProfileScreenState extends State<PublicProfileScreen> {
  late final Future<Map<String, dynamic>?> _profileFuture;
  late final Future<int> _shelfCountFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture = _fetchProfile();
    _shelfCountFuture = _fetchShelfCount();
  }

  Future<Map<String, dynamic>?> _fetchProfile() async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .get();
    return doc.data();
  }

  Future<int> _fetchShelfCount() async {
    final snap = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .collection('shelf')
        .count()
        .get();
    return snap.count ?? 0;
  }

  Widget _bookPlaceholder() => Container(
    width: 64,
    height: 92,
    decoration: BoxDecoration(
        color: Colors.grey[200], borderRadius: BorderRadius.circular(6)),
    child: const Icon(Icons.book, color: Colors.grey),
  );

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _profileFuture,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snap.data;
          final username = data?['username'] as String? ?? '';
          final bio = data?['bio'] as String?;
          final profilePicUrl = data?['profilePictureUrl'] as String?;
          final bannerPicUrl = data?['bannerPictureUrl'] as String?;
          final favoriteAuthors =
          List<String>.from(data?['favoriteAuthors'] ?? []);
          final favBookTitle = data?['favoriteBookTitle'] as String?;
          final favBookAuthor = data?['favoriteBookAuthor'] as String?;
          final favBookCoverUrl = data?['favoriteBookCoverUrl'] as String?;
          final initial = widget.displayName.isNotEmpty
              ? widget.displayName[0].toUpperCase()
              : '?';

          return ListView(
            padding: const EdgeInsets.only(bottom: 32),
            children: [
              Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.bottomCenter,
                children: [
                  Container(
                    height: 120,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppTheme.primary,
                      image: bannerPicUrl != null && bannerPicUrl.isNotEmpty
                          ? DecorationImage(
                          image: NetworkImage(bannerPicUrl),
                          fit: BoxFit.cover)
                          : null,
                    ),
                    padding: const EdgeInsets.fromLTRB(16, 32, 16, 0),
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.3),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new,
                              size: 18, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -36,
                    child: CircleAvatar(
                      radius: 36,
                      backgroundColor: AppTheme.background,
                      child: CircleAvatar(
                        radius: 33,
                        backgroundColor: AppTheme.primaryLight,
                        backgroundImage:
                        profilePicUrl != null && profilePicUrl.isNotEmpty
                            ? NetworkImage(profilePicUrl)
                            : null,
                        child: (profilePicUrl == null || profilePicUrl.isEmpty)
                            ? Text(initial,
                            style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.primary))
                            : null,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 48),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    Text(widget.displayName,
                        style: textTheme.titleLarge,
                        textAlign: TextAlign.center),
                    const SizedBox(height: 4),
                    if (username.isNotEmpty)
                      Text('@$username',
                          style: textTheme.bodySmall,
                          textAlign: TextAlign.center),
                    if (bio != null && bio.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(bio,
                          style: textTheme.bodyMedium,
                          textAlign: TextAlign.center),
                    ],
                    const SizedBox(height: 24),
                    FutureBuilder<int>(
                      future: _shelfCountFuture,
                      builder: (context, shelfSnap) {
                        final count = shelfSnap.data ?? 0;
                        return Row(
                          children: [
                            _StatCard(
                                label: 'Books',
                                value: shelfSnap.hasData ? '$count' : '…'),
                            const SizedBox(width: 8),
                            _StatCard(label: 'Swaps', value: '—'),
                            const SizedBox(width: 8),

                            StreamBuilder<List<Rating>>(
                              stream: context.read<RatingProvider>().getRatingsForUser(widget.userId),
                              builder: (context, snapshot) {
                                String ratingValue = '—';

                                if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                                  final ratings = snapshot.data!;
                                  final totalStars = ratings.fold<int>(0, (total, item) => total + item.rating);
                                  final average = totalStars / ratings.length;
                                  ratingValue = average.toStringAsFixed(1);
                                }

                                return _StatCard(label: 'Rating', value: ratingValue);
                              },
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              if (favoriteAuthors.isNotEmpty) ...[
                const Divider(),
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Favorite Authors', style: textTheme.titleSmall),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: favoriteAuthors
                            .map((author) => Chip(
                          label: Text(author),
                          backgroundColor: AppTheme.primaryLight
                              .withValues(alpha: 0.5),
                          side: BorderSide.none,
                        ))
                            .toList(),
                      ),
                    ],
                  ),
                ),
              ],

              if (favBookTitle != null && favBookTitle.isNotEmpty) ...[
                const Divider(),
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Favorite Book', style: textTheme.titleSmall),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: favBookCoverUrl != null &&
                                favBookCoverUrl.isNotEmpty
                                ? Image.network(
                              favBookCoverUrl,
                              width: 64,
                              height: 92,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stack) =>
                                  _bookPlaceholder(),
                            )
                                : _bookPlaceholder(),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(favBookTitle,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16)),
                                const SizedBox(height: 4),
                                if (favBookAuthor != null)
                                  Text(favBookAuthor,
                                      style: TextStyle(
                                          color: Colors.grey[700],
                                          fontSize: 14)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],

              const Divider(),
              Padding(
                padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child:
                Text('Available books', style: textTheme.titleSmall),
              ),
              _ShelfPreview(userId: widget.userId),
            ],
          );
        },
      ),
    );
  }
}

class _ShelfPreview extends StatefulWidget {
  final String userId;
  const _ShelfPreview({required this.userId});

  @override
  State<_ShelfPreview> createState() => _ShelfPreviewState();
}

class _ShelfPreviewState extends State<_ShelfPreview> {
  late final Future<QuerySnapshot> _shelfFuture;

  @override
  void initState() {
    super.initState();
    _shelfFuture = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .collection('shelf')
        .where('lockedBySwapId', isNull: true)
        .limit(10)
        .get();
  }

  Widget _bookPlaceholder() => Container(
    width: 64,
    height: 92,
    decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(6)),
    child: const Icon(Icons.book, color: Colors.grey),
  );

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<QuerySnapshot>(
      future: _shelfFuture,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()));
        }
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'No books available for swap right now.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          );
        }
        return SizedBox(
          height: 140,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemCount: docs.length,
            separatorBuilder: (context, index) => const SizedBox(width: 10),
            itemBuilder: (context, i) {
              final data = docs[i].data() as Map<String, dynamic>;
              final book = Book.fromJson({...data, 'id': docs[i].id});
              return GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        BookDetailScreen(book: book, isOwner: false),
                  ),
                ),
                child: Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: book.coverUrl != null
                          ? Image.network(
                        book.coverUrl!,
                        width: 64,
                        height: 92,
                        fit: BoxFit.cover,
                        errorBuilder: (c, e, s) => _bookPlaceholder(),
                      )
                          : _bookPlaceholder(),
                    ),
                    const SizedBox(height: 6),
                    SizedBox(
                      width: 64,
                      child: Text(
                        book.title,
                        style: const TextStyle(fontSize: 10),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  const _StatCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(10)),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (label == 'Rating' && value != '—')
                  const Icon(Icons.star, size: 16, color: AppTheme.accent),
                if (label == 'Rating' && value != '—')
                  const SizedBox(width: 4),
                Text(value, style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 2),
            Text(label, style: Theme.of(context).textTheme.labelSmall),
          ],
        ),
      ),
    );
  }
}