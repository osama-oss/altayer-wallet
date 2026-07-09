import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_error_message.dart';
import '../../core/network/api_exception.dart';
import '../../core/providers/app_providers.dart';
import '../../core/widgets/pin_entry_sheet.dart';
import '../../l10n/app_localizations.dart';
import 'widgets/transfer_confirm_sheet.dart';

typedef TransferSummaryBuilder = List<(String, String)> Function();

Future<void> confirmTransferWithPin({
  required BuildContext context,
  required WidgetRef ref,
  required Map<String, dynamic> payload,
  required String amount,
  required String currency,
  required TransferSummaryBuilder summaryRows,
  Map<String, dynamic>? validation,
  required void Function(Map<String, dynamic> result) onSuccess,
  required void Function(String message) onError,
  required VoidCallback onLoadingChanged,
}) async {
  final confirmed = await showTransferConfirmSheet(
    context,
    amount: amount,
    currency: currency,
    rows: summaryRows(),
    validation: validation,
  );
  if (!confirmed || !context.mounted) return;

  final pin = await showPinEntrySheet(
    context,
    title: context.l10n.authorizeTransfer,
    subtitle: context.l10n.enterPinToComplete,
  );
  if (pin == null || !context.mounted) return;

  onLoadingChanged();
  try {
    final token = await ref.read(authServiceProvider).readToken();
    if (token == null) return;
    final data = await ref.read(apiClientProvider).confirmTransfer(
          token,
          payload,
          pin,
        );
    // Balances changed — invalidate the shared accounts cache so home and
    // every accounts list refresh on their next frame.
    ref.read(accountsRevisionProvider.notifier).state++;
    if (!context.mounted) return;
    onSuccess(data);
  } on ApiException catch (e) {
    onError(e.message);
  } catch (e) {
    onError(formatThrowableMessage(e));
  }
}
