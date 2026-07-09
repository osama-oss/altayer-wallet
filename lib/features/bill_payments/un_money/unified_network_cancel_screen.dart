import 'package:flutter/material.dart';

import '../../../core/theme/bank_sync_colors.dart';
import '../../../core/widgets/uff_ui.dart';
import '../../../l10n/app_localizations.dart';

/// Front-only mockup of the Unified Network "cancel transfer" form — no
/// backend integration yet.
class UnifiedNetworkCancelScreen extends StatefulWidget {
  const UnifiedNetworkCancelScreen({super.key});

  @override
  State<UnifiedNetworkCancelScreen> createState() => _UnifiedNetworkCancelScreenState();
}

class _UnifiedNetworkCancelScreenState extends State<UnifiedNetworkCancelScreen> {
  final _reference = TextEditingController();

  @override
  void dispose() {
    _reference.dispose();
    super.dispose();
  }

  void _confirm() {
    final l10n = context.l10n;
    if (_reference.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.transferNumberHint),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.comingSoonToast), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.bankColors;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(title: Text(l10n.unifiedNetworkCancelTitle), centerTitle: true),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                child: UffField(
                  controller: _reference,
                  label: l10n.transferNumberHint,
                  prefixIcon: Icons.tag_rounded,
                  keyboardType: TextInputType.number,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 22),
              child: UffPrimaryButton(
                label: l10n.confirmLabel,
                trailingChevron: false,
                onPressed: _confirm,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
