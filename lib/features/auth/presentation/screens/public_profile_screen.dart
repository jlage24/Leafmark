import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:rxdart/rxdart.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../books/data/services/browse_service.dart';
import '../../../books/domain/models/book.dart';
import '../../../books/presentation/providers/block_provider.dart';
import '../../../books/presentation/providers/follow_provider.dart';
import '../../../books/presentation/screens/book_detail_screen.dart';
import '../../../ratings/domain/models/rating.dart';
import '../../../ratings/presentation/providers/rating_provider.dart';
import '../../../reports/data/services/report_service.dart';
import '../../../reports/domain/models/report.dart';
import '../../../swaps/presentation/providers/swap_provider.dart';
import '../../../wishlist/domain/models/wishlist_item.dart';
import '../../../wishlist/presentation/providers/wishlist_provider.dart';
import '../widgets/profile_badges.dart';
import '../../../books/presentation/screens/follow_list_screen.dart';

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

  void _showReportSheet(BuildContext context) {
    const reasons = ['Spam', 'Inappropriate behavior', 'Fake account', 'Other'];

    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetCtx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Report user',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Why are you reporting this profile?',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.62),
                  ),
                ),
                const SizedBox(height: 14),
                ...reasons.map(
                  (reason) => _ReportReasonTile(
                    reason: reason,
                    onTap: () async {
                      Navigator.pop(sheetCtx);

                      final uid = context.read<AuthProvider>().user?.uid ?? '';

                      try {
                        await ReportService().submitReport(
                          Report(
                            reporterId: uid,
                            reportedUid: widget.userId,
                            reason: reason,
                            createdAt: DateTime.now(),
                          ),
                        );

                        if (!context.mounted) return;

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Report submitted. Thank you.'),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        );
                      } catch (e) {
                        if (!context.mounted) return;

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text(
                              'Failed to submit report. Please try again.',
                            ),
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.error,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUid = context.read<AuthProvider>().user?.uid ?? '';
    final isOwnProfile = currentUid == widget.userId;

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
          final favoriteAuthors = List<String>.from(
            data?['favoriteAuthors'] ?? [],
          );
          final favBookTitle = data?['favoriteBookTitle'] as String?;
          final favBookAuthor = data?['favoriteBookAuthor'] as String?;
          final favBookCoverUrl = data?['favoriteBookCoverUrl'] as String?;

          final initial = widget.displayName.isNotEmpty
              ? widget.displayName[0].toUpperCase()
              : '?';

          return ListView(
            padding: const EdgeInsets.only(bottom: 32),
            children: [
              _PublicProfileHero(
                displayName: widget.displayName,
                initial: initial,
                profilePictureUrl: profilePicUrl,
                bannerPictureUrl: bannerPicUrl,
                isOwnProfile: isOwnProfile,
                currentUid: currentUid,
                userId: widget.userId,
                onReport: () => _showReportSheet(context),
                onShare: () {
                  final text =
                      'Check out ${widget.displayName} (@$username) on LeafMark! 📚✨';
                  Clipboard.setData(ClipboardData(text: text));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Profile details copied for @$username!'),
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 48),
              _PublicProfileInfo(
                userId: widget.userId,
                displayName: widget.displayName,
                username: username,
                bio: bio,
                isOwnProfile: isOwnProfile,
                currentUid: currentUid,
                shelfCountFuture: _shelfCountFuture,
              ),
              FutureBuilder<int>(
                future: _shelfCountFuture,
                builder: (context, shelfSnap) {
                  return ProfileBadges(
                    userId: widget.userId,
                    shelfCount: shelfSnap.data ?? 0,
                  );
                },
              ),
              const SizedBox(height: 18),
              if (favoriteAuthors.isNotEmpty)
                _ProfileSection(
                  title: 'Favorite Authors',
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: favoriteAuthors.map((author) {
                      return Chip(
                        label: Text(author),
                        backgroundColor: Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.15),
                        side: BorderSide.none,
                      );
                    }).toList(),
                  ),
                ),
              if (favBookTitle != null && favBookTitle.isNotEmpty)
                _ProfileSection(
                  title: 'Favorite Book',
                  child: _FavoriteBookCard(
                    title: favBookTitle,
                    author: favBookAuthor,
                    coverUrl: favBookCoverUrl,
                  ),
                ),
              _ProfileSection(
                title: 'Available books',
                child: _ShelfPreview(userId: widget.userId),
              ),
              _ProfileSection(
                title: 'Wishlist',
                child: _WishlistPreview(userId: widget.userId),
              ),
              _ProfileSection(
                title: 'Reviews',
                child: _ReviewsPreview(userId: widget.userId),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _PublicProfileHero extends StatelessWidget {
  final String displayName;
  final String initial;
  final String? profilePictureUrl;
  final String? bannerPictureUrl;
  final bool isOwnProfile;
  final String currentUid;
  final String userId;
  final VoidCallback onReport;
  final VoidCallback onShare;

  const _PublicProfileHero({
    required this.displayName,
    required this.initial,
    required this.profilePictureUrl,
    required this.bannerPictureUrl,
    required this.isOwnProfile,
    required this.currentUid,
    required this.userId,
    required this.onReport,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    final hasBanner = bannerPictureUrl != null && bannerPictureUrl!.isNotEmpty;
    final hasAvatar =
        profilePictureUrl != null && profilePictureUrl!.isNotEmpty;

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.bottomCenter,
      children: [
        Container(
          height: 150,
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(12, 18, 12, 0),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            image: hasBanner
                ? DecorationImage(
                    image: NetworkImage(bannerPictureUrl!),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _HeroIconButton(
                tooltip: 'Back',
                onPressed: () => Navigator.pop(context),
                child: const Icon(Icons.arrow_back_rounded, size: 20),
              ),
              const Spacer(),
              _HeroIconButton(
                tooltip: 'Share profile',
                onPressed: onShare,
                child: const Icon(Icons.share_outlined, size: 20),
              ),
              if (!isOwnProfile) ...[
                const SizedBox(width: 8),
                StreamBuilder<List<String>>(
                  stream: context.read<BlockProvider>().getBlockedUsers(
                    currentUid,
                  ),
                  builder: (context, snapshot) {
                    final isBlocked = snapshot.data?.contains(userId) ?? false;

                    return _HeroIconButton(
                      tooltip: isBlocked ? 'Unblock user' : 'Block user',
                      onPressed: () async {
                        if (isBlocked) {
                          await context.read<BlockProvider>().unblockUser(
                            currentUid,
                            userId,
                          );

                          if (!context.mounted) return;

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('User unblocked.')),
                          );
                        } else {
                          await context.read<BlockProvider>().blockUser(
                            currentUid,
                            userId,
                          );

                          if (!context.mounted) return;

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('User blocked.')),
                          );
                        }
                      },
                      child: Icon(
                        isBlocked
                            ? Icons.block_rounded
                            : Icons.pan_tool_outlined,
                        size: 20,
                      ),
                    );
                  },
                ),
                const SizedBox(width: 8),
                _HeroIconButton(
                  tooltip: 'Report user',
                  onPressed: onReport,
                  child: const Icon(Icons.flag_outlined, size: 20),
                ),
              ],
            ],
          ),
        ),
        Positioned(
          bottom: -38,
          child: CircleAvatar(
            radius: 42,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            child: CircleAvatar(
              radius: 38,
              backgroundColor: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.16),
              backgroundImage: hasAvatar
                  ? NetworkImage(profilePictureUrl!)
                  : null,
              child: !hasAvatar
                  ? Text(
                      initial,
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    )
                  : null,
            ),
          ),
        ),
      ],
    );
  }
}

