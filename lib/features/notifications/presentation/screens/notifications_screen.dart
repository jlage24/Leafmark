import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../auth/presentation/screens/public_profile_screen.dart';
import '../../../chat/presentation/screens/chat_screen.dart';
import '../../../swaps/presentation/screens/swap_requests_screen.dart';
import '../../domain/models/app_notification.dart';
import '../providers/notification_provider.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  Future<void> _handleNotificationTap(
      BuildContext context,
      AppNotification notification,
      NotificationProvider provider,
      ) async {
    await provider.markAsRead(notification.id);

    if (!context.mounted) return;

    switch (notification.type) {
      case AppNotificationType.chatMessage:
      case AppNotificationType.proposal:
      case AppNotificationType.counterOffer:
      case AppNotificationType.swapAccepted:
        final chatId = notification.chatId ?? notification.swapId;

        if (chatId == null || chatId.isEmpty) {
          _showUnavailableSnackBar(context);
          return;
        }

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatScreen(
              swapId: chatId,
              otherUserId: notification.senderId,
              otherUserName:
              notification.senderDisplayName ?? 'LeafMark user',
            ),
          ),
        );
        break;

      case AppNotificationType.swapRequest:
      case AppNotificationType.swapRejected:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SwapRequestsScreen()),
        );
        break;

      case AppNotificationType.newFollower:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PublicProfileScreen(
              userId: notification.senderId,
              displayName:
              notification.senderDisplayName ?? 'LeafMark user',
            ),
          ),
        );
        break;
    }
  }

  void _showUnavailableSnackBar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('This notification cannot be opened anymore.'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotificationProvider>();

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _NotificationsHeader(provider: provider),
            Expanded(
              child: StreamBuilder<List<AppNotification>>(
                stream: provider.notifications(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const _NotificationsMessageState(
                      icon: Icons.error_outline_rounded,
                      title: 'Could not load notifications',
                      message: 'Something went wrong. Please try again later.',
                    );
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const _NotificationsLoadingState();
                  }

                  final notifications = snapshot.data ?? [];

                  if (notifications.isEmpty) {
                    return const _NotificationsMessageState(
                      icon: Icons.notifications_none_rounded,
                      title: 'No notifications yet',
                      message:
                      'When someone messages you or interacts with your swaps, you will see it here.',
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.only(bottom: 16),
                    itemCount: notifications.length,
                    itemBuilder: (context, index) {
                      final notification = notifications[index];

                      return Dismissible(
                        key: ValueKey(notification.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 7,
                          ),
                          padding: const EdgeInsets.only(right: 22),
                          alignment: Alignment.centerRight,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.error,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(
                            Icons.delete_outline_rounded,
                            color: Colors.white,
                          ),
                        ),
                        onDismissed: (_) async {
                          await provider.deleteNotification(notification.id);
                        },
                        child: _NotificationCard(
                          notification: notification,
                          onTap: () => _handleNotificationTap(
                            context,
                            notification,
                            provider,
                          ),
                        ),
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

class _NotificationsHeader extends StatelessWidget {
  final NotificationProvider provider;

  const _NotificationsHeader({required this.provider});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 14),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(
              Icons.notifications_rounded,
              color: theme.colorScheme.primary,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Notifications',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Updates about chats, swaps and followers.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.62),
                  ),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'read') {
                await provider.markAllAsRead();
                return;
              }

              if (value == 'clear') {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (dialogContext) => AlertDialog(
                    title: const Text('Clear all notifications?'),
                    content: const Text(
                      'This will permanently remove all your notifications.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(dialogContext, false),
                        child: const Text('Cancel'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(dialogContext, true),
                        child: const Text('Clear all'),
                      ),
                    ],
                  ),
                );

                if (!context.mounted) return;

                if (confirmed == true) {
                  await provider.clearAll();
                }
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'read',
                child: Text('Mark all as read'),
              ),
              PopupMenuItem(
                value: 'clear',
                child: Text('Clear all'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback onTap;

  const _NotificationCard({
    required this.notification,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUnread = !notification.isRead;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
      decoration: BoxDecoration(
        color: isUnread
            ? theme.colorScheme.primary.withValues(alpha: 0.08)
            : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isUnread
              ? theme.colorScheme.primary.withValues(alpha: 0.22)
              : theme.colorScheme.outline.withValues(alpha: 0.12),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isUnread ? 0.055 : 0.035),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                _NotificationAvatar(notification: notification),
                const SizedBox(width: 14),
                Expanded(
                  child: _NotificationText(notification: notification),
                ),
                const SizedBox(width: 10),
                _NotificationTrailing(isUnread: isUnread),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NotificationAvatar extends StatelessWidget {
  final AppNotification notification;

  const _NotificationAvatar({required this.notification});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasPhoto = notification.senderPhotoUrl != null &&
        notification.senderPhotoUrl!.isNotEmpty;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        CircleAvatar(
          radius: 26,
          backgroundColor: theme.colorScheme.primaryContainer,
          foregroundColor: theme.colorScheme.onPrimaryContainer,
          backgroundImage:
          hasPhoto ? NetworkImage(notification.senderPhotoUrl!) : null,
          child: !hasPhoto
              ? Text(
            _initialFor(notification.senderDisplayName),
            style: const TextStyle(fontWeight: FontWeight.w900),
          )
              : null,
        ),
        Positioned(
          right: -2,
          bottom: -2,
          child: Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(
                _iconFor(notification.type),
                size: 14,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _initialFor(String? name) {
    if (name == null || name.trim().isEmpty) return '?';
    return name.trim()[0].toUpperCase();
  }

  IconData _iconFor(AppNotificationType type) {
    switch (type) {
      case AppNotificationType.chatMessage:
        return Icons.chat_bubble_outline_rounded;
      case AppNotificationType.proposal:
        return Icons.swap_horiz_rounded;
      case AppNotificationType.counterOffer:
        return Icons.compare_arrows_rounded;
      case AppNotificationType.swapAccepted:
        return Icons.check_circle_outline_rounded;
      case AppNotificationType.swapRequest:
        return Icons.mark_email_unread_outlined;
      case AppNotificationType.swapRejected:
        return Icons.cancel_outlined;
      case AppNotificationType.newFollower:
        return Icons.person_add_alt_rounded;
    }
  }
}

class _NotificationText extends StatelessWidget {
  final AppNotification notification;

  const _NotificationText({required this.notification});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUnread = !notification.isRead;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          notification.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: isUnread ? FontWeight.w900 : FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          notification.body,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.62),
          ),
        ),
      ],
    );
  }
}

class _NotificationTrailing extends StatelessWidget {
  final bool isUnread;

  const _NotificationTrailing({required this.isUnread});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isUnread)
          Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              shape: BoxShape.circle,
            ),
          ),
        const SizedBox(height: 8),
        Icon(
          Icons.chevron_right_rounded,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.35),
        ),
      ],
    );
  }
}

class _NotificationsLoadingState extends StatelessWidget {
  const _NotificationsLoadingState();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 16),
      itemCount: 5,
      itemBuilder: (context, index) {
        return const _LoadingNotificationCard();
      },
    );
  }
}

class _LoadingNotificationCard extends StatelessWidget {
  const _LoadingNotificationCard();

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
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: baseColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                _LoadingLine(widthFactor: 0.76),
                SizedBox(height: 10),
                _LoadingLine(widthFactor: 0.52),
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

class _NotificationsMessageState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _NotificationsMessageState({
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
              child: Icon(
                icon,
                size: 38,
                color: theme.colorScheme.primary,
              ),
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