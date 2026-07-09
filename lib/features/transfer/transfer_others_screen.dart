import 'package:flutter/material.dart';

import '../../core/theme/bank_sync_colors.dart';
import '../../l10n/app_localizations.dart';
import 'transfer_to_others_panel.dart';

/// Standalone page hosting the "to another customer / beneficiary" transfer
/// form. Reached from the transfer chooser ([TransferScreen]), from a
/// favorite, or when re-running a recent transfer (prefilled beneficiary).
class TransferOthersScreen extends StatelessWidget {
  const TransferOthersScreen({super.key, this.initialBeneficiary});

  /// Pre-fills the beneficiary account on the panel.
  final String? initialBeneficiary;

  @override
  Widget build(BuildContext context) {
    final colors = context.bankColors;
    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: Text(context.l10n.transferToOthers),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          child: TransferToOthersPanel(initialBeneficiary: initialBeneficiary),
        ),
      ),
    );
  }
}
