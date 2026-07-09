import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:banksync_app/core/notifications/notification_model.dart';
import 'package:banksync_app/core/theme/bank_sync_colors.dart';

class NotificationTile extends StatelessWidget {
  const NotificationTile({
    required this.item,
    required this.onTap,
    super.key,
  });

  final NotificationItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.bankColors;
    final isUnread = !item.isRead;

    return InkWell(
      onTap: onTap,
      child: Container(
        color: isUnread
            ? colors.primaryContainer.withValues(alpha: 0.08)
            : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status dot + Category Icon
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _iconBgColor(context, item.type, item.severity),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _iconData(item.type, item.severity),
                    color: _iconColor(context, item.type, item.severity),
                    size: 20,
                  ),
                ),
                if (isUnread)
                  Positioned(
                    top: -2,
                    right: -2,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: colors.secondary,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: colors.background,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 16),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight:
                                    isUnread ? FontWeight.bold : FontWeight.w500,
                                color: colors.onSurface,
                              ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatTime(item.createdAt),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.body,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconData(String type, String severity) {
    if (severity == 'CRITICAL') return Icons.gpp_maybe;
    switch (type) {
      case 'TRANSFER':
        return Icons.swap_horiz;
      case 'SECURITY':
        return Icons.security;
      case 'BILL':
        return Icons.receipt_long;
      case 'OFFER':
        return Icons.local_offer;
      default:
        return Icons.notifications;
    }
  }

  Color _iconColor(BuildContext context, String type, String severity) {
    final colors = context.bankColors;
    if (severity == 'CRITICAL') return colors.error;
    switch (type) {
      case 'TRANSFER':
        return colors.accentGreen;
      case 'SECURITY':
        return colors.error;
      case 'BILL':
        return colors.secondary;
      case 'OFFER':
        return colors.onTertiaryContainer;
      default:
        return colors.onSurface;
    }
  }

  Color _iconBgColor(BuildContext context, String type, String severity) {
    final color = _iconColor(context, type, severity);
    return color.withValues(alpha: 0.12);
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM d').format(time);
    }
  }
}
