import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/bank_sync_colors.dart';
import '../../core/widgets/uff_ui.dart';
import '../../l10n/app_localizations.dart';

/// Transfer landing — a chooser of tappable boxes. Each opens a dedicated
/// page: between my accounts · to another customer · open a new account.
class TransferScreen extends StatelessWidget {
  const TransferScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.bankColors;

    final choices = <_TransferChoice>[
      _TransferChoice(
        icon: Icons.swap_horiz_rounded,
        title: l10n.transferToMyAccounts,
        subtitle: l10n.betweenYourAccountsSubtitle,
        onTap: () => context.push('/transfer/own'),
      ),
      _TransferChoice(
        icon: Icons.person_outline_rounded,
        title: l10n.transferToOthers,
        subtitle: l10n.transferOthersSubtitle,
        onTap: () => context.push('/transfer/others'),
      ),
      _TransferChoice(
        icon: Icons.add_card_outlined,
        title: l10n.addAccount,
        subtitle: l10n.addAccountSubtitle,
        onTap: () => context.push('/add-account'),
      ),
    ];

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(title: Text(l10n.navTransfers), centerTitle: true),
      body: SafeArea(
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
          itemCount: choices.length,
          separatorBuilder: (_, __) => const SizedBox(height: 14),
          itemBuilder: (_, i) => _TransferChoiceCard(choice: choices[i]),
        ),
      ),
    );
  }
}

class _TransferChoice {
  const _TransferChoice({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
}

class _TransferChoiceCard extends StatelessWidget {
  const _TransferChoiceCard({required this.choice});

  final _TransferChoice choice;

  @override
  Widget build(BuildContext context) {
    final colors = context.bankColors;
    final lang = Localizations.localeOf(context).languageCode;
    return Material(
      color: colors.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(AppColors.radiusXl),
      child: InkWell(
        onTap: choice.onTap,
        borderRadius: BorderRadius.circular(AppColors.radiusXl),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppColors.radiusXl),
            border: Border.all(color: colors.outlineVariant),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: colors.secondary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(choice.icon, color: colors.secondary, size: 26),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      choice.title,
                      style: AppTextStyles.bodyMd(
                        color: colors.onSurface,
                        languageCode: lang,
                      ).copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      choice.subtitle,
                      style: AppTextStyles.labelSm(
                        color: colors.onSurfaceVariant,
                        languageCode: lang,
                      ).copyWith(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(uffForwardChevron(context), size: 16, color: colors.outline),
            ],
          ),
        ),
      ),
    );
  }
}
