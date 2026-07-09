import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/bank_sync_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../transfer_helpers.dart';
import '../../../core/widgets/uff_loader.dart';

/// Collapsible currency-exchange card shown when the debit and credit
/// currencies differ. Collapsed by default — it shows the converted amount at a
/// glance and expands to reveal the full breakdown (you send / deal rate /
/// recipient gets).
class TransferRateCard extends StatefulWidget {
  const TransferRateCard({super.key, required this.quote, required this.loading});

  final TransferQuote? quote;
  final bool loading;

  @override
  State<TransferRateCard> createState() => _TransferRateCardState();
}

class _TransferRateCardState extends State<TransferRateCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final q = widget.quote;
    if (q == null && !widget.loading) return const SizedBox.shrink();
    if (q != null && !q.isCrossCurrency) return const SizedBox.shrink();

    final colors = context.bankColors;
    final l10n = context.l10n;
    final lang = Localizations.localeOf(context).languageCode;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 16),
      decoration: BoxDecoration(
        color: colors.secondary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppColors.radiusLg),
        border: Border.all(color: colors.secondary.withValues(alpha: 0.20)),
      ),
      child: q == null
          ? _loadingBar(colors, l10n)
          : Column(
              children: [
                _header(q, colors, l10n, lang),
                AnimatedSize(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  alignment: Alignment.topCenter,
                  child: _expanded
                      ? _details(q, colors, l10n, lang)
                      : const SizedBox(width: double.infinity),
                ),
              ],
            ),
    );
  }

  Widget _loadingBar(BankSyncColors colors, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: UffLoader(),
          ),
          const SizedBox(width: 10),
          Text(l10n.fetchingRate,
              style: AppTextStyles.labelSm(color: colors.onSurfaceVariant)),
        ],
      ),
    );
  }

  Widget _header(
      TransferQuote q, BankSyncColors colors, AppLocalizations l10n, String lang) {
    final money = NumberFormat('#,##0.##');
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => setState(() => _expanded = !_expanded),
        borderRadius: BorderRadius.circular(AppColors.radiusLg),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(Icons.currency_exchange_rounded, size: 18, color: colors.secondary),
              const SizedBox(width: 10),
              Text(
                l10n.dealRate,
                style: AppTextStyles.labelSm(
                  color: colors.onSurfaceVariant,
                  languageCode: lang,
                ).copyWith(fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              Text(
                '≈ ${money.format(q.creditAmount)} ${q.creditCurrency}',
                textDirection: TextDirection.ltr,
                style: AppTextStyles.monoLabel(color: colors.secondary)
                    .copyWith(fontSize: 14, fontWeight: FontWeight.w700),
              ),
              const SizedBox(width: 6),
              AnimatedRotation(
                turns: _expanded ? 0.5 : 0,
                duration: const Duration(milliseconds: 220),
                child: Icon(Icons.keyboard_arrow_down_rounded,
                    color: colors.onSurfaceVariant, size: 22),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _details(
      TransferQuote q, BankSyncColors colors, AppLocalizations l10n, String lang) {
    final money = NumberFormat('#,##0.##');
    final rateFmt = NumberFormat('#,##0.####');
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      child: Column(
        children: [
          Divider(height: 1, color: colors.secondary.withValues(alpha: 0.18)),
          const SizedBox(height: 12),
          _row(colors, lang, l10n.youSend,
              '${money.format(q.debitAmount)} ${q.debitCurrency}'),
          if (q.dealRate != null) ...[
            const SizedBox(height: 12),
            _row(colors, lang, l10n.dealRate,
                '1 ${q.creditCurrency} = ${rateFmt.format(q.dealRate)} ${q.debitCurrency}'),
          ],
          const SizedBox(height: 12),
          _row(colors, lang, l10n.recipientGets,
              '${money.format(q.creditAmount)} ${q.creditCurrency}',
              emphasize: true),
        ],
      ),
    );
  }

  Widget _row(BankSyncColors colors, String lang, String label, String value,
      {bool emphasize = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: AppTextStyles.labelSm(
                color: colors.onSurfaceVariant, languageCode: lang),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 3,
          child: Text(
            value,
            textAlign: TextAlign.end,
            textDirection: TextDirection.ltr,
            style: AppTextStyles.monoLabel(
              color: emphasize ? colors.secondary : colors.onSurface,
            ).copyWith(
              fontSize: emphasize ? 16 : 13,
              fontWeight: emphasize ? FontWeight.w700 : FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
