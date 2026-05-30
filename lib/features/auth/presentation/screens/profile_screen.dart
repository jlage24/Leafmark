import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/app_theme.dart';
import '../../../../features/books/presentation/providers/book_shelf_provider.dart';
import '../../../../features/books/presentation/screens/my_shelf_screen.dart';
import '../../../books/presentation/providers/follow_provider.dart';
import '../../../notifications/presentation/providers/notification_provider.dart';
import '../../../notifications/presentation/screens/notifications_screen.dart';
import '../../../ratings/domain/models/rating.dart';
import '../../../ratings/presentation/providers/rating_provider.dart';
import '../../../swaps/presentation/providers/swap_provider.dart';
import '../../../swaps/presentation/screens/exchange_history_screen.dart';
import '../../../wishlist/presentation/screens/wishlist_screen.dart';
import '../providers/auth_provider.dart';
import '../widgets/profile_badges.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    context.read<BookShelfProvider>().clearBooks();
    await context.read<AuthProvider>().logout();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final shelf = context.watch<BookShelfProvider>();
    final theme = Theme.of(context);

    final initial = user?.displayName.isNotEmpty == true
        ? user!.displayName[0].toUpperCase()
        : '?';

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.only(bottom: 28),
        children: [
          _ProfileHero(
            title: 'Profile',
            displayName: user?.displayName ?? '',
            initial: initial,
            profilePictureUrl: user?.profilePictureUrl,
            bannerPictureUrl: user?.bannerPictureUrl,
            onEdit: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const EditProfileScreen()),
              );
            },
          ),
          const SizedBox(height: 48),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                Text(
                  user?.displayName ?? '',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.4,
                  ),
                ),
                if (user?.username.isNotEmpty == true) ...[
                  const SizedBox(height: 4),
                  Text(
                    '@${user!.username}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.58),
                    ),
                  ),
                ],
                if (user?.bio != null && user!.bio!.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Text(
                    user.bio!,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
                const SizedBox(height: 18),
                _FollowCounts(userId: user?.uid ?? ''),
                const SizedBox(height: 22),
                Row(
                  children: [
                    _StatCard(label: 'Books', value: '${shelf.books.length}'),
                    const SizedBox(width: 10),
                    StreamBuilder<int>(
                      stream: context.read<SwapProvider>().exchangeCount(user?.uid ?? ''),
                      builder: (context, snapshot) {
                        return _StatCard(
                          label: 'Swaps',
                          value: snapshot.hasData ? '${snapshot.data}' : '—',
                        );
                      },
                    ),
                    const SizedBox(width: 10),
                    StreamBuilder<List<Rating>>(
                      stream: context.read<RatingProvider>().getRatingsForUser(user?.uid ?? ''),
                      builder: (context, snapshot) {
                        var ratingValue = '—';

                        if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                          final ratings = snapshot.data!;
                          final total = ratings.fold<int>(0, (sum, item) => sum + item.rating);
                          ratingValue = (total / ratings.length).toStringAsFixed(1);
                        }

                        return _StatCard(label: 'Rating', value: ratingValue);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          ProfileBadges(
            userId: user?.uid ?? '',
            shelfCount: shelf.books.length,
          ),
          const SizedBox(height: 18),
          if (user?.favoriteAuthors != null && user!.favoriteAuthors.isNotEmpty)
            _ProfileSection(
              title: 'Favorite Authors',
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: user.favoriteAuthors.map((author) {
                  return Chip(
                    label: Text(author),
                    backgroundColor: AppTheme.primaryLight.withValues(alpha: 0.5),
                    side: BorderSide.none,
                  );
                }).toList(),
              ),
            ),
          if (user?.favoriteBookTitle != null && user!.favoriteBookTitle!.isNotEmpty)
            _ProfileSection(
              title: 'Favorite Book',
              child: _FavoriteBookCard(
                title: user.favoriteBookTitle!,
                author: user.favoriteBookAuthor,
                coverUrl: user.favoriteBookCoverUrl,
              ),
            ),
          const SizedBox(height: 8),
          _MenuSection(
            children: [
              _MenuItem(
                iconData: Icons.menu_book_outlined,
                iconBgColor: const Color(0xFFEAF3DE),
                iconColor: const Color(0xFF3B6D11),
                title: 'My Shelf',
                subtitle: '${shelf.books.length} books available',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MyShelfScreen()),
                ),
              ),
              _MenuItem(
                iconData: Icons.history_rounded,
                iconBgColor: const Color(0xFFE8F0FA),
                iconColor: const Color(0xFF2A5BA8),
                title: 'Exchange History',
                subtitle: 'Your completed swaps',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ExchangeHistoryScreen()),
                ),
              ),
              _MenuItem(
                iconData: Icons.bookmark_outline_rounded,
                iconBgColor: const Color(0xFFF3EAF5),
                iconColor: const Color(0xFF7A3BA1),
                title: 'My Wishlist',
                subtitle: 'Books you\'re looking for',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => WishlistScreen(uid: user?.uid ?? ''),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _MenuSection(
            children: [
              _MenuItem(
                iconData: Icons.logout_rounded,
                iconBgColor: const Color(0xFFFCEBEB),
                iconColor: const Color(0xFFA32D2D),
                title: 'Logout',
                titleColor: const Color(0xFFA32D2D),
                onTap: () => _logout(context),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProfileHero extends StatelessWidget {
  final String title;
  final String displayName;
  final String initial;
  final String? profilePictureUrl;
  final String? bannerPictureUrl;
  final VoidCallback onEdit;

  const _ProfileHero({
    required this.title,
    required this.displayName,
    required this.initial,
    required this.profilePictureUrl,
    required this.bannerPictureUrl,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final hasBanner = bannerPictureUrl != null && bannerPictureUrl!.isNotEmpty;
    final hasAvatar = profilePictureUrl != null && profilePictureUrl!.isNotEmpty;

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.bottomCenter,
      children: [
        Container(
          height: 150,
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
          decoration: BoxDecoration(
            color: AppTheme.primary,
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
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.primaryLight,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              StreamBuilder<int>(
                stream: context.read<NotificationProvider>().unreadCount(),
                builder: (context, snapshot) {
                  final count = snapshot.data ?? 0;

                  return _HeroIconButton(
                    tooltip: 'Notifications',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const NotificationsScreen(),
                        ),
                      );
                    },
                    child: Badge(
                      isLabelVisible: count > 0,
                      label: Text(count > 99 ? '99+' : '$count'),
                      child: const Icon(
                        Icons.notifications_none_rounded,
                        size: 20,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(width: 8),
              _HeroIconButton(
                tooltip: 'Edit profile',
                onPressed: onEdit,
                child: const Icon(Icons.edit_outlined, size: 20),
              ),
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
              backgroundColor: AppTheme.primaryLight,
              backgroundImage:
              hasAvatar ? NetworkImage(profilePictureUrl!) : null,
              child: !hasAvatar
                  ? Text(
                initial,
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.primary,
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

class _FollowCounts extends StatelessWidget {
  final String userId;

  const _FollowCounts({required this.userId});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        StreamBuilder<int>(
          stream: context.read<FollowProvider>().getFollowersCount(userId),
          builder: (context, snapshot) {
            return _FollowCountText(
              value: snapshot.hasData ? '${snapshot.data}' : '-',
              label: 'Followers',
              color: theme.colorScheme.onSurface,
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
          stream: context.read<FollowProvider>().getFollowingCount(userId),
          builder: (context, snapshot) {
            return _FollowCountText(
              value: '${snapshot.data ?? 0}',
              label: 'Following',
              color: theme.colorScheme.onSurface,
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

  const _FollowCountText({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Text.rich(
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
    );
  }
}

class _ProfileSection extends StatelessWidget {
  final String title;
  final Widget child;

  const _ProfileSection({
    required this.title,
    required this.child,
  });

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
          Text(title, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900)),
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
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 64,
            height: 92,
            color: Colors.grey[200],
            child: hasCover
                ? Image.network(
              coverUrl!,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => const Icon(Icons.book, color: Colors.grey),
            )
                : const Icon(Icons.book, color: Colors.grey),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
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
          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.75),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (label == 'Rating' && value != '—') ...[
                  const Icon(Icons.star_rounded, size: 17, color: AppTheme.accent),
                  const SizedBox(width: 3),
                ],
                Text(
                  value,
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
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

class _MenuSection extends StatelessWidget {
  final List<Widget> children;

  const _MenuSection({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
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
      child: Column(children: children),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData iconData;
  final Color iconBgColor;
  final Color iconColor;
  final String title;
  final Color? titleColor;
  final String? subtitle;
  final VoidCallback onTap;

  const _MenuItem({
    required this.iconData,
    required this.iconBgColor,
    required this.iconColor,
    required this.title,
    required this.onTap,
    this.titleColor,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: iconBgColor,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(iconData, size: 21, color: iconColor),
      ),
      title: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: titleColor,
          fontWeight: FontWeight.w800,
        ),
      ),
      subtitle: subtitle != null ? Text(subtitle!) : null,
      trailing: subtitle != null ? const Icon(Icons.chevron_right_rounded) : null,
      onTap: onTap,
    );
  }
}