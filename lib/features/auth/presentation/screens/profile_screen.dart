import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:rxdart/rxdart.dart';

import '../../../../core/app_theme.dart';
import '../../../../core/theme_provider.dart';
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
import '../../../books/presentation/screens/follow_list_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final Stream<int> _exchangeCountStream;
  late final Stream<List<Rating>> _ratingsStream;

  @override
  void initState() {
    super.initState();
    final uid = context.read<AuthProvider>().user?.uid ?? '';
    _exchangeCountStream = context
        .read<SwapProvider>()
        .exchangeCount(uid)
        .shareValue();
    _ratingsStream = context
        .read<RatingProvider>()
        .getRatingsForUser(uid)
        .shareValue();
  }

  Future<void> _logout(BuildContext context) async {
    context.read<BookShelfProvider>().clearBooks();
    await context.read<AuthProvider>().logout();
  }

  void _showChangePasswordDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const ChangePasswordDialog(),
    );
  }

  void _shareProfile(
    BuildContext context,
    String displayName,
    String username,
  ) {
    final text = 'Check out $displayName (@$username) on LeafMark! 📚✨';
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Profile details copied for @$username!'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const DeleteAccountDialog(),
    );
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
            onShare: () {
              if (user != null) {
                _shareProfile(context, user.displayName, user.username);
              }
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
                      color: theme.colorScheme.onSurface.withValues(
                        alpha: 0.58,
                      ),
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
                            (sum, item) => sum + item.rating,
                          );
                          ratingValue = (total / ratings.length)
                              .toStringAsFixed(1);
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
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.15),
                    side: BorderSide.none,
                  );
                }).toList(),
              ),
            ),
          if (user?.favoriteBookTitle != null &&
              user!.favoriteBookTitle!.isNotEmpty)
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
                iconBgColor: theme.colorScheme.primary.withValues(alpha: 0.12),
                iconColor: theme.colorScheme.primary,
                title: 'My Shelf',
                subtitle: '${shelf.books.length} books available',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MyShelfScreen()),
                ),
              ),
              _MenuItem(
                iconData: Icons.history_rounded,
                iconBgColor: theme.colorScheme.secondary.withValues(
                  alpha: 0.12,
                ),
                iconColor: theme.colorScheme.secondary,
                title: 'Exchange History',
                subtitle: 'Your completed swaps',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ExchangeHistoryScreen(),
                  ),
                ),
              ),
              _MenuItem(
                iconData: Icons.bookmark_outline_rounded,
                iconBgColor: theme.colorScheme.tertiary.withValues(alpha: 0.12),
                iconColor: theme.colorScheme.tertiary,
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
              Consumer<ThemeProvider>(
                builder: (context, themeProvider, _) {
                  return SwitchListTile(
                    secondary: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        themeProvider.isDarkMode
                            ? Icons.dark_mode_rounded
                            : Icons.light_mode_rounded,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    title: Text(
                      'Dark mode',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    value: themeProvider.isDarkMode,
                    onChanged: themeProvider.toggleTheme,
                  );
                },
              ),

              _MenuItem(
                iconData: Icons.lock_outline_rounded,
                iconBgColor: theme.colorScheme.primary.withValues(alpha: 0.12),
                iconColor: theme.colorScheme.primary,
                title: 'Change Password',
                subtitle: 'Update your account password',
                onTap: () => _showChangePasswordDialog(context),
              ),

              _MenuItem(
                iconData: Icons.delete_forever_rounded,
                iconBgColor: theme.colorScheme.error.withValues(alpha: 0.12),
                iconColor: theme.colorScheme.error,
                title: 'Delete Account',
                titleColor: theme.colorScheme.error,
                subtitle: 'Permanently delete your data',
                onTap: () => _showDeleteAccountDialog(context),
              ),

              _MenuItem(
                iconData: Icons.logout_rounded,
                iconBgColor: theme.colorScheme.error.withValues(alpha: 0.12),
                iconColor: theme.colorScheme.error,
                title: 'Logout',
                titleColor: theme.colorScheme.error,
                onTap: () => _logout(context),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProfileHero extends StatefulWidget {
  final String title;
  final String displayName;
  final String initial;
  final String? profilePictureUrl;
  final String? bannerPictureUrl;
  final VoidCallback onEdit;
  final VoidCallback onShare;

  const _ProfileHero({
    required this.title,
    required this.displayName,
    required this.initial,
    required this.profilePictureUrl,
    required this.bannerPictureUrl,
    required this.onEdit,
    required this.onShare,
  });

  @override
  State<_ProfileHero> createState() => _ProfileHeroState();
}

class _ProfileHeroState extends State<_ProfileHero> {
  late final Stream<int> _unreadCountStream;

  @override
  void initState() {
    super.initState();
    _unreadCountStream = context
        .read<NotificationProvider>()
        .unreadCount()
        .shareValue();
  }

  @override
  Widget build(BuildContext context) {
    final hasBanner =
        widget.bannerPictureUrl != null && widget.bannerPictureUrl!.isNotEmpty;
    final hasAvatar =
        widget.profilePictureUrl != null &&
        widget.profilePictureUrl!.isNotEmpty;

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.bottomCenter,
      children: [
        Container(
          height: 150,
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            image: hasBanner
                ? DecorationImage(
                    image: NetworkImage(widget.bannerPictureUrl!),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              StreamBuilder<int>(
                stream: _unreadCountStream,
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
                tooltip: 'Share profile',
                onPressed: widget.onShare,
                child: const Icon(Icons.share_outlined, size: 20),
              ),
              const SizedBox(width: 8),
              _HeroIconButton(
                tooltip: 'Edit profile',
                onPressed: widget.onEdit,
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
              backgroundColor: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.16),
              backgroundImage: hasAvatar
                  ? NetworkImage(widget.profilePictureUrl!)
                  : null,
              child: !hasAvatar
                  ? Text(
                      widget.initial,
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
                    errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.book, color: Colors.grey),
                  )
                : const Icon(Icons.book, color: Colors.grey),
          ),
        ),
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
      trailing: subtitle != null
          ? const Icon(Icons.chevron_right_rounded)
          : null,
      onTap: onTap,
    );
  }
}

class ChangePasswordDialog extends StatefulWidget {
  const ChangePasswordDialog({super.key});

  @override
  State<ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<ChangePasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.changePassword(
      currentPassword: _currentPasswordController.text,
      newPassword: _newPasswordController.text,
    );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (success) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Password changed successfully!'),
          backgroundColor: Theme.of(context).colorScheme.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } else {
      setState(() {
        _errorMessage = authProvider.errorMessage;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      backgroundColor: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Change Password',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        fontSize: 20,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: _isLoading
                          ? null
                          : () => Navigator.of(context).pop(),
                      style: IconButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(36, 36),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: theme.colorScheme.error.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.error_outline_rounded,
                          color: theme.colorScheme.error,
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(
                              color: theme.colorScheme.error,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                TextFormField(
                  controller: _currentPasswordController,
                  obscureText: _obscureCurrent,
                  decoration: InputDecoration(
                    labelText: 'Current Password',
                    hintText: '••••••••',
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureCurrent
                            ? Icons.visibility_off_rounded
                            : Icons.visibility_rounded,
                      ),
                      onPressed: () =>
                          setState(() => _obscureCurrent = !_obscureCurrent),
                    ),
                  ),
                  validator: (val) => val == null || val.isEmpty
                      ? 'Please enter your current password'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _newPasswordController,
                  obscureText: _obscureNew,
                  decoration: InputDecoration(
                    labelText: 'New Password',
                    hintText: 'At least 6 characters',
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureNew
                            ? Icons.visibility_off_rounded
                            : Icons.visibility_rounded,
                      ),
                      onPressed: () =>
                          setState(() => _obscureNew = !_obscureNew),
                    ),
                  ),
                  validator: (val) {
                    if (val == null || val.isEmpty) {
                      return 'Please enter a new password';
                    }
                    if (val.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirm,
                  decoration: InputDecoration(
                    labelText: 'Confirm New Password',
                    hintText: '••••••••',
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirm
                            ? Icons.visibility_off_rounded
                            : Icons.visibility_rounded,
                      ),
                      onPressed: () =>
                          setState(() => _obscureConfirm = !_obscureConfirm),
                    ),
                  ),
                  validator: (val) {
                    if (val != _newPasswordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _isLoading
                          ? null
                          : () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 22,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                color: theme.colorScheme.onPrimary,
                              ),
                            )
                          : const Text(
                              'Change',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class DeleteAccountDialog extends StatefulWidget {
  const DeleteAccountDialog({super.key});

  @override
  State<DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<DeleteAccountDialog> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final authProvider = context.read<AuthProvider>();
    context.read<BookShelfProvider>().clearBooks();

    final success = await authProvider.deleteAccount(
      password: _passwordController.text,
    );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (success) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Your account has been deleted.'),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } else {
      setState(() {
        _errorMessage = authProvider.errorMessage;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      backgroundColor: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Delete Account',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        fontSize: 20,
                        color: theme.colorScheme.error,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: _isLoading
                          ? null
                          : () => Navigator.of(context).pop(),
                      style: IconButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(36, 36),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: theme.colorScheme.error.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: theme.colorScheme.error,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Warning: This action is permanent and cannot be undone. All your books, swaps, and profile data will be deleted.',
                          style: TextStyle(
                            color: theme.colorScheme.error,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: theme.colorScheme.error.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.error_outline_rounded,
                          color: theme.colorScheme.error,
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(
                              color: theme.colorScheme.error,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Confirm Password',
                    hintText: 'Enter your password to confirm deletion',
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_rounded
                            : Icons.visibility_rounded,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (val) => val == null || val.isEmpty
                      ? 'Please enter your password to confirm deletion'
                      : null,
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _isLoading
                          ? null
                          : () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.error,
                        foregroundColor: theme.colorScheme.onError,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 22,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                color: theme.colorScheme.onError,
                              ),
                            )
                          : const Text(
                              'Delete',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