class _PublicProfileInfo extends StatefulWidget {
  final String userId;
  final String displayName;
  final String username;
  final String? bio;
  final bool isOwnProfile;
  final String currentUid;
  final Future<int> shelfCountFuture;

  const _PublicProfileInfo({
    required this.userId,
    required this.displayName,
    required this.username,
    required this.bio,
    required this.isOwnProfile,
    required this.currentUid,
    required this.shelfCountFuture,
  });

  @override
  State<_PublicProfileInfo> createState() => _PublicProfileInfoState();
}

class _PublicProfileInfoState extends State<_PublicProfileInfo> {
  late final Stream<int> _exchangeCountStream;
  late final Stream<List<Rating>> _ratingsStream;

  @override
  void initState() {
    super.initState();
    _exchangeCountStream = context
        .read<SwapProvider>()
        .exchangeCount(widget.userId)
        .shareValue();
    _ratingsStream = context
        .read<RatingProvider>()
        .getRatingsForUser(widget.userId)
        .shareValue();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Text(
            widget.displayName,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w900,
              letterSpacing: -0.4,
            ),
          ),
          if (widget.username.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              '@${widget.username}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.58),
              ),
            ),
          ],
          if (widget.bio != null && widget.bio!.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              widget.bio!,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
          ],
          const SizedBox(height: 18),
          _FollowCounts(userId: widget.userId),
          if (!widget.isOwnProfile) ...[
            const SizedBox(height: 16),
            _FollowButton(currentUid: widget.currentUid, userId: widget.userId),
          ],
          const SizedBox(height: 22),
          FutureBuilder<int>(
            future: widget.shelfCountFuture,
            builder: (context, shelfSnap) {
              final count = shelfSnap.data ?? 0;

              return Row(
                children: [
                  _StatCard(
                    label: 'Books',
                    value: shelfSnap.hasData ? '$count' : '-',
                  ),
                  const SizedBox(width: 10),
                  StreamBuilder<int>(
                    stream: _exchangeCountStream,
                    builder: (context, snapshot) {
                      return _StatCard(
                        label: 'Swaps',
                        value: snapshot.hasData ? '${snapshot.data}' : '—',
                      );
                    },
                  ),
                  const SizedBox(width: 10),
                  StreamBuilder<List<Rating>>(
                    stream: _ratingsStream,
                    builder: (context, snapshot) {
                      var ratingValue = '—';

                      if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                        final ratings = snapshot.data!;
                        final total = ratings.fold<int>(
                          0,
                          (totalStars, item) => totalStars + item.rating,
                        );
                        ratingValue = (total / ratings.length).toStringAsFixed(
                          1,
                        );
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
    );
  }
}

class _FollowButton extends StatefulWidget {
  final String currentUid;
  final String userId;

  const _FollowButton({required this.currentUid, required this.userId});

  @override
  State<_FollowButton> createState() => _FollowButtonState();
}

class _FollowButtonState extends State<_FollowButton> {
  late final Stream<bool> _isFollowingStream;

  @override
  void initState() {
    super.initState();
    _isFollowingStream = context
        .read<FollowProvider>()
        .isFollowing(widget.currentUid, widget.userId)
        .shareValue();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: _isFollowingStream,
      builder: (context, snapshot) {
        final isFollowing = snapshot.data ?? false;

        return SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: () async {
              try {
                if (isFollowing) {
                  await context.read<FollowProvider>().unfollowUser(
                    widget.currentUid,
                    widget.userId,
                  );
                } else {
                  await context.read<FollowProvider>().followUser(
                    widget.currentUid,
                    widget.userId,
                  );
                }
              } catch (e) {
                if (!context.mounted) return;

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(e.toString().replaceAll('Exception: ', '')),
                    backgroundColor: Theme.of(context).colorScheme.error,
                  ),
                );
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: isFollowing
                  ? Theme.of(context).colorScheme.surfaceContainerHighest
                  : Theme.of(context).colorScheme.primary,
              foregroundColor: isFollowing
                  ? Theme.of(context).colorScheme.onSurface
                  : Colors.white,
              elevation: isFollowing ? 0 : 1,
              padding: const EdgeInsets.symmetric(vertical: 13),
            ),
            icon: Icon(
              isFollowing ? Icons.check_rounded : Icons.person_add_alt_rounded,
              size: 18,
            ),
            label: Text(isFollowing ? 'Following' : 'Follow'),
          ),
        );
      },
    );
  }
}

