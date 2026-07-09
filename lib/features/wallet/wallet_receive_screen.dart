import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/models/banking_account.dart';
import '../../core/qr/account_qr_payload.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/bank_sync_colors.dart';
import '../../l10n/app_localizations.dart';

/// Wallet "receive" screen — renders the customer's real account QR
/// ([AccountQrPayload]) so another «عَ الطاير» / UFF user can scan it and pay
/// into this wallet. Uses the existing account-QR payload the transfer scanner
/// already decodes, so receive ↔ scan interoperate out of the box.
class WalletReceiveScreen extends StatelessWidget {
  const WalletReceiveScreen({super.key, required this.account});

  final BankingAccount account;

  @override
  Widget build(BuildContext context) {
    final colors = context.bankColors;
    final l10n = context.l10n;
    final lang = Localizations.localeOf(context).languageCode;
    final data = AccountQrPayload(
      accountNumber: account.accountNumber,
      currency: account.currency,
      label: account.label,
    ).encode();

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(title: Text(l10n.walletReceiveTitle), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppColors.radiusLg),
                boxShadow: [
                  BoxShadow(
                    color: colors.cardShadow,
                    blurRadius: 28,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: QrImageView(
                data: data,
                version: QrVersions.auto,
                size: 236,
                backgroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 22),
            Text(
              l10n.walletReceiveShareHint,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMd(
                color: colors.onSurfaceVariant,
                languageCode: lang,
              ),
            ),
            const SizedBox(height: 24),
            _NumberCard(
              label: l10n.walletNumberLabel,
              value: account.accountNumber,
              copiedLabel: l10n.copied,
              colors: colors,
              lang: lang,
            ),
          ],
        ),
      ),
    );
  }
}

class _NumberCard extends StatelessWidget {
  const _NumberCard({
    required this.label,
    required this.value,
    required this.copiedLabel,
    required this.colors,
    required this.lang,
  });

  final String label;
  final String value;
  final String copiedLabel;
  final BankSyncColors colors;
  final String lang;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppColors.radiusMd),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.labelSm(
                    color: colors.onSurfaceVariant,
                    languageCode: lang,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: AppTextStyles.bodyMd(color: colors.onSurface, languageCode: lang)
                      .copyWith(fontWeight: FontWeight.w700, letterSpacing: 0.5),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.content_copy_rounded, color: colors.secondary, size: 20),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: value));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(copiedLabel)),
              );
            },
          ),
        ],
      ),
    );
  }
}
