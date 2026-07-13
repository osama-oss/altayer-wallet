import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Shown when an owner in simulation mode taps a gated service tile.
Future<void> showOnboardingGateDialog(BuildContext context) async {
  final choice = await showCupertinoDialog<String>(
    context: context,
    builder: (ctx) => CupertinoAlertDialog(
      title: const Text('Finish registration'),
      content: const Text(
        'Complete merchant registration to use real banking services. You can continue browsing or finish now.',
      ),
      actions: [
        CupertinoDialogAction(
          onPressed: () => Navigator.of(ctx).pop('later'),
          child: const Text('Later'),
        ),
        CupertinoDialogAction(
          isDefaultAction: true,
          onPressed: () => Navigator.of(ctx).pop('now'),
          child: const Text('Now'),
        ),
      ],
    ),
  );
  if (!context.mounted) return;
  if (choice == 'now') {
    context.push('/pos/onboarding');
  }
}
