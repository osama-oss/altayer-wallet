import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:banksync_app/core/network/api_exception.dart';
import 'package:banksync_app/core/network/banking_auth_exceptions.dart';
import 'package:banksync_app/core/providers/app_providers.dart';
import 'package:banksync_app/core/providers/locale_provider.dart';
import 'package:banksync_app/core/providers/theme_mode_provider.dart';
import 'package:banksync_app/core/theme/bank_sync_colors.dart';
import 'package:banksync_app/core/widgets/db_settings_widgets.dart';
import 'package:banksync_app/core/widgets/pin_entry_sheet.dart';
import 'package:banksync_app/l10n/app_localizations.dart';
import 'package:banksync_app/features/settings/default_accounts_screen.dart';
import 'package:banksync_app/router/app_router.dart';
import '../../core/widgets/uff_loader.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
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
    // Prefer password so the router does not bounce logout → biometric page.
    await ref.read(authServiceProvider).switchToPasswordLogin();
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
    final errorColor = Theme.of(context).colorScheme.error;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        DbSettingsSectionLabel(label: l10n.appearance),
        DbSettingsGroup(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Iconsax.color_swatch, color: colors.secondary, size: 22),
                      const SizedBox(width: 12),
                      Text(l10n.theme, style: Theme.of(context).textTheme.titleMedium),
                    ],
                  ),
                  const SizedBox(height: 12),
                  DbThemeModeSelector(
                    selected: themeMode,
                    lightLabel: l10n.themeLight,
                    darkLabel: l10n.themeDark,
                    systemLabel: l10n.themeSystem,
                    onChanged: (mode) =>
                        ref.read(themeModeProvider.notifier).setThemeMode(mode),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Icon(Iconsax.translate, color: colors.secondary, size: 22),
                      const SizedBox(width: 12),
                      Text(l10n.language, style: Theme.of(context).textTheme.titleMedium),
                    ],
                  ),
                  const SizedBox(height: 12),
                  DbLanguageSelector(
                    selected: locale,
                    englishLabel: l10n.languageEnglish,
                    arabicLabel: l10n.languageArabic,
                    chineseLabel: l10n.languageChinese,
                    onChanged: (value) =>
                        ref.read(localeProvider.notifier).setLocale(value),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        DbSettingsSectionLabel(label: l10n.security),
        DbSettingsGroup(
          children: [
            if (_hardwareOk)
              DbSettingsTile(
                icon: Iconsax.finger_scan,
                title: l10n.biometricLogin,
                subtitle: l10n.biometricLoginSubtitle,
                trailing: _loadingBiometric || _togglingBiometric
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: UffLoader(),
                      )
                    : Switch(
                        value: _biometricOn,
                        onChanged: _togglingBiometric ? null : _onBiometricToggle,
                        activeTrackColor: colors.accentGreen,
                      ),
              ),
            DbSettingsTile(
              icon: Iconsax.password_check,
              title: l10n.changePin,
              subtitle: l10n.changePinSubtitle,
              onTap: () => context.push('/pin-change'),
            ),
            DbSettingsTile(
              icon: Iconsax.lock_1,
              title: l10n.forgotPin,
              subtitle: l10n.forgotPinSubtitle,
              onTap: () => context.push('/pin-reset'),
            ),
            DbSettingsTile(
              icon: Icons.notifications_none,
              title: l10n.notificationSettingsTitle,
              subtitle: 'Manage push notifications and alerts',
              onTap: () => context.push('/notification-settings'),
            ),

          ],
        ),
        const SizedBox(height: 16),
        DbSettingsSectionLabel(label: l10n.helpSupport),
        DbSettingsGroup(
          children: [
            DbSettingsTile(
              icon: Iconsax.headphone,
              title: l10n.helpSupport,
              subtitle: l10n.helpSupportSubtitle,
              onTap: () => context.push('/support'),
            ),
            DbSettingsTile(
              icon: Icons.description_outlined,
              title: l10n.termsAndConditions,
              subtitle: l10n.termsAndConditionsSubtitle,
              onTap: () => context.push('/terms'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        DbSettingsSectionLabel(label: l10n.account),
        DbSettingsGroup(
          children: [
            DbSettingsTile(
              icon: Iconsax.wallet_3,
              title: l10n.defaultAccountsTitle,
              subtitle: l10n.defaultAccountsSettingsSubtitle,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const DefaultAccountsScreen()),
                );
              },
            ),
            DbSettingsTile(
              icon: Iconsax.lock,
              title: l10n.resetPassword,
              subtitle: l10n.resetPasswordSubtitle,
              onTap: _openResetPassword,
            ),
          ],
        ),
        const SizedBox(height: 16),
        DbSettingsGroup(
          children: [
            DbSettingsTile(
              icon: Iconsax.logout,
              title: l10n.signOut,
              titleColor: errorColor,
              iconColor: errorColor,
              onTap: _signOut,
            ),
          ],
        ),
      ],
    );
  }
}
