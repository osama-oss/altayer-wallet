import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/bank_sync_colors.dart';

/// Review screen shown right after a QR is scanned. It never moves money — it
/// presents the resolved recipient and lets the user enter an amount / note,
/// then hands off to the real transfer flow (`/transfer/others`) which performs
/// validation and PIN confirmation. Recipient name / bank arrive from the core
/// on the next step; here we show what the QR carries plus a masked account.
class ScanReviewScreen extends StatefulWidget {
  const ScanReviewScreen({
    super.key,
    required this.account,
    this.recipientName,
    this.currency,
  });

  final String account;
  final String? recipientName;
  final String? currency;

  @override
  State<ScanReviewScreen> createState() => _ScanReviewScreenState();
}

class _ScanReviewScreenState extends State<ScanReviewScreen> {
  final _amount = TextEditingController();
  final _note = TextEditingController();

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  String get _maskedAccount {
    final n = widget.account.trim();
    if (n.length <= 4) return n;
    return '•••• •••• ${n.substring(n.length - 4)}';
  }

  void _continue() {
    final amount = double.tryParse(_amount.text.trim());
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('أدخل مبلغًا صحيحًا للمتابعة'),
        ),
      );
      return;
    }
    // Hand off to the vetted transfer flow (validation + PIN live there).
    // Note: the optional note is captured here and will be forwarded once the
    // core transfer payload supports it.
    final to = Uri.encodeComponent(widget.account.trim());
    final amt = Uri.encodeComponent(_amount.text.trim());
    context.push('/transfer/others?to=$to&amount=$amt');
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.bankColors;
    final lang = Localizations.localeOf(context).languageCode;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: Text(
          'مراجعة التحويل',
          style: AppTextStyles.headlineMd(color: colors.primary, languageCode: lang)
              .copyWith(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _RecipientCard(
                colors: colors,
                lang: lang,
                name: widget.recipientName,
                maskedAccount: _maskedAccount,
                currency: widget.currency,
              ),
              const SizedBox(height: 22),
              _FieldLabel(text: 'المبلغ', colors: colors, lang: lang),
              const SizedBox(height: 8),
              _AmountField(
                controller: _amount,
                currency: widget.currency,
                colors: colors,
                lang: lang,
              ),
              const SizedBox(height: 20),
              _FieldLabel(text: 'ملاحظة (اختياري)', colors: colors, lang: lang),
              const SizedBox(height: 8),
              _NoteField(controller: _note, colors: colors, lang: lang),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _continue,
                  style: FilledButton.styleFrom(
                    backgroundColor: colors.secondary,
                    foregroundColor: colors.onSecondary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: const StadiumBorder(),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'متابعة التحويل',
                        style: AppTextStyles.labelSm(color: colors.onSecondary)
                            .copyWith(fontWeight: FontWeight.w700, fontSize: 15),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward_rounded, size: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecipientCard extends StatelessWidget {
  const _RecipientCard({
    required this.colors,
    required this.lang,
    required this.name,
    required this.maskedAccount,
    required this.currency,
  });

  final BankSyncColors colors;
  final String lang;
  final String? name;
  final String maskedAccount;
  final String? currency;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppColors.radiusLg),
        border: Border.all(color: colors.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: colors.cardShadow,
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: colors.secondaryFixed,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: colors.secondary.withValues(alpha: 0.18),
                  ),
                ),
                child: Icon(Icons.person_rounded,
                    color: colors.secondary, size: 30),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (name != null && name!.trim().isNotEmpty)
                          ? name!.trim()
                          : 'المستلم',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.headlineMd(
                        color: colors.onSurface,
                        languageCode: lang,
                      ).copyWith(fontSize: 16, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'محفظة Ultimate Wallet',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.labelSm(
                        color: colors.onSurfaceVariant,
                        languageCode: lang,
                      ).copyWith(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Divider(height: 1, color: colors.outlineVariant),
          const SizedBox(height: 14),
          _InfoRow(
            label: 'رقم الحساب',
            value: maskedAccount,
            colors: colors,
            lang: lang,
            valueLtr: true,
          ),
          if (currency != null && currency!.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            _InfoRow(
              label: 'العملة',
              value: currency!.trim().toUpperCase(),
              colors: colors,
              lang: lang,
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    required this.colors,
    required this.lang,
    this.valueLtr = false,
  });

  final String label;
  final String value;
  final BankSyncColors colors;
  final String lang;
  final bool valueLtr;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: AppTextStyles.labelSm(
            color: colors.onSurfaceVariant,
            languageCode: lang,
          ).copyWith(fontWeight: FontWeight.w600),
        ),
        const Spacer(),
        Text(
          value,
          textDirection: valueLtr ? TextDirection.ltr : null,
          style: AppTextStyles.bodyMd(color: colors.onSurface, languageCode: lang)
              .copyWith(fontWeight: FontWeight.w700, letterSpacing: 0.4),
        ),
      ],
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({
    required this.text,
    required this.colors,
    required this.lang,
  });

  final String text;
  final BankSyncColors colors;
  final String lang;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTextStyles.labelSm(
        color: colors.onSurfaceVariant,
        languageCode: lang,
      ).copyWith(fontWeight: FontWeight.w600),
    );
  }
}

class _AmountField extends StatelessWidget {
  const _AmountField({
    required this.controller,
    required this.currency,
    required this.colors,
    required this.lang,
  });

  final TextEditingController controller;
  final String? currency;
  final BankSyncColors colors;
  final String lang;

  @override
  Widget build(BuildContext context) {
    final isAr = lang == 'ar';
    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.outlineVariant),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: colors.secondary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              (currency == null || currency!.trim().isEmpty)
                  ? '—'
                  : currency!.trim().toUpperCase(),
              style: AppTextStyles.labelSm(
                color: colors.secondary,
                languageCode: lang,
              ).copyWith(fontSize: 14, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
              ],
              textDirection: TextDirection.ltr,
              textAlign: isAr ? TextAlign.right : TextAlign.left,
              style: AppTextStyles.balanceDisplay(color: colors.onSurface)
                  .copyWith(fontSize: 30, fontWeight: FontWeight.w700),
              decoration: InputDecoration(
                isCollapsed: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 6),
                border: InputBorder.none,
                hintText: '0.00',
                hintStyle: AppTextStyles.balanceDisplay(
                  color: colors.onSurfaceVariant.withValues(alpha: 0.25),
                ).copyWith(fontSize: 30, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NoteField extends StatelessWidget {
  const _NoteField({
    required this.controller,
    required this.colors,
    required this.lang,
  });

  final TextEditingController controller;
  final BankSyncColors colors;
  final String lang;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.outlineVariant),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Icon(Icons.edit_note_rounded, color: colors.secondary, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller,
              maxLength: 140,
              minLines: 1,
              maxLines: 3,
              style: AppTextStyles.bodyMd(color: colors.onSurface, languageCode: lang)
                  .copyWith(fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                isCollapsed: true,
                counterText: '',
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
                border: InputBorder.none,
                hintText: 'اكتب ملاحظة للمستلم',
                hintStyle: AppTextStyles.bodyMd(
                  color: colors.onSurfaceVariant,
                  languageCode: lang,
                ).copyWith(fontWeight: FontWeight.w500, fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
