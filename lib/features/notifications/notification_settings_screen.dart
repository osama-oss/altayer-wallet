import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:banksync_app/core/notifications/notification_model.dart';
import 'package:banksync_app/core/providers/app_providers.dart';
import 'package:banksync_app/core/theme/bank_sync_colors.dart';
import 'package:banksync_app/core/widgets/db_settings_widgets.dart';
import 'package:banksync_app/l10n/app_localizations.dart';
import '../../core/widgets/uff_loader.dart';

class NotificationSettingsScreen extends ConsumerStatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  ConsumerState<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends ConsumerState<NotificationSettingsScreen> {
  bool _loading = true;
  String? _error;
  NotificationPreferences _prefs = const NotificationPreferences();

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final repo = ref.read(notificationRepositoryProvider);
      final preferences = await repo.getPreferences();
      if (!mounted) return;
      setState(() {
        _prefs = preferences;
        _loading = false;
      });
    } catch (_) {
      // Backend may not be deployed yet — show UI with defaults so users
      // can still explore the settings screen.  Toggles will persist once
      // the API is available.
      if (!mounted) return;
      setState(() {
        _prefs = const NotificationPreferences();
        _loading = false;
      });
    }
  }

  Future<void> _updatePreference(NotificationPreferences newPrefs) async {
    // Keep local UI snappy, but roll back if API fails
    final oldPrefs = _prefs;
    setState(() {
      _prefs = newPrefs;
    });

    try {
      final repo = ref.read(notificationRepositoryProvider);
      await repo.updatePreferences(newPrefs);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _prefs = oldPrefs;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update preferences: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.notificationSettingsTitle),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    final colors = context.bankColors;
    final l10n = context.l10n;

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
                onPressed: _loadPreferences,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final pushEnabled = _prefs.pushEnabled;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        // Master Toggle
        DbSettingsGroup(
          children: [
            DbSettingsTile(
              icon: Icons.notifications_active_outlined,
              title: l10n.notificationsAllow,
              subtitle: 'Enable or disable all push notifications',
              trailing: Switch(
                value: pushEnabled,
                onChanged: (value) {
                  _updatePreference(_prefs.copyWith(pushEnabled: value));
                },
                activeTrackColor: colors.secondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Categories List (Only enabled if Push is allowed)
        IgnorePointer(
          ignoring: !pushEnabled,
          child: Opacity(
            opacity: pushEnabled ? 1.0 : 0.5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const DbSettingsSectionLabel(label: 'Categories'),
                DbSettingsGroup(
                  children: [
                    // Transfers
                    DbSettingsTile(
                      icon: Icons.swap_horiz,
                      title: l10n.notificationsTransfers,
                      subtitle: 'Alerts on money transfers',
                      trailing: Switch(
                        value: _prefs.transferEnabled,
                        onChanged: (value) {
                          _updatePreference(
                              _prefs.copyWith(transferEnabled: value));
                        },
                        activeTrackColor: colors.secondary,
                      ),
                    ),
                    // Bills (Coming soon)
                    DbSettingsTile(
                      icon: Icons.receipt_long,
                      title: 'Bills & Payments (${l10n.notificationsComingSoon})',
                      subtitle: 'Alerts on utility bills and standing orders',
                      trailing: const Switch(
                        value: false, // always false for Phase 1
                        onChanged: null, // disabled
                      ),
                    ),
                    // Offers (Coming soon)
                    DbSettingsTile(
                      icon: Icons.local_offer_outlined,
                      title: 'Offers & Promotions (${l10n.notificationsComingSoon})',
                      subtitle: 'Alerts on cashbacks, travel discounts, and campaigns',
                      trailing: const Switch(
                        value: false, // always false for Phase 1
                        onChanged: null, // disabled
                      ),
                    ),
                    // General
                    DbSettingsTile(
                      icon: Icons.notifications_none,
                      title: l10n.notificationsGeneral,
                      subtitle: 'Alerts on bank services updates',
                      trailing: Switch(
                        value: _prefs.generalEnabled,
                        onChanged: (value) {
                          _updatePreference(
                              _prefs.copyWith(generalEnabled: value));
                        },
                        activeTrackColor: colors.secondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Always-On Security alerts section
                DbSettingsSectionLabel(label: l10n.notificationsSecurityAlerts),
                DbSettingsGroup(
                  children: [
                    _buildLockedTile(
                      Icons.security,
                      'Account Security',
                      'Login alerts, failed attempts, and locks',
                    ),
                    _buildLockedTile(
                      Icons.key_outlined,
                      'Credentials Changed',
                      'Alerts on Password or PIN changes',
                    ),
                    _buildLockedTile(
                      Icons.fingerprint,
                      'Biometrics Enrollment',
                      'Alerts when biometric keys are registered or revoked',
                    ),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.fromLTRB(4, 8, 4, 0),
                  child: Text(
                    'Security alerts cannot be disabled for your protection.',
                    style: TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLockedTile(IconData icon, String title, String subtitle) {
    final colors = context.bankColors;

    return DbSettingsTile(
      icon: icon,
      iconColor: colors.outline,
      title: title,
      subtitle: subtitle,
      trailing: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.lock_outline, size: 18, color: Colors.grey),
          SizedBox(width: 8),
          Switch(
            value: true,
            onChanged: null, // read-only
          ),
        ],
      ),
    );
  }
}
