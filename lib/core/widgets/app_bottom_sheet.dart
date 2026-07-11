import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/bank_sync_colors.dart';

/// Shared Ultimate Wallet bottom-sheet scaffold — the single source of truth for
/// sheet chrome across the app: rounded top corners, a clear drag handle, an
/// optional icon + title header, full RTL support, safe-area padding and the
/// framework's smooth open/close animation. Wrap any sheet body with this via
/// [showAppBottomSheet] so every sheet reads as one system.
Future<T?> showAppBottomSheet<T>(
  BuildContext context, {
  required Widget child,
  String? title,
  IconData? icon,
  bool isScrollControlled = false,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    backgroundColor: Colors.transparent,
    builder: (_) => AppBottomSheet(title: title, icon: icon, child: child),
  );
}

/// The chrome used by [showAppBottomSheet]. Can also be used directly as the
/// `builder` result of a `showModalBottomSheet` call.
class AppBottomSheet extends StatelessWidget {
  const AppBottomSheet({
    super.key,
    required this.child,
    this.title,
    this.icon,
  });

  final Widget child;
  final String? title;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final colors = context.bankColors;
    final lang = Localizations.localeOf(context).languageCode;

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.outlineVariant,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            if (title != null) ...[
              const SizedBox(height: 18),
              Row(
                children: [
                  if (icon != null) ...[
                    Container(
                      width: 40,
                      height: 40,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: colors.secondaryFixed,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, color: colors.secondary, size: 22),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: Text(
                      title!,
                      style: AppTextStyles.headlineMd(
                        color: colors.onSurface,
                        languageCode: lang,
                      ).copyWith(fontSize: 18, fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

/// Professional "coming soon" sheet in the Ultimate Wallet identity. Shown when
/// a not-yet-built service tile is tapped. Purely informational — no backend,
/// no fake data.
Future<void> showComingSoonSheet(
  BuildContext context, {
  required String serviceName,
  String? description,
  IconData icon = Icons.rocket_launch_rounded,
}) {
  return showAppBottomSheet<void>(
    context,
    child: _ComingSoonBody(
      serviceName: serviceName,
      description: description,
      icon: icon,
    ),
  );
}

class _ComingSoonBody extends StatelessWidget {
  const _ComingSoonBody({
    required this.serviceName,
    required this.description,
    required this.icon,
  });

  final String serviceName;
  final String? description;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = context.bankColors;
    final l10n = context.l10n;
    final lang = Localizations.localeOf(context).languageCode;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 72,
          height: 72,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: colors.secondaryFixed,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: colors.secondary, size: 34),
        ),
        const SizedBox(height: 16),
        // "قريبًا" badge.
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: AppColors.warning.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(AppColors.radiusPill),
          ),
          child: Text(
            l10n.walletComingSoon,
            style: AppTextStyles.labelSm(
              color: const Color(0xFF9A6B00),
              languageCode: lang,
            ).copyWith(fontWeight: FontWeight.w800, fontSize: 12),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          serviceName,
          textAlign: TextAlign.center,
          style: AppTextStyles.headlineMd(
            color: colors.onSurface,
            languageCode: lang,
          ).copyWith(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Text(
          description ?? l10n.comingSoonSheetMessage,
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyMd(
            color: colors.onSurfaceVariant,
            languageCode: lang,
          ).copyWith(height: 1.5),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            style: FilledButton.styleFrom(
              backgroundColor: colors.secondary,
              foregroundColor: colors.onSecondary,
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: const StadiumBorder(),
              elevation: 0,
            ),
            child: Text(
              l10n.closeButton,
              style: AppTextStyles.labelSm(color: colors.onSecondary)
                  .copyWith(fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }
}

/// One row inside a [showServiceOptionsSheet] — a sub-service of a grouped
/// service tile (e.g. "تحويل إلى مشترك" under "التحويلات المالية"). Either a
/// real action ([onTap]) or a not-yet-built one ([comingSoon]).
class ServiceSheetOption {
  const ServiceSheetOption({
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.accent,
    this.comingSoon = false,
  });

  final IconData icon;
  final String title;
  final String? subtitle;

  /// Runs after the sheet is dismissed. For [comingSoon] rows this typically
  /// opens [showComingSoonSheet]; bind it to the *screen* context (not the
  /// sheet's) so it stays valid once the sheet pops.
  final VoidCallback onTap;

  /// Optional per-row accent; falls back to the brand secondary.
  final Color? accent;
  final bool comingSoon;
}

/// A grouped-service sheet: an organised, RTL-correct vertical list of
/// sub-services in the shared Ultimate Wallet sheet chrome. Used by services
/// that hold more than one action (Transfers / Recharge & Pay / Purchases).
Future<void> showServiceOptionsSheet(
  BuildContext context, {
  required String title,
  required IconData icon,
  required List<ServiceSheetOption> options,
}) {
  return showAppBottomSheet<void>(
    context,
    title: title,
    icon: icon,
    child: _ServiceOptionsList(options: options),
  );
}

class _ServiceOptionsList extends StatelessWidget {
  const _ServiceOptionsList({required this.options});

  final List<ServiceSheetOption> options;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < options.length; i++) ...[
          if (i > 0) const SizedBox(height: 10),
          _ServiceOptionRow(option: options[i]),
        ],
      ],
    );
  }
}

class _ServiceOptionRow extends StatelessWidget {
  const _ServiceOptionRow({required this.option});

  final ServiceSheetOption option;

  @override
  Widget build(BuildContext context) {
    final colors = context.bankColors;
    final l10n = context.l10n;
    final lang = Localizations.localeOf(context).languageCode;
    final accent = option.accent ?? colors.secondary;
    final soon = option.comingSoon;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppColors.radiusMd),
        border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.7)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // Dismiss the sheet first, then run the (screen-context-bound)
            // action so navigation / coming-soon sheet has a valid context.
            Navigator.of(context).pop();
            option.onTap();
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(option.icon, color: accent, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        option.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodyMd(
                          color: colors.onSurface,
                          languageCode: lang,
                        ).copyWith(fontWeight: FontWeight.w700, fontSize: 14.5),
                      ),
                      if (option.subtitle != null) ...[
                        const SizedBox(height: 3),
                        Text(
                          option.subtitle!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.labelSm(
                            color: colors.onSurfaceVariant,
                            languageCode: lang,
                          ).copyWith(fontSize: 11.5, height: 1.3),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                if (soon)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(AppColors.radiusPill),
                    ),
                    child: Text(
                      l10n.walletComingSoon,
                      style: AppTextStyles.labelSm(
                        color: const Color(0xFF9A6B00),
                        languageCode: lang,
                      ).copyWith(fontWeight: FontWeight.w800, fontSize: 10),
                    ),
                  )
                else
                  Icon(
                    Directionality.of(context) == TextDirection.rtl
                        ? Icons.chevron_left_rounded
                        : Icons.chevron_right_rounded,
                    color: colors.onSurfaceVariant,
                    size: 22,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
