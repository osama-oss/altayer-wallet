import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:banksync_app/core/network/api_exception.dart';
import 'package:banksync_app/core/notifications/notification_model.dart';
import 'package:banksync_app/core/providers/app_providers.dart';
import 'package:banksync_app/core/theme/bank_sync_colors.dart';
import 'package:banksync_app/features/notifications/widgets/notification_filter_bar.dart';
import 'package:banksync_app/features/notifications/widgets/notification_tile.dart';
import 'package:banksync_app/l10n/app_localizations.dart';
import '../../core/widgets/uff_loader.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  final ScrollController _scrollController = ScrollController();
  
  bool _loading = false;
  bool _loadingMore = false;
  String? _error;
  
  List<NotificationItem> _notifications = [];
  int _currentPage = 0;
  bool _hasMore = false;
  String? _selectedType;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadFirstPage();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadFirstPage() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
      _notifications = [];
      _currentPage = 0;
    });

    try {
      final repo = ref.read(notificationRepositoryProvider);
      final page = await repo.getNotifications(
        page: 0,
        size: 20,
        type: _selectedType,
      );

      if (!mounted) return;
      setState(() {
        _notifications = page.content;
        _hasMore = page.hasMore;
        _loading = false;
      });

      // Also trigger a refresh of the unread badge count
      _refreshUnreadCount();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load notifications. Please try again.';
        _loading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore) return;

    setState(() {
      _loadingMore = true;
    });

    try {
      final repo = ref.read(notificationRepositoryProvider);
      final nextPage = _currentPage + 1;
      final page = await repo.getNotifications(
        page: nextPage,
        size: 20,
        type: _selectedType,
      );

      if (!mounted) return;
      setState(() {
        _notifications.addAll(page.content);
        _currentPage = nextPage;
        _hasMore = page.hasMore;
        _loadingMore = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingMore = false;
      });
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  Future<void> _refreshUnreadCount() async {
    try {
      final count = await ref.read(notificationRepositoryProvider).getUnreadCount();
      ref.read(unreadNotificationCountProvider.notifier).state = count;
    } catch (_) {}
  }

  Future<void> _markAllAsRead() async {
    try {
      await ref.read(notificationRepositoryProvider).markAllRead(type: _selectedType);
      if (!mounted) return;
      
      // Update local state to show all as read
      setState(() {
        _notifications = _notifications
            .map((item) => item.copyWith(isRead: true))
            .toList();
      });

      _refreshUnreadCount();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All notifications marked as read')),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to mark all as read: $e')),
        );
      }
    }
  }

  Future<void> _onNotificationTap(NotificationItem item) async {
    // If not read yet, call read API
    if (!item.isRead) {
      try {
        await ref.read(notificationRepositoryProvider).markRead(item.id);
        setState(() {
          _notifications = _notifications.map((n) {
            if (n.id == item.id) {
              return n.copyWith(isRead: true);
            }
            return n;
          }).toList();
        });
        _refreshUnreadCount();
      } catch (_) {}
    }

    // Dynamic routing from notifications (we fallback to /home or similar for Phase 1)
    if (mounted) {
      // Direct navigation placeholder or GoRouter back/home
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Tapped: ${item.title}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.notificationsTitle),
        actions: [
          if (_notifications.any((n) => !n.isRead))
            TextButton(
              onPressed: _markAllAsRead,
              child: const Text('Mark all read'),
            ),
        ],
      ),
      body: Column(
        children: [
          // Filter Chips
          NotificationFilterBar(
            selectedType: _selectedType,
            onSelected: (type) {
              setState(() {
                _selectedType = type;
              });
              _loadFirstPage();
            },
          ),

          // Main Feed
          Expanded(
            child: _buildMainContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    final colors = context.bankColors;

    if (_loading) {
      return const Center(child: UffLoader());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: colors.error),
              const SizedBox(height: 16),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: colors.onSurfaceVariant),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _loadFirstPage,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_off_outlined,
                size: 64, color: colors.onSurfaceVariant.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            Text(
              'No notifications found',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadFirstPage,
      child: ListView.separated(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: _notifications.length + (_hasMore ? 1 : 0),
        separatorBuilder: (context, index) => Divider(
          height: 1,
          color: colors.outlineVariant.withValues(alpha: 0.4),
        ),
        itemBuilder: (context, index) {
          if (index == _notifications.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: UffLoader()),
            );
          }
          final item = _notifications[index];
          return NotificationTile(
            item: item,
            onTap: () => _onNotificationTap(item),
          );
        },
      ),
    );
  }
}
