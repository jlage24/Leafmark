import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rxdart/rxdart.dart';

import '../../../auth/presentation/screens/public_profile_screen.dart';
import '../providers/follow_provider.dart';

enum FollowListType { followers, following }

class FollowListScreen extends StatefulWidget {
  final String userId;
  final FollowListType type;

  const FollowListScreen({super.key, required this.userId, required this.type});

  @override
  State<FollowListScreen> createState() => _FollowListScreenState();
}

class _FollowListScreenState extends State<FollowListScreen> {
  late final Stream<List<String>> _usersStream;

  @override
  void initState() {
    super.initState();
    final provider = context.read<FollowProvider>();
    final isFollowers = widget.type == FollowListType.followers;
    _usersStream =
        (isFollowers
                ? provider.getFollowers(widget.userId)
                : provider.getFollowing(widget.userId))
            .shareValue();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.read<FollowProvider>();
    final isFollowers = widget.type == FollowListType.followers;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _FollowListHeader(
              title: isFollowers ? 'Followers' : 'Following',
              subtitle: isFollowers
                  ? 'People following this reader.'
                  : 'Readers this user follows.',
            ),
            Expanded(
              child: StreamBuilder<List<String>>(
                stream: _usersStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const _FollowListLoadingState();
                  }

                  if (snapshot.hasError) {
                    return const _FollowListMessageState(
                      icon: Icons.error_outline_rounded,
                      title: 'Could not load users',
                      message: 'Something went wrong. Please try again later.',
                    );
                  }

                  final userIds = snapshot.data ?? [];

                  if (userIds.isEmpty) {
                    return _FollowListMessageState(
                      icon: Icons.people_outline_rounded,
                      title: isFollowers
                          ? 'No followers yet'
                          : 'Not following anyone yet',
                      message: isFollowers
                          ? 'Followers will appear here.'
                          : 'Followed readers will appear here.',
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.only(bottom: 16),
                    itemCount: userIds.length,
                    itemBuilder: (context, index) {
                      final uid = userIds[index];

                      return FutureBuilder<Map<String, String?>>(
                        future: provider.fetchUserInfo(uid),
                        builder: (context, userSnap) {
                          final info = userSnap.data;
                          final displayName =
                              info?['displayName'] ?? 'LeafMark user';
                          final photoUrl = info?['photoUrl'];

                          return _FollowUserCard(
                            userId: uid,
                            displayName: displayName,
                            photoUrl: photoUrl,
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FollowListHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const _FollowListHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 12, 20, 14),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(17),
            ),
            child: Icon(
              Icons.people_alt_rounded,
              color: theme.colorScheme.primary,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.62),
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

class _FollowUserCard extends StatelessWidget {
  final String userId;
  final String displayName;
  final String? photoUrl;

  const _FollowUserCard({
    required this.userId,
    required this.displayName,
    required this.photoUrl,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasPhoto = photoUrl != null && photoUrl!.isNotEmpty;
    final initial = displayName.trim().isNotEmpty
        ? displayName.trim()[0].toUpperCase()
        : '?';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.045),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        leading: CircleAvatar(
          radius: 25,
          backgroundColor: theme.colorScheme.primaryContainer,
          backgroundImage: hasPhoto ? NetworkImage(photoUrl!) : null,
          child: !hasPhoto
              ? Text(
                  initial,
                  style: TextStyle(
                    color: theme.colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w900,
                  ),
                )
              : null,
        ),
        title: Text(
          displayName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w900,
          ),
        ),
        subtitle: Text(
          'View profile',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.58),
          ),
        ),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  PublicProfileScreen(userId: userId, displayName: displayName),
            ),
          );
        },
      ),
    );
  }
}

class _FollowListLoadingState extends StatelessWidget {
  const _FollowListLoadingState();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: 6,
      itemBuilder: (context, index) => const _LoadingUserCard(),
    );
  }
}

class _LoadingUserCard extends StatelessWidget {
  const _LoadingUserCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final baseColor = theme.colorScheme.onSurface.withValues(alpha: 0.08);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(color: baseColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                _LoadingLine(widthFactor: 0.48),
                SizedBox(height: 10),
                _LoadingLine(widthFactor: 0.32),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingLine extends StatelessWidget {
  final double widthFactor;

  const _LoadingLine({required this.widthFactor});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FractionallySizedBox(
      widthFactor: widthFactor,
      alignment: Alignment.centerLeft,
      child: Container(
        height: 12,
        decoration: BoxDecoration(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(99),
        ),
      ),
    );
  }
}

class _FollowListMessageState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _FollowListMessageState({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 38, color: theme.colorScheme.primary),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.62),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
