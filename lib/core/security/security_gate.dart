import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../theme/app_text_styles.dart';
import '../theme/bank_sync_colors.dart';
import 'rasp_service.dart';
import 'threat_policy.dart';

/// Gate for money-movement / credential operations (everything behind the PIN
/// sheet). Returns true when the device posture allows them; otherwise shows
/// a sheet explaining the restriction and returns false.
///
/// The decision comes from the graded [ThreatPolicy] via
/// [RaspService.highestAction] — under the default `warn` policy a rooted /
/// tampered device reaches [SecurityAction.restrict] and lands here.
Future<bool> guardSensitiveOperation(BuildContext context) async {
  final action = RaspService.instance.highestAction.value;
  if (action.index < SecurityAction.restrict.index) return true;
  await showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _SecurityRestrictedSheet(),
  );
  return false;
}

/// Wraps the whole app (from `MaterialApp.builder`) and swaps the UI for a
/// full-screen block when the policy escalates to [SecurityAction.block]
/// (high-confidence tamper under the `enforce` policy). Purely reactive:
/// under `monitor`/`warn` it never engages.
class SecurityGate extends StatelessWidget {
  const SecurityGate({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<SecurityAction>(
      valueListenable: RaspService.instance.highestAction,
      child: child,
      builder: (context, action, child) {
        if (action == SecurityAction.block) {
          return const SecurityBlockScreen();
        }
        return child!;
      },
    );
  }
}

/// Terminal screen for a device the policy refuses to serve. No way back —
/// the block clears only on a fresh launch on a healthy device.
class SecurityBlockScreen extends StatelessWidget {
  const SecurityBlockScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.bankColors;
    final l10n = context.l10n;
    final languageCode = Localizations.localeOf(context).languageCode;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: colors.error.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.gpp_bad_outlined,
                    size: 48,
                    color: colors.error,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                l10n.securityBlockedTitle,
                textAlign: TextAlign.center,
                style: AppTextStyles.headlineMd(
                  color: colors.onSurface,
                  languageCode: languageCode,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                l10n.securityBlockedMessage,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMd(
                  color: colors.onSurfaceVariant,
                  languageCode: languageCode,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SecurityRestrictedSheet extends StatelessWidget {
  const _SecurityRestrictedSheet();

  @override
  Widget build(BuildContext context) {
    final colors = context.bankColors;
    final l10n = context.l10n;
    final languageCode = Localizations.localeOf(context).languageCode;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
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
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: colors.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.shield_outlined,
                size: 32,
                color: colors.error,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.securityRestrictedTitle,
            textAlign: TextAlign.center,
            style: AppTextStyles.headlineMd(
              color: colors.onSurface,
              languageCode: languageCode,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.securityRestrictedMessage,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMd(
              color: colors.onSurfaceVariant,
              languageCode: languageCode,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 56,
            child: FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                l10n.okButton,
                style: AppTextStyles.bodyMd(
                  color: colors.onSecondary,
                  languageCode: languageCode,
                ).copyWith(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
