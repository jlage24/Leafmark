import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../ratings/presentation/providers/rating_provider.dart';
import '../../../swaps/presentation/providers/swap_provider.dart';
import '../providers/auth_provider.dart';
import '../../../../features/books/presentation/providers/book_shelf_provider.dart';
import 'package:leafmark/features/books/presentation/screens/my_shelf_screen.dart';
import '../../../../core/app_theme.dart';
import 'edit_profile_screen.dart';
import '../../../ratings/domain/models/rating.dart';
import '../../../swaps/presentation/screens/exchange_history_screen.dart';
import '../../../wishlist/presentation/screens/wishlist_screen.dart';
import '../../../books/presentation/providers/follow_provider.dart';
import '../widgets/profile_badges.dart';
import '../../../notifications/presentation/providers/notification_provider.dart';
import '../../../notifications/presentation/screens/notifications_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    context.read<BookShelfProvider>().clearBooks();
    await context.read<AuthProvider>().logout();
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
    final user = context.watch<AuthProvider>().user;
    final shelf = context.watch<BookShelfProvider>();
    final textTheme = Theme.of(context).textTheme;
    final initial = user?.displayName.isNotEmpty == true
        ? user!.displayName[0].toUpperCase()
        : '?';

    return Scaffold(
      body: ListView(
        children: [
          Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.bottomCenter,
            children: [
              Container(
                height: 120,
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  image: user?.bannerPictureUrl != null &&
                      user!.bannerPictureUrl!.isNotEmpty
                      ? DecorationImage(
                    image: NetworkImage(user.bannerPictureUrl!),
                    fit: BoxFit.cover,
                  )
                      : null,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Profile',
                      style: textTheme.titleMedium?.copyWith(
                        color: AppTheme.primaryLight,
                      ),
                    ),
                    Row(
                      children: [
                        StreamBuilder<int>(
                          stream: context.read<NotificationProvider>().unreadCount(),
                          builder: (context, snapshot) {
                            final count = snapshot.data ?? 0;

                            return IconButton(
                              color: AppTheme.primaryLight,
                              tooltip: 'Notifications',
                              icon: Badge(
                                isLabelVisible: count > 0,
                                label: Text(count > 99 ? '99+' : '$count'),
                                child: const Icon(Icons.notifications_none_outlined, size: 20),
                              ),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const NotificationsScreen(),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 20),
                          color: AppTheme.primaryLight,
                          tooltip: 'Edit profile',
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const EditProfileScreen(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Positioned(
                bottom: -36,
                child: CircleAvatar(
                  radius: 36,
                  backgroundColor: AppTheme.primaryLight,
                  backgroundImage: user?.profilePictureUrl != null &&
                      user!.profilePictureUrl!.isNotEmpty
                      ? NetworkImage(user.profilePictureUrl!)
                      : null,
                  child: user?.profilePictureUrl == null ||
                      user!.profilePictureUrl!.isEmpty
                      ? Text(
                    initial,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.primary,
                    ),
                  )
                      : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 48),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                Text(
                  user?.displayName ?? '',
                  style: textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  user?.username.isNotEmpty == true
                      ? '@${user!.username}'
                      : '',
                  style: textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
                if (user?.bio != null && user!.bio!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    user.bio!,
                    style: textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ],

                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    StreamBuilder<int>(
                      stream: context.read<FollowProvider>().getFollowersCount(user?.uid ?? ''),
                      builder: (context, snapshot) {
                        return Text(
                          '${snapshot.hasData ? snapshot.data : '-'} Followers',
                          style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                        );
                      },
                    ),
                    const SizedBox(width: 16),
                    StreamBuilder<int>(
                      stream: context.read<FollowProvider>().getFollowingCount(user?.uid ?? ''),
                      builder: (context, snapshot) {
                        return Text(
                          '${snapshot.data ?? 0} Following',
                          style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                Row(
                  children: [
                    _StatCard(label: 'Books', value: '${shelf.books.length}'),
                    const SizedBox(width: 8),
                    StreamBuilder<int>(
                      stream: context.read<SwapProvider>().exchangeCount(user?.uid ?? ''),
                      builder: (context, snapshot) {
                        return _StatCard(
                          label: 'Swaps',
                          value: snapshot.hasData ? '${snapshot.data}' : '—',
                        );
                      },
                    ),
                    const SizedBox(width: 8),
                    StreamBuilder<List<Rating>>(
                      stream: context.read<RatingProvider>().getRatingsForUser(user?.uid ?? ''),
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
                ),
              ],
            ),
          ),
          ProfileBadges(
            userId: user?.uid ?? '',
            shelfCount: shelf.books.length,
          ),

          const SizedBox(height: 24),
          if (user?.favoriteAuthors != null &&
              user!.favoriteAuthors.isNotEmpty) ...[
            const Divider(),
            Padding(
              padding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Favorite Authors', style: textTheme.titleSmall),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: user.favoriteAuthors.map((author) {
                      return Chip(
                        label: Text(author),
                        backgroundColor:
                        AppTheme.primaryLight.withValues(alpha: 0.5),
                        side: BorderSide.none,
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ],

          if (user?.favoriteBookTitle != null &&
              user!.favoriteBookTitle!.isNotEmpty) ...[
            const Divider(),
            Padding(
              padding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
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
                        child: user.favoriteBookCoverUrl != null &&
                            user.favoriteBookCoverUrl!.isNotEmpty
                            ? Image.network(
                          user.favoriteBookCoverUrl!,
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
                            Text(
                              user.favoriteBookTitle!,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const SizedBox(height: 4),
                            if (user.favoriteBookAuthor != null)
                              Text(
                                user.favoriteBookAuthor!,
                                style: TextStyle(
                                    color: Colors.grey[700], fontSize: 14),
                              ),
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
          const Divider(),
          _MenuItem(
            iconData: Icons.history,
            iconBgColor: const Color(0xFFE8F0FA),
            iconColor: const Color(0xFF2A5BA8),
            title: 'Exchange History',
            subtitle: 'Your completed swaps',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ExchangeHistoryScreen()),
            ),
          ),
          const Divider(),
          _MenuItem(
            iconData: Icons.bookmark_outline,
            iconBgColor: const Color(0xFFF3EAF5),
            iconColor: const Color(0xFF7A3BA1),
            title: 'My Wishlist',
            subtitle: 'Books you\'re looking for',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => WishlistScreen(
                  uid: user?.uid ?? '',
                ),
              ),
            ),
          ),
          const Divider(),
          _MenuItem(
            iconData: Icons.logout,
            iconBgColor: const Color(0xFFFCEBEB),
            iconColor: const Color(0xFFA32D2D),
            title: 'Logout',
            titleColor: const Color(0xFFA32D2D),
            onTap: () => _logout(context),
          ),
          const SizedBox(height: 32),
        ],
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
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(10),
        ),
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
      contentPadding:
      const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: iconBgColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(iconData, size: 18, color: iconColor),
      ),
      title: Text(
        title,
        style: Theme.of(context)
            .textTheme
            .titleSmall
            ?.copyWith(color: titleColor),
      ),
      subtitle: subtitle != null
          ? Text(subtitle!,
          style: Theme.of(context).textTheme.bodySmall)
          : null,
      trailing: subtitle != null
          ? const Icon(Icons.chevron_right, size: 18)
          : null,
      onTap: onTap,
    );
  }
}