import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/bank_sync_colors.dart';
import '../../../core/wallet_account_id.dart';
import '../../../l10n/app_localizations.dart';
import '../transfer_receipt.dart';
import '../transfer_receipt_pdf.dart';
import '../../../core/widgets/uff_loader.dart';

/// Transfer "done" screen — a clean, screenshot-friendly receipt with the full
/// transfer details, an expandable section, and share-as-text / share-as-PDF
/// actions. Mirrors the approved design.
class TransferSuccessView extends ConsumerStatefulWidget {
  const TransferSuccessView({
    super.key,
    required this.reference,
    required this.onNewTransfer,
    this.receipt,
  });

  final String reference;
  final VoidCallback onNewTransfer;
  final TransferReceipt? receipt;

  @override
  ConsumerState<TransferSuccessView> createState() =>
      _TransferSuccessViewState();
}

class _TransferSuccessViewState extends ConsumerState<TransferSuccessView> {
  bool _expanded = false;
  bool _favBusy = false;
  bool _sharingText = false;
  bool _sharingPdf = false;

  bool get _canCopy =>
      widget.reference.trim().isNotEmpty && widget.reference != '—';

  /// Toggles the transfer target as a server-side favorite (FAVORITE_ADD /
  /// FAVORITE_DELETE, JWT-scoped) so it survives clear-data and new devices.
  Future<void> _toggleFavorite(bool enable) async {
    final r = widget.receipt;
    if (r == null || _favBusy) return;
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    setState(() => _favBusy = true);
    try {
      final favorites = ref.read(favoritesProvider.notifier);
      if (enable) {
        await favorites.add(
          targetAccountNumber: r.toAccount,
          targetName: r.toName,
          currency: r.currency,
          transferType: 'OTHERS',
        );
      } else {
        await favorites.removeByAccount(r.toAccount);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isAr
                ? 'تعذّر تحديث المفضّلة'
                : 'Could not update favorites'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _favBusy = false);
    }
  }

