import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/app_localizations.dart';
import '../security/security_gate.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/bank_sync_colors.dart';

/// Full-screen PIN entry matching Stitch `pin_setup_light` layout.
///
/// PIN-authorised operations are exactly the sensitive ones (transfers,
/// linking accounts, PIN changes), so the device-posture gate lives here:
/// on a restricted device the user gets the explanation sheet and the caller
/// sees `null` — the same contract as a manual cancel.
Future<String?> showPinEntrySheet(
  BuildContext context, {
  required String title,
  String? subtitle,
  int minLength = 4,
  int maxLength = 6,
}) async {
  if (!await guardSensitiveOperation(context)) return null;
  if (!context.mounted) return null;
  return Navigator.of(context).push<String>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (ctx) => PinEntryScreen(
        title: title,
        subtitle: subtitle,
        minLength: minLength,
        maxLength: maxLength,
      ),
    ),
  );
}

/// Reusable PIN UI (Stitch pin_setup_light) for sheets and embedded flows.
class PinEntryView extends StatefulWidget {
  const PinEntryView({
    super.key,
    required this.title,
    this.subtitle,
    this.minLength = 4,
    this.maxLength = 6,
    required this.onCompleted,
    this.onCancel,
    this.showContinueButton = true,
    this.trailingActions,
  });

  final String title;
  final String? subtitle;
  final int minLength;
  final int maxLength;
  final ValueChanged<String> onCompleted;
  final VoidCallback? onCancel;
  final bool showContinueButton;
  final List<Widget>? trailingActions;

  @override
  State<PinEntryView> createState() => _PinEntryViewState();
}

class _PinEntryViewState extends State<PinEntryView> {
  String _digits = '';

  bool get _canContinue =>
      _digits.length >= widget.minLength && _digits.length <= widget.maxLength;

  void _onDigit(String digit) {
    if (_digits.length >= widget.maxLength) return;
    setState(() => _digits += digit);
    if (_digits.length >= widget.minLength) {
      HapticFeedback.lightImpact();
    }
    if (_digits.length == widget.maxLength) {
      widget.onCompleted(_digits);
    }
  }

  void _onBackspace() {
    if (_digits.isEmpty) return;
    setState(() => _digits = _digits.substring(0, _digits.length - 1));
  }

  void _submit() {
    if (!_canContinue) return;
    widget.onCompleted(_digits);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.bankColors;
    final languageCode = Localizations.localeOf(context).languageCode;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: Column(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: colors.secondary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.lock_outline_rounded,
                    size: 36,
                    color: colors.secondary,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  widget.title,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.headlineMd(
                    color: colors.onSurface,
                    languageCode: languageCode,
                  ),
                ),
                if (widget.subtitle != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    widget.subtitle!,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyMd(
                      color: colors.onSurfaceVariant,
                      languageCode: languageCode,
                    ),
                  ),
                ],
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: _PinSlotRow(
                    length: widget.maxLength,
                    filled: _digits.length,
                    colors: colors,
                  ),
                ),
                if (widget.showContinueButton) ...[
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _canContinue ? _submit : null,
                      child: Text(context.l10n.continueLabel),
                    ),
                  ),
                ],
                if (widget.onCancel != null) ...[
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: widget.onCancel,
                    child: Text(
                      MaterialLocalizations.of(context).cancelButtonLabel,
                      style: AppTextStyles.labelSm(color: colors.onSurfaceVariant),
                    ),
                  ),
                ],
                if (widget.trailingActions != null) ...[
                  const SizedBox(height: 12),
                  ...widget.trailingActions!,
                ],
              ],
            ),
          ),
        ),
        _StitchPinKeypad(
          onDigit: _onDigit,
          onBackspace: _onBackspace,
          colors: colors,
        ),
      ],
    );
  }
}

class PinEntryScreen extends StatelessWidget {
  const PinEntryScreen({
    super.key,
    required this.title,
    this.subtitle,
    this.minLength = 4,
    this.maxLength = 6,
  });

  final String title;
  final String? subtitle;
  final int minLength;
  final int maxLength;

  @override
  Widget build(BuildContext context) {
    final colors = context.bankColors;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: PinEntryView(
        title: title,
        subtitle: subtitle,
        minLength: minLength,
        maxLength: maxLength,
        onCompleted: (pin) => Navigator.of(context).pop(pin),
        onCancel: () => Navigator.of(context).pop(),
        showContinueButton: minLength < maxLength,
      ),
    );
  }
}

class _PinSlotRow extends StatelessWidget {
  const _PinSlotRow({
    required this.length,
    required this.filled,
    required this.colors,
  });

  final int length;
  final int filled;
  final BankSyncColors colors;

  static const double _maxSlotWidth = 44;
  static const double _slotGap = 8;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final available = constraints.maxWidth;
        final gaps = _slotGap * (length - 1);
        final slotWidth = ((available - gaps) / length)
            .clamp(32.0, _maxSlotWidth)
            .toDouble();
        final slotHeight = slotWidth * 1.18;

        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(length, (index) {
            final isFilled = index < filled;
            return Padding(
              padding: EdgeInsets.only(right: index < length - 1 ? _slotGap : 0),
              child: SizedBox(
                width: slotWidth,
                height: slotHeight,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: isFilled
                        ? colors.secondary
                        : colors.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(AppColors.radiusMd),
                    border: Border.all(
                      color: isFilled ? colors.secondary : colors.outlineVariant,
                      width: isFilled ? 0 : 1.5,
                    ),
                  ),
                  child: isFilled
                      ? Center(
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: colors.onSecondary,
                              shape: BoxShape.circle,
                            ),
                          ),
                        )
                      : null,
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

/// Stitch-style keypad: flat grid on elevated surface, no per-key borders.
class _StitchPinKeypad extends StatelessWidget {
  const _StitchPinKeypad({
    required this.onDigit,
    required this.onBackspace,
    required this.colors,
  });

  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;
  final BankSyncColors colors;

  @override
  Widget build(BuildContext context) {
    const rows = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['', '0', 'del'],
    ];

    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: colors.cardShadow,
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: EdgeInsets.only(
        left: 8,
        right: 8,
        top: 8,
        bottom: MediaQuery.paddingOf(context).bottom + 8,
      ),
      child: Column(
        children: rows.map((row) {
          return Row(
            children: row.map((key) {
              return Expanded(
                child: _KeypadCell(
                  keyLabel: key,
                  colors: colors,
                  onDigit: onDigit,
                  onBackspace: onBackspace,
                ),
              );
            }).toList(),
          );
        }).toList(),
      ),
    );
  }
}

class _KeypadCell extends StatelessWidget {
  const _KeypadCell({
    required this.keyLabel,
    required this.colors,
    required this.onDigit,
    required this.onBackspace,
  });

  final String keyLabel;
  final BankSyncColors colors;
  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;

  @override
  Widget build(BuildContext context) {
    if (keyLabel.isEmpty) {
      return const SizedBox(height: 64);
    }

    if (keyLabel == 'del') {
      return SizedBox(
        height: 64,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onBackspace,
            borderRadius: BorderRadius.circular(AppColors.radiusMd),
            child: Icon(
              Icons.backspace_outlined,
              color: colors.onSurface,
              size: 26,
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: 64,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onDigit(keyLabel),
          borderRadius: BorderRadius.circular(AppColors.radiusMd),
          child: Center(
            child: Text(
              keyLabel,
              style: AppTextStyles.headlineMd(color: colors.onSurface).copyWith(
                fontSize: 28,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
