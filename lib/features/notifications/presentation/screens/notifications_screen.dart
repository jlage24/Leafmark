import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/notification_provider.dart';
import '../../domain/models/app_notification.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotificationProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: provider.markAllAsRead,
            child: const Text('Mark all read'),
          ),
        ],
      ),
      body: StreamBuilder<List<AppNotification>>(
        stream: provider.notifications(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final notifications = snapshot.data ?? [];

          if (notifications.isEmpty) {
            return const _EmptyNotifications();
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: notifications.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final notification = notifications[index];

              return _NotificationCard(
                notification: notification,
                onTap: () => provider.markAsRead(notification.id),
              );
            },
          );
        },
      ),
    );
  }
}

class _EmptyNotifications extends StatelessWidget {
  const _EmptyNotifications();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.notifications_none,
              size: 64,
              color: scheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'No notifications yet',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'When someone messages you or interacts with your swaps, you will see it here.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: scheme.outline,
              ),
            ),
          ],
        ),
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
    final scheme = Theme.of(context).colorScheme;

    return Card(
      elevation: notification.isRead ? 0 : 2,
      color: notification.isRead
          ? scheme.surface
          : scheme.primaryContainer.withValues(alpha: 0.35),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: notification.isRead
              ? scheme.outlineVariant
              : scheme.primary.withValues(alpha: 0.35),
        ),
      ),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: scheme.primaryContainer,
          foregroundColor: scheme.onPrimaryContainer,
          child: Icon(_iconForType(notification.type)),
        ),
        title: Text(
          notification.title,
          style: TextStyle(
            fontWeight:
            notification.isRead ? FontWeight.w500 : FontWeight.w700,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(notification.body),
        ),
        trailing: notification.isRead
            ? null
            : Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: scheme.primary,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }

  IconData _iconForType(AppNotificationType type) {
    switch (type) {
      case AppNotificationType.swapRequest:
        return Icons.swap_horiz;
      case AppNotificationType.chatMessage:
        return Icons.chat_bubble_outline;
      case AppNotificationType.proposal:
        return Icons.local_offer_outlined;
      case AppNotificationType.counterOffer:
        return Icons.compare_arrows;
      case AppNotificationType.swapAccepted:
        return Icons.check_circle_outline;
    }
  }
}