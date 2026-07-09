import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/bank_sync_colors.dart';
import '../../../core/widgets/uff_ui.dart';
import '../../../l10n/app_localizations.dart';
import '../bill_payments_providers.dart';
import '../bill_review_screen.dart';
import '../data/bill_inquiry.dart';
import '../data/biller.dart';

/// UN Money send: recipient in → the shared review screen (amount + account +
/// PIN → BILL_PAY with the UNMONEY biller) — one payment path for everything.
class UnMoneySendScreen extends ConsumerStatefulWidget {
  const UnMoneySendScreen({super.key});

  @override
  ConsumerState<UnMoneySendScreen> createState() => _UnMoneySendScreenState();
}

class _UnMoneySendScreenState extends ConsumerState<UnMoneySendScreen> {
  final _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Biller? get _unMoney {
    final billers = ref.read(billerCatalogProvider).valueOrNull;
    if (billers == null) return null;
    for (final b in billers) {
      if (b.code == 'UNMONEY') return b;
    }
    return null;
  }

  void _continue() {
    final l10n = context.l10n;
    final biller = _unMoney;
    if (biller == null) return;
    final recipient = _controller.text.trim();
    if (!biller.matchesInput(recipient)) {
      setState(() => _error = l10n.invalidSubscriberNumber);
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BillReviewScreen(
          biller: biller,
          subscriberNo: recipient,
          inquiry: const BillInquiry(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.bankColors;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(title: Text(l10n.unMoneySend), centerTitle: true),
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
                  color: const Color(0xFF16B89B).withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.north_east_rounded,
                  color: Color(0xFF16B89B),
                  size: 32,
                ),
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _controller,
              keyboardType: TextInputType.phone,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              textDirection: TextDirection.ltr,
              style: AppTextStyles.monoLabel(color: colors.onSurface)
                  .copyWith(fontSize: 18, fontWeight: FontWeight.w600),
              onChanged: (_) {
                if (_error != null) setState(() => _error = null);
              },
              decoration: uffInputDecoration(
                context,
                label: l10n.unMoneyRecipientLabel,
                placeholder: '7XXXXXXXX',
                errorText: _error,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _continue,
              child: Text(l10n.continueLabel),
            ),
          ],
        ),
      ),
    );
  }
}
