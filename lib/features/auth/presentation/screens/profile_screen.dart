import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../../../../features/books/presentation/providers/book_shelf_provider.dart';
import 'package:leafmark/features/books/presentation/screens/my_shelf_screen.dart';
import '../../../../core/app_theme.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    context.read<BookShelfProvider>().clearBooks();
    await context.read<AuthProvider>().logout();
  }

  @override
  Widget build(BuildContext context) {
    final user      = context.watch<AuthProvider>().user;
    final shelf     = context.watch<BookShelfProvider>();
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
                color: AppTheme.primary,
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
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
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 20),
                      color: AppTheme.primaryLight,
                      onPressed: () {},
                    ),
                  ],
                ),
              ),
              Positioned(
                bottom: -36,
                child: CircleAvatar(
                  radius: 36,
                  backgroundColor: AppTheme.primaryLight,
                  child: Text(
                    initial,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.primary,
                    ),
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
                const SizedBox(height: 20),
                Row(
                  children: [
                    _StatCard(label: 'Books',  value: '${shelf.books.length}'),
                    const SizedBox(width: 8),
                    _StatCard(label: 'Swaps',  value: '—'),
                    const SizedBox(width: 8),
                    _StatCard(label: 'Rating', value: '—'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Divider(),
          _MenuItem(
            iconData:    Icons.menu_book_outlined,
            iconBgColor: const Color(0xFFEAF3DE),
            iconColor:   const Color(0xFF3B6D11),
            title:       'My Shelf',
            subtitle:    '${shelf.books.length} books available',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MyShelfScreen()),
            ),
          ),
          const Divider(),
          _MenuItem(
            iconData:    Icons.logout,
            iconBgColor: const Color(0xFFFCEBEB),
            iconColor:   const Color(0xFFA32D2D),
            title:       'Logout',
            titleColor:  const Color(0xFFA32D2D),
            onTap:       () => _logout(context),
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
            Text(value, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 2),
            Text(label, style: Theme.of(context).textTheme.labelSmall),
          ],
        ),
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData  iconData;
  final Color     iconBgColor;
  final Color     iconColor;
  final String    title;
  final Color?    titleColor;
  final String?   subtitle;
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
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
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: titleColor,
        ),
      ),
      subtitle: subtitle != null
          ? Text(subtitle!, style: Theme.of(context).textTheme.bodySmall)
          : null,
      trailing: subtitle != null
          ? const Icon(Icons.chevron_right, size: 18)
          : null,
      onTap: onTap,
    );
  }
}