import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

void showFeatureComingSoonDialog(BuildContext context) {
  final l10n = context.l10n;
  showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(l10n.featureComingSoonTitle),
      content: Text(l10n.featureComingSoonMessage),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: Text(MaterialLocalizations.of(context).okButtonLabel),
        ),
      ],
    ),
  );
}
