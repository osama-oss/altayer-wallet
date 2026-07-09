import 'package:flutter/material.dart';

import '../../core/theme/bank_sync_colors.dart';
import '../../l10n/app_localizations.dart';
import 'transfer_to_own_accounts_panel.dart';

/// Standalone page hosting the "between my accounts" transfer form.
/// Reached from the transfer chooser ([TransferScreen]).
class TransferOwnAccountsScreen extends StatelessWidget {
  const TransferOwnAccountsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.bankColors;
    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: Text(context.l10n.transferToMyAccounts),
        centerTitle: true,
      ),
      body: const SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 32),
          child: TransferToOwnAccountsPanel(),
        ),
      ),
    );
  }
}