class _HeroIconButton extends StatelessWidget {
  final String tooltip;
  final VoidCallback onPressed;
  final Widget child;

  const _HeroIconButton({
    required this.tooltip,
    required this.onPressed,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.25),
      shape: const CircleBorder(),
      child: IconButton(
        tooltip: tooltip,
        color: Colors.white,
        onPressed: onPressed,
        icon: child,
      ),
    );
  }
}

class _FollowCounts extends StatefulWidget {
  final String userId;

  const _FollowCounts({required this.userId});

  @override
  State<_FollowCounts> createState() => _FollowCountsState();
}

class _FollowCountsState extends State<_FollowCounts> {
  late final Stream<int> _followersStream;
  late final Stream<int> _followingStream;

  @override
  void initState() {
    super.initState();
    _followersStream = context
        .read<FollowProvider>()
        .getFollowersCount(widget.userId)
        .shareValue();
    _followingStream = context
        .read<FollowProvider>()
        .getFollowingCount(widget.userId)
        .shareValue();
  }

  void _openList(BuildContext context, FollowListType type) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FollowListScreen(userId: widget.userId, type: type),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        StreamBuilder<int>(
          stream: _followersStream,
          builder: (context, snapshot) {
            return _FollowCountText(
              value: snapshot.hasData ? '${snapshot.data}' : '-',
              label: 'Followers',
              color: theme.colorScheme.onSurface,
              onTap: () => _openList(context, FollowListType.followers),
            );
          },
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 14),
          width: 1,
          height: 18,
          color: theme.colorScheme.outline.withValues(alpha: 0.25),
        ),
        StreamBuilder<int>(
          stream: _followingStream,
          builder: (context, snapshot) {
            return _FollowCountText(
              value: '${snapshot.data ?? 0}',
              label: 'Following',
              color: theme.colorScheme.onSurface,
              onTap: () => _openList(context, FollowListType.following),
            );
          },
        ),
      ],
    );
  }
}

