import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/notifications/notification_inbox.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/app_notification.dart';
import '../../../routing/app_router.dart';

/// In-app notification inbox: lists every analysis push / completion event.
class NotificationsView extends StatelessWidget {
  const NotificationsView({super.key});

  @override
  Widget build(BuildContext context) {
    final inbox = context.watch<NotificationInbox>();
    final palette = context.palette;
    final items = inbox.items;

    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (items.any((n) => !n.read))
            TextButton(
              onPressed: inbox.markAllRead,
              child: Text(
                'Mark all read',
                style: TextStyle(color: palette.teal, fontSize: 13),
              ),
            ),
          if (items.isNotEmpty)
            IconButton(
              tooltip: 'Clear all',
              onPressed: () => _confirmClear(context, inbox),
              icon: Icon(Icons.delete_outline, color: palette.textSecondary),
            ),
        ],
      ),
      body: !inbox.isLoaded
          ? const Center(child: CircularProgressIndicator())
          : items.isEmpty
              ? const _EmptyState()
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final notification = items[index];
                    return _NotificationCard(
                      notification: notification,
                      onTap: () => _open(context, inbox, notification),
                      onDismiss: () => inbox.remove(notification.id),
                    );
                  },
                ),
    );
  }

  Future<void> _confirmClear(
    BuildContext context,
    NotificationInbox inbox,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final palette = ctx.palette;
        return AlertDialog(
          backgroundColor: palette.surface,
          title: Text(
            'Clear notifications?',
            style: TextStyle(color: palette.textPrimary),
          ),
          content: Text(
            'This removes every item from your inbox.',
            style: TextStyle(color: palette.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('Cancel', style: TextStyle(color: palette.hint)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text('Clear', style: TextStyle(color: palette.error)),
            ),
          ],
        );
      },
    );
    if (confirmed == true) await inbox.clearAll();
  }

  Future<void> _open(
    BuildContext context,
    NotificationInbox inbox,
    AppNotification notification,
  ) async {
    await inbox.markRead(notification.id);
    final examId = notification.examId;
    if (examId != null && examId.isNotEmpty && context.mounted) {
      context.push(AppRoutes.examDetail(examId));
    }
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    palette.teal.withValues(alpha: 0.2),
                    palette.cyan.withValues(alpha: 0.12),
                  ],
                ),
              ),
              child: Icon(
                Icons.notifications_none_rounded,
                size: 40,
                color: palette.teal,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'You\'re all caught up',
              style: TextStyle(
                color: palette.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Analysis updates will appear here when an exam finishes.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: palette.textSecondary,
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({
    required this.notification,
    required this.onTap,
    required this.onDismiss,
  });

  final AppNotification notification;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final accent = notification.isFailure
        ? palette.error
        : notification.isSuccess
            ? palette.teal
            : palette.cyan;
    final icon = notification.isFailure
        ? Icons.error_outline_rounded
        : notification.isSuccess
            ? Icons.check_circle_outline_rounded
            : Icons.notifications_outlined;

    return Dismissible(
      key: ValueKey(notification.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDismiss(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: palette.error.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(Icons.delete_outline, color: palette.error),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Ink(
            decoration: BoxDecoration(
              color: palette.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: notification.read
                    ? palette.border
                    : accent.withValues(alpha: 0.45),
              ),
            ),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: 4,
                    decoration: BoxDecoration(
                      color: notification.read
                          ? Colors.transparent
                          : accent,
                      borderRadius: const BorderRadius.horizontal(
                        left: Radius.circular(16),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: accent.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(icon, color: accent, size: 22),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        notification.title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: palette.textPrimary,
                                          fontSize: 15,
                                          fontWeight: notification.read
                                              ? FontWeight.w600
                                              : FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _relativeTime(notification.createdAt),
                                      style: TextStyle(
                                        color: palette.hint,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  notification.body,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: palette.textSecondary,
                                    fontSize: 13,
                                    height: 1.35,
                                  ),
                                ),
                                if (notification.examId != null) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    'Tap to open exam',
                                    style: TextStyle(
                                      color: accent,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          if (!notification.read) ...[
                            const SizedBox(width: 6),
                            Container(
                              width: 8,
                              height: 8,
                              margin: const EdgeInsets.only(top: 6),
                              decoration: BoxDecoration(
                                color: accent,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static String _relativeTime(DateTime date) {
    final local = date.toLocal();
    final diff = DateTime.now().difference(local);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(local.day)}/${two(local.month)}';
  }
}
