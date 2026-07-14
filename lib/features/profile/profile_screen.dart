import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/profile_helpers.dart';
import '../../core/providers/app_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/bank_sync_colors.dart';
import '../../l10n/app_localizations.dart';
import '../../core/widgets/uff_loader.dart';
import '../kyc/kyc_providers.dart';
import '../kyc/kyc_status.dart';
import '../kyc/widgets/kyc_status_badge.dart';

/// Read-only profile screen. Renders the customer details already cached from
/// `userDetail` / `CUSTOMER-DATA` at login, plus a live verification (KYC)
/// status card driven by [kycStatusProvider]. Editing and avatar upload need
/// core support, so they are intentionally out of scope.
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _loading = true;
  Map<String, dynamic>? _profile;
  String? _username;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final auth = ref.read(authServiceProvider);
    final profile = await auth.readProfile();
    final username = await auth.readUsername();
    if (!mounted) return;
    setState(() {
      _profile = profile;
      _username = username;
      _loading = false;
    });
  }

  /// First non-empty value among [keys] in the cached profile.
  String? _pick(List<String> keys) {
    final profile = _profile;
    if (profile == null) return null;
    for (final key in keys) {
      final value = profile[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString().trim();
      }
    }
    return null;
  }

  String _initials(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '?';
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return trimmed[0].toUpperCase();
  }

  void _copy(String value) {
    Clipboard.setData(ClipboardData(text: value));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.copied)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.bankColors;
    final languageCode = Localizations.localeOf(context).languageCode;
    // While KYC is disabled (dead code), don't watch the provider — that avoids
    // hitting the KYC backend during app testing.
    final kycAsync = kycFeatureEnabled ? ref.watch(kycStatusProvider) : null;
    final kycStatus = kycAsync?.valueOrNull?.status;
    // Loading / unknown → do not show "unverified" chrome for a verified user.
    final showAsVerified = kycStatus?.isVerified ?? false;

    final fullName =
        _pick(['fullName', 'name', 'customerName']) ?? _username ?? '';
    final username = _pick(['preferredUsername', 'username']) ?? _username;
    final customerId = coreCustomerIdFromProfile(
      _profile ?? const {},
      usernameFallback: _username,
    );
    final mobile = _pick(['mobile', 'mobileNo', 'mobileNumber', 'phone']);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(title: Text(l10n.profile), centerTitle: true),
      body: _loading
          ? const Center(child: UffLoader())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
              children: [
                _Header(
                  initials: _initials(
                      fullName.isNotEmpty ? fullName : (username ?? '?')),
                  name: fullName.isNotEmpty ? fullName : (username ?? ''),
                  username: username,
                  verified: showAsVerified,
                  colors: colors,
                  languageCode: languageCode,
                ),
                const SizedBox(height: 20),
                if (kycFeatureEnabled && kycStatus != null) ...[
                  _VerificationCard(status: kycStatus),
                  const SizedBox(height: 20),
                ],
                Container(
                  decoration: BoxDecoration(
                    color: colors.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(AppColors.radiusLg),
                    border: Border.all(color: colors.outlineVariant),
                  ),
                  child: Column(
                    children: [
                      if (fullName.isNotEmpty)
                        _InfoRow(
                          icon: Icons.badge_outlined,
                          label: l10n.fullName,
                          value: fullName,
                          colors: colors,
                          languageCode: languageCode,
                        ),
                      if (customerId.isNotEmpty) ...[
                        _divider(colors),
                        _InfoRow(
                          icon: Icons.tag_rounded,
                          label: l10n.coreCustomerId,
                          value: customerId,
                          colors: colors,
                          languageCode: languageCode,
                          onCopy: () => _copy(customerId),
                        ),
                      ],
                      if (username != null && username.isNotEmpty) ...[
                        _divider(colors),
                        _InfoRow(
                          icon: Icons.alternate_email_rounded,
                          label: l10n.username,
                          value: username,
                          colors: colors,
                          languageCode: languageCode,
                        ),
                      ],
                      if (mobile != null && mobile.isNotEmpty) ...[
                        _divider(colors),
                        _InfoRow(
                          icon: Icons.phone_outlined,
                          label: l10n.mobile,
                          value: mobile,
                          colors: colors,
                          languageCode: languageCode,
                          onCopy: () => _copy(mobile),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _divider(BankSyncColors colors) => Divider(
      height: 1, indent: 56, endIndent: 16, color: colors.outlineVariant);
}

/// Verification status card. Tappable for any non-terminal state — actionable
/// states (unverified/incomplete/rejected) show a "complete verification" cue,
/// pending/verified open the read-only status view.
class _VerificationCard extends StatelessWidget {
  const _VerificationCard({required this.status});

  final KycStatus status;

  @override
  Widget build(BuildContext context) {
    final colors = context.bankColors;
    final actionable = status.canSubmit;
    final color = (status == KycStatus.unverified || status == KycStatus.incomplete)
        ? colors.error
        : status.color(colors);

    return InkWell(
      onTap: () => context.push('/kyc'),
      borderRadius: BorderRadius.circular(18),
      child: KycStatusCard(
        status: status,
        trailing: actionable
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Directionality.of(context) == TextDirection.rtl
                        ? Icons.chevron_left_rounded
                        : Icons.chevron_right_rounded,
                    color: color,
                  ),
                ],
              )
            : (status.isVerified
                ? Icon(Icons.verified_rounded,
                    color: colors.accentGreen, size: 22)
                : null),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.initials,
    required this.name,
    required this.username,
    required this.verified,
    required this.colors,
    required this.languageCode,
  });

  final String initials;
  final String name;
  final String? username;
  final bool verified;
  final BankSyncColors colors;
  final String languageCode;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 96,
              height: 96,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                gradient: AppColors.brandGradient,
                shape: BoxShape.circle,
              ),
              child: Text(
                initials,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 34,
                ),
              ),
            ),
            // Verified check overlaid on the avatar.
            if (verified)
              PositionedDirectional(
                end: -2,
                bottom: -2,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: colors.background,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.verified_rounded,
                      color: colors.accentGreen, size: 26),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                name,
                textAlign: TextAlign.center,
                style: AppTextStyles.headlineMd(languageCode: languageCode)
                    .copyWith(color: colors.onSurface, fontWeight: FontWeight.w700),
              ),
            ),
            if (verified) ...[
              const SizedBox(width: 6),
              Icon(Icons.verified_rounded, color: colors.accentGreen, size: 20),
            ],
          ],
        ),
        if (username != null && username!.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            '@$username',
            textDirection: TextDirection.ltr,
            style: AppTextStyles.bodyMd(
              color: colors.onSurfaceVariant,
              languageCode: languageCode,
            ),
          ),
        ],
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.colors,
    required this.languageCode,
    this.onCopy,
  });

  final IconData icon;
  final String label;
  final String value;
  final BankSyncColors colors;
  final String languageCode;
  final VoidCallback? onCopy;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: colors.secondary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppColors.radiusMd),
            ),
            child: Icon(icon, color: colors.secondary, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.labelSm(
                    color: colors.onSurfaceVariant,
                    languageCode: languageCode,
                  ).copyWith(fontSize: 12),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyMd(
                    color: colors.onSurface,
                    languageCode: languageCode,
                  ).copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          if (onCopy != null)
            IconButton(
              onPressed: onCopy,
              icon: Icon(Icons.content_copy_rounded,
                  size: 18, color: colors.secondary),
            ),
        ],
      ),
    );
  }
}