  void _copyReference() {
    if (!_canCopy) return;
    Clipboard.setData(ClipboardData(text: widget.reference.trim()));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.referenceCopied)),
    );
  }

  Future<void> _share(
    Future<void> Function(TransferReceipt) action, {
    required bool isPdf,
  }) async {
    final r = widget.receipt;
    if (r == null) return;
    if (isPdf ? _sharingPdf : _sharingText) return;
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    setState(() => isPdf ? _sharingPdf = true : _sharingText = true);
    try {
      await action(r);
    } catch (e, st) {
      debugPrint('TransferSuccessView share failed (isPdf=$isPdf): $e\n$st');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                isAr ? 'تعذّر إنشاء الإيصال' : 'Could not generate receipt'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isPdf ? _sharingPdf = false : _sharingText = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final lang = Localizations.localeOf(context).languageCode;
    final isAr = lang == 'ar';
    final colors = context.bankColors;
    final r = widget.receipt;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        Center(
          child: Container(
            width: 92,
            height: 92,
            decoration: BoxDecoration(
              color: colors.success.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.check_circle_rounded,
                color: colors.success, size: 56),
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: Text(
            l10n.transferComplete,
            style: AppTextStyles.headlineMd(languageCode: lang)
                .copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(height: 20),
        if (r == null)
          _ReferenceOnly(
            reference: widget.reference,
            canCopy: _canCopy,
            onCopy: _copyReference,
          )
        else ...[
          _favoriteRow(colors, isAr),
          const SizedBox(height: 12),
          _detailsCard(r, colors, lang, isAr),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _ActionButton(
                  icon: Icons.description_outlined,
                  label: isAr ? 'نص' : 'Text',
                  busy: _sharingText,
                  onPressed: _sharingText
                      ? null
                      : () => _share(shareTransferReceiptText, isPdf: false),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ActionButton(
                  icon: Icons.ios_share_rounded,
                  label: isAr ? 'مشاركة' : 'Share',
                  busy: _sharingPdf,
                  onPressed: _sharingPdf
                      ? null
                      : () => _share(shareTransferReceipt, isPdf: true),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => context.go('/home'),
              style: FilledButton.styleFrom(
                backgroundColor: colors.secondary,
                foregroundColor: colors.onSecondary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppColors.radiusMd),
                ),
              ),
              child: Text(
                isAr ? 'الذهاب إلى الصفحة الرئيسية' : 'Go to home',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Center(
            child: TextButton(
              onPressed: widget.onNewTransfer,
              child: Text(l10n.newTransfer),
            ),
          ),
        ],
      ],
    );
  }

  Widget _favoriteRow(BankSyncColors colors, bool isAr) {
    // Live server-backed state: the switch reflects whether the target account
    // is already in the customer's favorites (shared favoritesProvider cache).
    final favorites = ref.watch(favoritesProvider);
    final toAccount = widget.receipt?.toAccount.trim() ?? '';
    final isFavorite = favorites.valueOrNull
            ?.any((f) => f.targetAccountNumber == toAccount) ??
        false;
    final suffix = Theme.of(context).brightness == Brightness.dark ? 'dark' : 'light';

    return Row(
      children: [
        Opacity(
          opacity: isFavorite ? 1.0 : 0.35,
          child: SvgPicture.asset('assets/icons/ic_favorite_star_$suffix.svg',
              width: 22, height: 22),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            isAr ? 'تعيين كمفضل' : 'Set as favorite',
            style: TextStyle(
                fontWeight: FontWeight.w600, color: colors.onSurface),
          ),
        ),
        if (_favBusy)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 14),
            child: SizedBox(
              width: 18,
              height: 18,
              child: UffLoader(),
            ),
          )
        else
          Switch(
            value: isFavorite,
            activeTrackColor: colors.secondary,
            onChanged: toAccount.isEmpty ? null : _toggleFavorite,
          ),
      ],
    );
  }

  Widget _detailsCard(
      TransferReceipt r, BankSyncColors colors, String lang, bool isAr) {
    final dateStr = DateFormat.yMMMMd(lang).format(r.date);
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppColors.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            isAr ? 'تفاصيل التحويل' : 'Transfer details',
            style: AppTextStyles.labelSm(
                color: colors.onSurfaceVariant, languageCode: lang),
          ),
          const SizedBox(height: 14),
          _field(colors, isAr ? 'المبلغ' : 'Amount',
              '${r.currency} ${r.amount}',
              emphasize: true),
          const SizedBox(height: 14),
          _field(colors, isAr ? 'إلى' : 'To',
              r.toName?.trim().isNotEmpty == true
                  ? '${r.toName}  ·  ${walletDisplayNumber(r.toAccount)}'
                  : walletDisplayNumber(r.toAccount)),
          const SizedBox(height: 14),
          _field(colors, isAr ? 'تاريخ إنشاء الأمر' : 'Order date', dateStr),
          if (_expanded) ...[
            const SizedBox(height: 14),
            _field(
                colors,
                isAr ? 'من' : 'From',
                r.fromName?.trim().isNotEmpty == true
                    ? '${r.fromName}  ·  ${maskAccount(walletDisplayNumber(r.fromAccount))}'
                    : maskAccount(walletDisplayNumber(r.fromAccount))),
            if (r.typeLabel != null && r.typeLabel!.isNotEmpty) ...[
              const SizedBox(height: 14),
              _field(colors, isAr ? 'نوع الحوالة' : 'Type', r.typeLabel!),
            ],
            const SizedBox(height: 14),
            _referenceField(colors, isAr),
          ],
          const SizedBox(height: 6),
          Divider(color: colors.outlineVariant, height: 16),
          Center(
            child: TextButton(
              onPressed: () => setState(() => _expanded = !_expanded),
              child: Text(
                _expanded
                    ? (isAr ? 'عرض أقل' : 'Show less')
                    : (isAr ? 'عرض المزيد' : 'Show more'),
                style: TextStyle(
                    color: colors.secondary, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _field(BankSyncColors colors, String label, String value,
      {bool emphasize = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 12,
                color: colors.onSurfaceVariant,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: emphasize ? 20 : 15,
            fontWeight: emphasize ? FontWeight.w700 : FontWeight.w600,
            color: colors.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _referenceField(BankSyncColors colors, bool isAr) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(isAr ? 'المرجع' : 'Reference',
            style: TextStyle(
                fontSize: 12,
                color: colors.onSurfaceVariant,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: Text(widget.reference,
                  style: AppTextStyles.monoLabel(color: colors.primary)),
            ),
            if (_canCopy)
              InkWell(
                onTap: _copyReference,
                child: Icon(Icons.content_copy_rounded,
                    size: 18, color: colors.secondary),
              ),
          ],
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.busy = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final colors = context.bankColors;
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: busy
          ? SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: colors.secondary),
            )
          : Icon(icon, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: colors.secondary,
        side: BorderSide(color: colors.secondary.withValues(alpha: 0.4)),
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppColors.radiusMd),
        ),
      ),
    );
  }
}

/// Fallback shown when no structured receipt is available (reference only).
class _ReferenceOnly extends StatelessWidget {
  const _ReferenceOnly(
      {required this.reference, required this.canCopy, required this.onCopy});

  final String reference;
  final bool canCopy;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.bankColors;
    return Material(
      color: colors.surfaceContainerLow,
      borderRadius: BorderRadius.circular(AppColors.radiusMd),
      child: InkWell(
        onTap: canCopy ? onCopy : null,
        borderRadius: BorderRadius.circular(AppColors.radiusMd),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.reference,
                        style:
                            AppTextStyles.labelSm(color: colors.onSurfaceVariant)),
                    const SizedBox(height: 4),
                    Text(reference,
                        style: AppTextStyles.monoLabel(color: colors.primary)),
                  ],
                ),
              ),
              if (canCopy)
                IconButton(
                  onPressed: onCopy,
                  icon: Icon(Icons.content_copy, color: colors.secondary),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