class _FollowCountText extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _FollowCountText({
    required this.value,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: value,
                style: TextStyle(fontWeight: FontWeight.w900, color: color),
              ),
              TextSpan(
                text: ' $label',
                style: TextStyle(color: color.withValues(alpha: 0.65)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileSection extends StatelessWidget {
  final String title;
  final Widget child;

  const _ProfileSection({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 14),
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
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _FavoriteBookCard extends StatelessWidget {
  final String title;
  final String? author;
  final String? coverUrl;

  const _FavoriteBookCard({
    required this.title,
    required this.author,
    required this.coverUrl,
  });

  @override
  Widget build(BuildContext context) {
    final hasCover = coverUrl != null && coverUrl!.isNotEmpty;

    return Row(
      children: [
        _BookCover(coverUrl: hasCover ? coverUrl : null),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
              if (author != null && author!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(author!, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ],
          ),
        ),
      ],
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

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<QuerySnapshot>(
      future: _shelfFuture,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const _SectionLoading();
        }

        final docs = snap.data?.docs ?? [];

        if (docs.isEmpty) {
          return const _SectionEmptyText(
            text: 'No books available for swap right now.',
          );
        }

        return SizedBox(
          height: 142,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: docs.length,
            separatorBuilder: (context, index) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final book = Book.fromJson({...data, 'id': docs[index].id});

              return _ShelfBookPreview(
                book: book,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          BookDetailScreen(book: book, isOwner: false),
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}

class _ShelfBookPreview extends StatelessWidget {
  final Book book;
  final VoidCallback onTap;

  const _ShelfBookPreview({required this.book, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final coverUrl = book.conditionPhotoUrls.isNotEmpty
        ? book.conditionPhotoUrls.first
        : book.coverUrl;

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 76,
        child: Column(
          children: [
            _BookCover(coverUrl: coverUrl),
            const SizedBox(height: 7),
            Text(
              book.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

class _WishlistPreview extends StatefulWidget {
  final String userId;

  const _WishlistPreview({required this.userId});

  @override
  State<_WishlistPreview> createState() => _WishlistPreviewState();
}

class _WishlistPreviewState extends State<_WishlistPreview> {
  late final Stream<List<WishlistItem>> _wishlistStream;

  @override
  void initState() {
    super.initState();
    _wishlistStream = context
        .read<WishlistProvider>()
        .getWishlist(widget.userId)
        .shareValue();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<WishlistItem>>(
      stream: _wishlistStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _SectionLoading();
        }

        final items = snapshot.data ?? [];

        if (items.isEmpty) {
          return const _SectionEmptyText(text: 'No books on the wishlist yet.');
        }

        return Column(
          children: items.map((item) {
            return _WishlistTile(item: item);
          }).toList(),
        );
      },
    );
  }
}

class _WishlistTile extends StatelessWidget {
  final WishlistItem item;

  const _WishlistTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final authors = item.authors.isNotEmpty ? item.authors.join(', ') : null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(
              Icons.bookmark_outline_rounded,
              size: 19,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800),
                ),
                if (authors != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    authors,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewsPreview extends StatefulWidget {
  final String userId;

  const _ReviewsPreview({required this.userId});

  @override
  State<_ReviewsPreview> createState() => _ReviewsPreviewState();
}

class _ReviewsPreviewState extends State<_ReviewsPreview> {
  late final Stream<List<Rating>> _ratingsStream;

  @override
  void initState() {
    super.initState();
    _ratingsStream = context
        .read<RatingProvider>()
        .getRatingsForUser(widget.userId)
        .shareValue();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Rating>>(
      stream: _ratingsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _SectionLoading();
        }

        final ratings = snapshot.data ?? [];
        final reviews = ratings
            .where(
              (rating) =>
                  rating.comment != null && rating.comment!.trim().isNotEmpty,
            )
            .toList();

        if (reviews.isEmpty) {
          return const _SectionEmptyText(text: 'No written reviews yet.');
        }

        return Column(
          children: reviews.map((review) {
            return _ReviewTile(review: review);
          }).toList(),
        );
      },
    );
  }
}

class _ReviewTile extends StatelessWidget {
  final Rating review;

  const _ReviewTile({required this.review});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: BrowseService().fetchDisplayName(review.reviewerId),
      builder: (context, snapshot) {
        final reviewerName = snapshot.data ?? 'Anonymous';

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      reviewerName,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  Row(
                    children: List.generate(5, (index) {
                      return Icon(
                        index < review.rating
                            ? Icons.star_rounded
                            : Icons.star_border_rounded,
                        size: 15,
                        color: Colors.amber,
                      );
                    }),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                review.comment!,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ReportReasonTile extends StatelessWidget {
  final String reason;
  final VoidCallback onTap;

  const _ReportReasonTile({required this.reason, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(
        context,
      ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.55),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  reason,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
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

class _BookCover extends StatelessWidget {
  final String? coverUrl;

  const _BookCover({required this.coverUrl});

  @override
  Widget build(BuildContext context) {
    final hasCover = coverUrl != null && coverUrl!.isNotEmpty;

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 64,
        height: 92,
        color: Colors.grey[200],
        child: hasCover
            ? Image.network(
                coverUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.book, color: Colors.grey),
              )
            : const Icon(Icons.book, color: Colors.grey),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;

  const _StatCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(
            alpha: 0.75,
          ),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (label == 'Rating' && value != '—') ...[
                  Icon(
                    Icons.star_rounded,
                    size: 17,
                    color: theme.colorScheme.tertiary,
                  ),
                  const SizedBox(width: 3),
                ],
                Text(
                  value,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 3),
            Text(label, style: theme.textTheme.labelSmall),
          ],
        ),
      ),
    );
  }
}

class _SectionLoading extends StatelessWidget {
  const _SectionLoading();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 18),
      child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
    );
  }
}

class _SectionEmptyText extends StatelessWidget {
  final String text;

  const _SectionEmptyText({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.62),
      ),
    );
  }
}
