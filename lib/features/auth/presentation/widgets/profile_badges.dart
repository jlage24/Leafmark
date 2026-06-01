import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/app_theme.dart';
import '../../../ratings/domain/models/rating.dart';
import '../../../ratings/presentation/providers/rating_provider.dart';
import '../../../swaps/presentation/providers/swap_provider.dart';
import '../../../books/presentation/providers/follow_provider.dart';

class ProfileBadges extends StatelessWidget {
  final String userId;
  final int shelfCount;

  const ProfileBadges({
    super.key,
    required this.userId,
    required this.shelfCount,
  });

  @override
  Widget build(BuildContext context) {
    if (userId.isEmpty) return const SizedBox.shrink();

    return StreamBuilder<int>(
      stream: context.read<SwapProvider>().exchangeCount(userId),
      builder: (context, swapSnapshot) {
        final swapsCount = swapSnapshot.data ?? 0;

        return StreamBuilder<List<Rating>>(
          stream: context.read<RatingProvider>().getRatingsForUser(userId),
          builder: (context, ratingSnapshot) {
            final ratings = ratingSnapshot.data ?? [];
            double averageRating = 0.0;
            if (ratings.isNotEmpty) {
              final totalStars = ratings.fold<int>(0, (total, item) => total + item.rating);
              averageRating = totalStars / ratings.length;
            }

            return StreamBuilder<int>(
              stream: context.read<FollowProvider>().getFollowersCount(userId),
              builder: (context, followersSnapshot) {
                final followersCount = followersSnapshot.data ?? 0;

                final badges = _calculateBadges(
                  context,
                  swapsCount: swapsCount,
                  averageRating: averageRating,
                  ratingsCount: ratings.length,
                  shelfCount: shelfCount,
                  followersCount: followersCount,
                );

                if (badges.isEmpty) return const SizedBox.shrink();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        'Achievements',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: badges.map((badge) => _BadgeChip(badge: badge)).toList(),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  // Deterministic badge logic mapping
  List<Map<String, dynamic>> _calculateBadges(
    BuildContext context, {
    required int swapsCount,
    required double averageRating,
    required int ratingsCount,
    required int shelfCount,
    required int followersCount,
  }) {
    final badges = <Map<String, dynamic>>[];
    final scheme = Theme.of(context).colorScheme;

    if (swapsCount >= 1) {
      badges.add({
        'label': 'First Swap',
        'icon': Icons.swap_horiz_rounded,
        'color': scheme.secondary,
      });
    }

    if (swapsCount >= 3) {
      badges.add({
        'label': 'Trusted Swapper',
        'icon': Icons.handshake_rounded,
        'color': scheme.primary,
      });
    }

    if (ratingsCount >= 1 && averageRating >= 4.5) {
      badges.add({
        'label': 'Well Rated',
        'icon': Icons.star_rounded,
        'color': scheme.tertiary,
      });
    }

    if (shelfCount >= 5) {
      badges.add({
        'label': 'Librarian',
        'icon': Icons.local_library_rounded,
        'color': const Color(0xFF455A64), // BlueGrey
      });
    }

    if (followersCount >= 5) {
      badges.add({
        'label': 'Community Pillar',
        'icon': Icons.groups_rounded,
        'color': const Color(0xFF6A1B9A), // Purple
      });
    }

    return badges;
  }
}


class _BadgeChip extends StatelessWidget {
  final Map<String, dynamic> badge;

  const _BadgeChip({required this.badge});

  @override
  Widget build(BuildContext context) {
    final baseColor = badge['color'] as Color;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: baseColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: baseColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(badge['icon'] as IconData, size: 16, color: baseColor),
          const SizedBox(width: 6),
          Text(
            badge['label'] as String,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: baseColor,
            ),
          ),
        ],
      ),
    );
  }
}