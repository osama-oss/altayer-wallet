import 'package:flutter/material.dart';
import './uff_loader.dart';

class DbPrimaryButton extends StatelessWidget {
  const DbPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: loading ? null : onPressed,
      child: loading
          ? const SizedBox(
              height: 22,
              width: 22,
              child: UffLoader(size: 20, color: Colors.white),
            )
          : Text(label),
    );
  }
}
