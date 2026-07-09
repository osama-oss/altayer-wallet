import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/network/api_exception.dart';
import '../../core/providers/app_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/bank_sync_colors.dart';
import '../../core/widgets/uff_ui.dart';
import '../../l10n/app_localizations.dart';
import 'bill_review_screen.dart';
import 'data/bill_inquiry.dart';
import 'data/biller.dart';
import '../../core/widgets/uff_loader.dart';

/// Step 1 of the bill flow: subscriber number in → provider truth out
/// (name/amount/line type come from `BILL_INQUIRY`, never typed by the user).
class BillInquiryScreen extends ConsumerStatefulWidget {
  const BillInquiryScreen({super.key, required this.biller});

  final Biller biller;

  @override
  ConsumerState<BillInquiryScreen> createState() => _BillInquiryScreenState();
}

class _BillInquiryScreenState extends ConsumerState<BillInquiryScreen> {
  final _controller = TextEditingController();
  bool _loading = false;
  String? _error;
  BillInquiry? _inquiry;
  String? _inquiredNumber;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _inputLabel(AppLocalizations l10n) {
    switch (widget.biller.inputLabel) {
      case 'SUBSCRIBER_NO':
        return l10n.subscriberNumberLabel;
      case 'ACCOUNT_NO':
        return l10n.billAccountNoLabel;
      default:
        return l10n.phoneNumberLabel;
    }
  }

  Future<void> _inquire() async {
    final l10n = context.l10n;
    final value = _controller.text.trim();
    if (!widget.biller.matchesInput(value)) {
      setState(() => _error = l10n.invalidSubscriberNumber);
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
      _inquiry = null;
    });
    try {
      final token = await ref.read(authServiceProvider).readToken();
      if (token == null || token.isEmpty) return;
      final data = await ref.read(apiClientProvider).inquireBill(
            token,
            billerCode: widget.biller.code,
            subscriberNo: value,
          );
      if (!mounted) return;
      setState(() {
        _inquiry = BillInquiry.fromMap(data);
        _inquiredNumber = value;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _continue() {
    final inquiry = _inquiry;
    final number = _inquiredNumber;
    if (inquiry == null || number == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BillReviewScreen(
          biller: widget.biller,
          subscriberNo: number,
          inquiry: inquiry,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.bankColors;
    final languageCode = Localizations.localeOf(context).languageCode;
    final biller = widget.biller;
    final inquiry = _inquiry;
    final themeAsset = biller.getThemeAssetIcon(context);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(title: Text(biller.localizedName(languageCode)), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 72,
                height: 72,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: biller.accentColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: themeAsset != null
                    ? ClipOval(
                        child: themeAsset.endsWith('.svg')
                            ? SvgPicture.asset(
                                themeAsset,
                                width: 52,
                                height: 52,
                                fit: BoxFit.contain,
                              )
                            : Image.asset(
                                themeAsset,
                                width: 52,
                                height: 52,
                                fit: BoxFit.cover,
                              ),
                      )
                    : Icon(biller.icon, color: biller.accentColor, size: 34),
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _controller,
              keyboardType: biller.inputLabel == 'PHONE'
                  ? TextInputType.phone
                  : TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              textDirection: TextDirection.ltr,
              style: AppTextStyles.monoLabel(color: colors.onSurface)
                  .copyWith(fontSize: 18, fontWeight: FontWeight.w600),
              onChanged: (_) {
                if (_error != null || _inquiry != null) {
                  setState(() {
                    _error = null;
                    _inquiry = null;
                  });
                }
              },
              decoration: uffInputDecoration(
                context,
                label: _inputLabel(l10n),
                placeholder: biller.inputLabel == 'PHONE' ? '7XXXXXXXX' : null,
                errorText: _error,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _loading ? null : _inquire,
              child: _loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: UffLoader(),
                    )
                  : Text(l10n.inquireBill),
            ),
            if (inquiry != null) ...[
              const SizedBox(height: 24),
              _InquiryCard(
                biller: biller,
                inquiry: inquiry,
                languageCode: languageCode,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _continue,
                child: Text(l10n.continueLabel),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InquiryCard extends StatelessWidget {
  const _InquiryCard({
    required this.biller,
    required this.inquiry,
    required this.languageCode,
  });

  final Biller biller;
  final BillInquiry inquiry;
  final String languageCode;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.bankColors;

    final rows = <(String, String)>[
      if (inquiry.subscriberName != null) (l10n.subscriberNameLabel, inquiry.subscriberName!),
      if (inquiry.formattedBalanceDue(biller.currency) != null)
        (l10n.balanceDueLabel, inquiry.formattedBalanceDue(biller.currency)!),
      if (inquiry.availableCredit != null) (l10n.availableCreditLabel, inquiry.availableCredit!),
      if (inquiry.lineType != null) (l10n.lineTypeLabel, inquiry.lineType!),
      if (inquiry.expiryDate != null) (l10n.expiresLabel, inquiry.expiryDate!),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppColors.radiusXl),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.billDetails,
            style: AppTextStyles.labelSm(
              color: colors.onSurfaceVariant,
              languageCode: languageCode,
            ).copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          if (rows.isEmpty && inquiry.message != null)
            Text(
              inquiry.message!,
              style: AppTextStyles.bodyMd(color: colors.onSurface, languageCode: languageCode),
            ),
          for (final (label, value) in rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    label,
                    style: AppTextStyles.labelSm(
                      color: colors.onSurfaceVariant,
                      languageCode: languageCode,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      value,
                      textAlign: TextAlign.end,
                      style: AppTextStyles.labelSm(
                        color: colors.onSurface,
                        languageCode: languageCode,
                      ).copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
