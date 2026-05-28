import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/notification_provider.dart';
import '../../domain/models/app_notification.dart';
import '../../../chat/presentation/screens/chat_screen.dart';
import '../../../swaps/presentation/screens/swap_requests_screen.dart';

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
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const SwapRequestsScreen(),
          ),
        );
        break;
    }
  }

  void _showUnavailableSnackBar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('This notification cannot be opened anymore.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotificationProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          StreamBuilder<int>(
            stream: provider.unreadCount(),
            builder: (context, snapshot) {
              final count = snapshot.data ?? 0;

              if (count <= 0) return const SizedBox.shrink();

              return TextButton(
                onPressed: provider.markAllAsRead,
                child: const Text('Mark all read'),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<List<AppNotification>>(
        stream: provider.notifications(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Failed to load notifications: ${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

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
                onTap: () => _handleNotificationTap(
                  context,
                  notification,
                  provider,
                ),
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
          backgroundImage: notification.senderPhotoUrl != null &&
              notification.senderPhotoUrl!.isNotEmpty
              ? NetworkImage(notification.senderPhotoUrl!)
              : null,
          child: notification.senderPhotoUrl == null ||
              notification.senderPhotoUrl!.isEmpty
              ? Text(
            _initialFor(notification.senderDisplayName),
            style: const TextStyle(fontWeight: FontWeight.bold),
          )
              : null,
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
            ? const Icon(Icons.chevron_right, size: 18)
            : Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: scheme.primary,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            const Icon(Icons.chevron_right, size: 18),
          ],
        ),
      ),
    );
  }

  String _initialFor(String? name) {
    if (name == null || name.trim().isEmpty) return '?';
    return name.trim()[0].toUpperCase();
  }
}