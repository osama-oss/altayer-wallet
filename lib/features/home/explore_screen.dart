import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/api_exception.dart';
import '../../core/network/banking_auth_exceptions.dart';
import '../../core/providers/app_providers.dart';
import '../../core/providers/locale_provider.dart';
import '../../core/providers/theme_mode_provider.dart';
import '../../core/theme/bank_sync_colors.dart';
import '../../core/widgets/pin_entry_sheet.dart';
import '../../l10n/app_localizations.dart';
import '../../router/app_router.dart';
import '../profile/profile_screen.dart';
import '../settings/default_accounts_screen.dart';
import '../../core/widgets/uff_loader.dart';

class ExploreScreen extends ConsumerStatefulWidget {
  const ExploreScreen({super.key});

  @override
  ConsumerState<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends ConsumerState<ExploreScreen> {
  bool _loadingBiometric = true;
  bool _biometricOn = false;
  bool _hardwareOk = false;
  bool _togglingBiometric = false;

  @override
  void initState() {
    super.initState();
    _loadBiometricState();
  }

  Future<void> _loadBiometricState() async {
    final auth = ref.read(authServiceProvider);
    final on = await auth.isBiometricEnabled();
    final hw = await auth.isBiometricHardwareAvailable();
    if (mounted) {
      setState(() {
        _biometricOn = on;
        _hardwareOk = hw;
        _loadingBiometric = false;
      });
    }
  }


  Future<void> _onBiometricToggle(bool enable) async {
    final l10n = context.l10n;
    final pin = await showPinEntrySheet(
      context,
      title: l10n.enterTransactionPin,
      subtitle: enable ? l10n.pinRequiredEnableBiometric : l10n.pinRequiredDisableBiometric,
    );
    if (pin == null || !mounted) return;

    setState(() => _togglingBiometric = true);
    try {
      if (enable) {
        final ok = await ref.read(authServiceProvider).enableBiometricLogin(pin);
        if (!mounted) return;
        if (ok) {
          setState(() => _biometricOn = true);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.biometricEnabled)),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.biometricSetupCancelled)),
          );
        }
      } else {
        await ref.read(authServiceProvider).disableBiometricLogin(pin);
        if (!mounted) return;
        setState(() => _biometricOn = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.biometricDisabled)),
        );
      }
    } on PinInvalidException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) {
        setState(() => _togglingBiometric = false);
        await _loadBiometricState();
      }
    }
  }

  Future<void> _openResetPassword() async {
    final profile = await ref.read(authServiceProvider).readProfile();
    final mobile = profile?['mobile']?.toString();
    if (!mounted) return;
    if (mobile != null && mobile.isNotEmpty) {
      context.push('/reset-password?mobile=${Uri.encodeComponent(mobile)}');
    } else {
      context.push('/reset-password');
    }
  }

  Future<void> _signOut() async {
    await ref.read(authServiceProvider).signOut();
    if (!mounted) return;
    invalidateUserSessionCache(ref);
    notifyRouterAuthChanged(ref);
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);
    final colors = context.bankColors;
    final isDarkTheme = Theme.of(context).brightness == Brightness.dark;
    final languageCode = locale.languageCode;
    final isAr = languageCode == 'ar';

    return Scaffold(
      backgroundColor: isDarkTheme ? const Color(0xFF0F1115) : const Color(0xFFF1F5F9), // Slate light/dark background
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          physics: const BouncingScrollPhysics(),
          children: [
            // Appearance Header
            _buildSectionLabel(l10n.appearance),
            const SizedBox(height: 8),

            // Appearance Custom Card Segmented Selector
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDarkTheme ? const Color(0xFF161921) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  _buildSegmentItem(
                    label: l10n.themeLight,
                    icon: Icons.light_mode_outlined,
                    isActive: themeMode == ThemeMode.light,
                    onTap: () => ref.read(themeModeProvider.notifier).setThemeMode(ThemeMode.light),
                  ),
                  _buildSegmentItem(
                    label: l10n.themeDark,
                    icon: Icons.dark_mode_outlined,
                    isActive: themeMode == ThemeMode.dark,
                    onTap: () => ref.read(themeModeProvider.notifier).setThemeMode(ThemeMode.dark),
                  ),
                  _buildSegmentItem(
                    label: l10n.themeSystem,
                    icon: Icons.settings_brightness_outlined,
                    isActive: themeMode == ThemeMode.system,
                    onTap: () => ref.read(themeModeProvider.notifier).setThemeMode(ThemeMode.system),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Language Header
            _buildSectionLabel(l10n.language),
            const SizedBox(height: 8),

            // Language Custom Card Segmented Selector
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDarkTheme ? const Color(0xFF161921) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  _buildSegmentItem(
                    label: 'English',
                    icon: Icons.language_rounded,
                    isActive: locale.languageCode == 'en',
                    onTap: () => ref.read(localeProvider.notifier).setLocale(const Locale('en')),
                  ),
                  _buildSegmentItem(
                    label: 'العربية',
                    icon: Icons.language_rounded,
                    isActive: locale.languageCode == 'ar',
                    onTap: () => ref.read(localeProvider.notifier).setLocale(const Locale('ar')),
                  ),
                  _buildSegmentItem(
                    label: '中文',
                    icon: Icons.language_rounded,
                    isActive: locale.languageCode == 'zh',
                    onTap: () => ref.read(localeProvider.notifier).setLocale(const Locale('zh')),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Security Header
            _buildSectionLabel(l10n.security),
            const SizedBox(height: 8),

            // Security card list group
            Container(
              decoration: BoxDecoration(
                color: isDarkTheme ? const Color(0xFF161921) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  if (_hardwareOk) ...[
                    _buildListTile(
                      icon: Icons.fingerprint_rounded,
                      iconBgColor: const Color(0xFFEFF6FF),
                      iconColor: const Color(0xFF5B2EE5),
                      title: l10n.biometricLogin,
                      subtitle: l10n.biometricLoginSubtitle,
                      isAr: isAr,
                      trailing: _loadingBiometric || _togglingBiometric
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: UffLoader(),
                            )
                          : Switch(
                              value: _biometricOn,
                              onChanged: _togglingBiometric ? null : _onBiometricToggle,
                              activeTrackColor: colors.accentGreen,
                            ),
                    ),
                    const Divider(height: 1, indent: 56, endIndent: 16),
                  ],
                  _buildListTile(
                    icon: Icons.password_rounded,
                    iconBgColor: const Color(0xFFEEF2FF),
                    iconColor: const Color(0xFF3F51B5),
                    title: l10n.changePin,
                    subtitle: l10n.changePinSubtitle,
                    isAr: isAr,
                    onTap: () => context.push('/pin-change'),
                  ),
                  const Divider(height: 1, indent: 56, endIndent: 16),
                  _buildListTile(
                    icon: Icons.history_toggle_off_rounded,
                    iconBgColor: const Color(0xFFF3E8FF),
                    iconColor: const Color(0xFF9333EA),
                    title: l10n.forgotPin,
                    subtitle: l10n.forgotPinSubtitle,
                    isAr: isAr,
                    onTap: () => context.push('/pin-reset'),
                  ),
                  const Divider(height: 1, indent: 56, endIndent: 16),
                  _buildListTile(
                    icon: Icons.notifications_none_rounded,
                    iconBgColor: const Color(0xFFFFF7ED),
                    iconColor: const Color(0xFFF59E0B),
                    title: l10n.notificationSettingsTitle,
                    subtitle: 'Manage push notifications and alerts',
                    isAr: isAr,
                    onTap: () => context.push('/notification-settings'),
                  ),

                ],
              ),
            ),

            // Help & Support Header
            _buildSectionLabel(l10n.helpSupport),
            const SizedBox(height: 8),

            Container(
              decoration: BoxDecoration(
                color: isDarkTheme ? const Color(0xFF161921) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: _buildListTile(
                icon: Icons.support_agent_rounded,
                iconBgColor: const Color(0xFFECFDF5),
                iconColor: const Color(0xFF059669),
                title: l10n.helpSupport,
                subtitle: l10n.helpSupportSubtitle,
                isAr: isAr,
                onTap: () => context.push('/support'),
              ),
            ),
            const SizedBox(height: 20),

            // Account Header
            _buildSectionLabel(l10n.account),
            const SizedBox(height: 8),

            // Account card list group
            Container(
              decoration: BoxDecoration(
                color: isDarkTheme ? const Color(0xFF161921) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildListTile(
                    icon: Icons.person_outline_rounded,
                    iconBgColor: const Color(0xFFEFF6FF),
                    iconColor: const Color(0xFF5B2EE5),
                    title: l10n.profile,
                    subtitle: l10n.profileSubtitle,
                    isAr: isAr,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(builder: (_) => const ProfileScreen()),
                      );
                    },
                  ),
                  const Divider(height: 1, indent: 56, endIndent: 16),
                  _buildListTile(
                    icon: Icons.credit_card_rounded,
                    iconBgColor: const Color(0xFFE0F2F1),
                    iconColor: const Color(0xFF00796B),
                    title: l10n.defaultAccountsTitle,
                    subtitle: l10n.defaultAccountsSettingsSubtitle,
                    isAr: isAr,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(builder: (_) => const DefaultAccountsScreen()),
                      );
                    },
                  ),
                  const Divider(height: 1, indent: 56, endIndent: 16),
                  _buildListTile(
                    icon: Icons.lock_outline_rounded,
                    iconBgColor: const Color(0xFFFFF7ED),
                    iconColor: const Color(0xFFD97706),
                    title: l10n.resetPassword,
                    subtitle: l10n.resetPasswordSubtitle,
                    isAr: isAr,
                    onTap: _openResetPassword,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Sign Out card list group
            Container(
              decoration: BoxDecoration(
                color: isDarkTheme ? const Color(0xFF161921) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: _buildListTile(
                icon: Icons.logout_rounded,
                iconBgColor: const Color(0xFFFEF2F2),
                iconColor: const Color(0xFFEF4444),
                title: l10n.signOut,
                titleColor: const Color(0xFFEF4444),
                isAr: isAr,
                onTap: _signOut,
                showChevron: true,
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: Color(0xFF64748B), // slate-500
          fontFamily: 'Tajawal',
        ),
      ),
    );
  }

  Widget _buildSegmentItem({
    required String label,
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: isActive ? const Color(0xFFEEF2FF) : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isActive ? const Color(0xFF5B2EE5) : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: isActive ? const Color(0xFF5B2EE5) : Colors.grey[400],
                ),
                const SizedBox(height: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isActive ? const Color(0xFF5B2EE5) : Colors.grey[500],
                    fontFamily: 'Tajawal',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    required String title,
    String? subtitle,
    Color? titleColor,
    required bool isAr,
    VoidCallback? onTap,
    Widget? trailing,
    bool showChevron = true,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Circular icon shape
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Icon(icon, color: iconColor, size: 20),
              ),
            ),
            const SizedBox(width: 14),

            // Title and Subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: titleColor ?? const Color(0xFF14152E),
                      fontFamily: 'Tajawal',
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[400],
                        fontFamily: 'Tajawal',
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Trailing Chevron or custom widget
            if (trailing != null)
              trailing
            else if (showChevron)
              Icon(
                isAr ? Icons.chevron_left_rounded : Icons.chevron_right_rounded,
                color: titleColor ?? Colors.grey[400],
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}
