import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/bank_sync_colors.dart';
import './uff_loader.dart';

/// Shared UI kit for the UBS / uff identity redesign.
///
/// Electric-indigo (#2119F3) on a clean, light surface system — extracted from
/// the design in `Des/UBS Banking.html`. Every widget here is theme-aware so it
/// also works under the dark palette.

/// Directional chevron that points toward the reading-direction end
/// (right in LTR, left in RTL) — used on primary CTAs.
IconData uffForwardChevron(BuildContext context) =>
    Directionality.of(context) == TextDirection.rtl
        ? Icons.arrow_back_ios_new_rounded
        : Icons.arrow_forward_ios_rounded;

/// Tall indigo primary call-to-action with an optional trailing chevron.
class UffPrimaryButton extends StatelessWidget {
  const UffPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.trailingChevron = true,
    this.loading = false,
    this.enabled = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool trailingChevron;
  final bool loading;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final colors = context.bankColors;
    final languageCode = Localizations.localeOf(context).languageCode;
    final isActive = enabled && !loading && onPressed != null;

    return Opacity(
      opacity: isActive ? 1 : 0.6,
      child: Material(
        color: colors.secondary,
        borderRadius: BorderRadius.circular(AppColors.radiusMd),
        child: InkWell(
          onTap: isActive ? onPressed : null,
          borderRadius: BorderRadius.circular(AppColors.radiusMd),
          child: Container(
            height: 58,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppColors.radiusMd),
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: colors.secondary.withValues(alpha: 0.35),
                        blurRadius: 24,
                        offset: const Offset(0, 12),
                      ),
                    ]
                  : null,
            ),
            child: loading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: UffLoader(size: 20, color: Colors.white),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (icon != null) ...[
                        Icon(icon, color: colors.onSecondary, size: 20),
                        const SizedBox(width: 10),
                      ],
                      Text(
                        label,
                        style: AppTextStyles.labelSm(
                          color: colors.onSecondary,
                          languageCode: languageCode,
                        ).copyWith(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                      if (trailingChevron) ...[
                        const SizedBox(width: 10),
                        Icon(uffForwardChevron(context), color: colors.onSecondary, size: 16),
                      ],
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

/// Two-step progress indicator (1 → 2) with a check on completed steps.
class UffStepIndicator extends StatelessWidget {
  const UffStepIndicator({super.key, required this.current, this.total = 2});

  /// Zero-based index of the active step.
  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    final colors = context.bankColors;
    final children = <Widget>[];
    for (var i = 0; i < total; i++) {
      final done = i < current;
      final active = i == current;
      children.add(_dot(colors, i + 1, done: done, active: active));
      if (i < total - 1) {
        children.add(Expanded(
          child: Container(
            height: 3,
            margin: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: i < current ? colors.secondary : colors.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ));
      }
    }
    return Row(children: children);
  }

  Widget _dot(BankSyncColors colors, int n, {required bool done, required bool active}) {
    final Color bg;
    if (done) {
      bg = AppColors.success;
    } else if (active) {
      bg = colors.secondary;
    } else {
      bg = colors.surfaceContainerHigh;
    }
    return Container(
      width: 26,
      height: 26,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
      child: done
          ? const Icon(Icons.check_rounded, size: 15, color: Colors.white)
          : Text(
              '$n',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: active ? Colors.white : colors.onSurfaceVariant,
              ),
            ),
    );
  }
}

/// Selectable method chip (e.g. IBAN / Mobile / Account) used on the
/// add-beneficiary method selector.
class UffMethodChip extends StatelessWidget {
  const UffMethodChip({
    super.key,
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.bankColors;
    final languageCode = Localizations.localeOf(context).languageCode;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 6),
          decoration: BoxDecoration(
            color: selected ? colors.secondary.withValues(alpha: 0.12) : colors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(AppColors.radiusLg),
            border: Border.all(
              color: selected ? colors.secondary : colors.outlineVariant,
              width: selected ? 1.5 : 1,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: colors.secondary.withValues(alpha: 0.08),
                      blurRadius: 0,
                      spreadRadius: 4,
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 26, color: selected ? colors.secondary : colors.onSurfaceVariant),
              const SizedBox(height: 10),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.labelSm(
                  color: selected ? colors.secondary : AppColors.inkMuted,
                  languageCode: languageCode,
                ).copyWith(fontSize: 12.5, fontWeight: selected ? FontWeight.w700 : FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A square service tile used in the transfer hub grid (round icon + label).
class UffServiceTile extends StatelessWidget {
  const UffServiceTile({
    super.key,
    this.icon,
    this.svgName,
    required this.label,
    required this.onTap,
    this.iconColor,
    this.iconBg,
  });

  final IconData? icon;
  final String? svgName;
  final String label;
  final VoidCallback onTap;
  final Color? iconColor;
  final Color? iconBg;

  @override
  Widget build(BuildContext context) {
    final colors = context.bankColors;
    final languageCode = Localizations.localeOf(context).languageCode;
    final suffix = Theme.of(context).brightness == Brightness.dark ? 'dark' : 'light';

    return Material(
      color: colors.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(AppColors.radiusXl),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppColors.radiusXl),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppColors.radiusXl),
            border: Border.all(color: colors.outlineVariant),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 48,
                width: double.infinity,
                child: Center(
                  child: svgName != null
                      ? SvgPicture.asset(
                          'assets/icons/${svgName}_$suffix.svg',
                          width: 38,
                          height: 38,
                          fit: BoxFit.contain,
                        )
                      : Icon(icon ?? Icons.help_outline_rounded, size: 34, color: iconColor ?? colors.secondary),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.labelSm(
                  color: AppColors.inkMuted,
                  languageCode: languageCode,
                ).copyWith(fontSize: 11.5, fontWeight: FontWeight.w700, height: 1.25),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Large hero action card (e.g. "New beneficiary" / "Transfer").
class UffHeroAction extends StatelessWidget {
  const UffHeroAction({
    super.key,
    this.icon,
    this.svgName,
    required this.label,
    required this.onTap,
    this.filled = false,
  });

  final IconData? icon;
  final String? svgName;
  final String label;
  final VoidCallback onTap;

  /// When true, paints the indigo gradient variant (primary action).
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final colors = context.bankColors;
    final languageCode = Localizations.localeOf(context).languageCode;
    final suffix = Theme.of(context).brightness == Brightness.dark ? 'dark' : 'light';
    return Expanded(
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppColors.radiusLg),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppColors.radiusLg),
          child: Container(
            height: 96,
            padding: const EdgeInsets.symmetric(horizontal: 6),
            decoration: BoxDecoration(
              color: filled ? colors.secondary : colors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(AppColors.radiusLg),
              border: filled ? null : Border.all(color: colors.outlineVariant),
              boxShadow: filled
                  ? [
                      BoxShadow(
                        color: colors.secondary.withValues(alpha: 0.12),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (svgName != null)
                  SvgPicture.asset(
                    'assets/icons/${svgName}_$suffix.svg',
                    width: 26,
                    height: 26,
                    colorFilter: ColorFilter.mode(filled ? Colors.white : colors.secondary, BlendMode.srcIn),
                  )
                else
                  Icon(
                    icon ?? Icons.help_outline_rounded,
                    size: 26,
                    color: filled ? Colors.white : colors.secondary,
                  ),
                const SizedBox(height: 10),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.labelSm(
                    color: filled ? Colors.white : colors.onSurface,
                    languageCode: languageCode,
                  ).copyWith(fontSize: 12.5, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Builds the shared **outlined floating-label** [InputDecoration] used across
/// the whole app (matches the reference design): the [label] sits inside the
/// border while the field is empty and rises above the border on focus / when
/// filled, tinted with the focus color. Use this on bespoke `TextFormField`s
/// (with validators) so they match [UffField] without duplicating styling.
///
/// Pass [fillColor] to preserve a screen's existing surface color; otherwise it
/// defaults to the theme surface. [placeholder] is an optional format example
/// shown once the label has floated up (e.g. `7XXXXXXXX`).
///
/// Set [reserveErrorSpace] to `true` on validated fields (especially two fields
/// sharing a [Row]) to permanently reserve a single-line slot below the field
/// for the validator message. The field keeps a constant height whether or not
/// an error is shown, so a `مطلوب` under one field never shifts its neighbour or
/// the rows beneath it. A transparent single-space helper occupies the slot when
/// there is no error; the error text then swaps into the *same* slot with no
/// layout jump. [errorMaxLines] caps the message height (defaults to a single
/// line when [reserveErrorSpace] is on) so a long message can't re-introduce the
/// jump.
InputDecoration uffInputDecoration(
  BuildContext context, {
  String? label,
  String? placeholder,
  Widget? prefixIcon,
  Widget? suffixIcon,
  String? suffixText,
  Color? fillColor,
  String? errorText,
  bool reserveErrorSpace = false,
  int? errorMaxLines,
  BoxConstraints? prefixIconConstraints,
  BoxConstraints? suffixIconConstraints,
}) {
  final colors = context.bankColors;
  OutlineInputBorder outline(Color color, [double width = 1.3]) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppColors.radiusField),
        borderSide: BorderSide(color: color, width: width),
      );
  // Error / helper share the same sub-text row below the field. Keeping their
  // font metrics identical guarantees the reserved slot is exactly as tall as a
  // shown error, so swapping between them never changes the field height.
  final subTextStyle = AppTextStyles.labelSm(color: colors.error)
      .copyWith(fontSize: 12, height: 1.15, fontWeight: FontWeight.w600);
  return InputDecoration(
    labelText: label,
    hintText: placeholder,
    suffixText: suffixText,
    errorText: errorText,
    // Reserved constant-height error slot (opt-in) — see doc comment above.
    helperText: reserveErrorSpace ? ' ' : null,
    helperMaxLines: 1,
    helperStyle: reserveErrorSpace
        ? subTextStyle.copyWith(color: Colors.transparent)
        : null,
    errorMaxLines: errorMaxLines ?? (reserveErrorSpace ? 1 : null),
    errorStyle: reserveErrorSpace ? subTextStyle : null,
    floatingLabelBehavior: FloatingLabelBehavior.auto,
    // Resting label (inside the border while empty): quiet placeholder look.
    labelStyle: AppTextStyles.bodyMd(color: colors.onSurfaceVariant)
        .copyWith(fontWeight: FontWeight.w500, fontSize: 16),
    // Floating label (risen above the border): bold and highly legible, like
    // the reference design — dark ink normally, brand ink while focused.
    floatingLabelStyle: WidgetStateTextStyle.resolveWith((states) {
      final Color ink;
      if (states.contains(WidgetState.error)) {
        ink = colors.error;
      } else if (states.contains(WidgetState.focused)) {
        ink = colors.secondary;
      } else {
        ink = colors.onSurface;
      }
      return AppTextStyles.labelSm(color: ink).copyWith(
        fontSize: 14.5,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.2,
        height: 1,
      );
    }),
    prefixIcon: prefixIcon,
    prefixIconConstraints: prefixIconConstraints,
    suffixIcon: suffixIcon,
    suffixIconConstraints: suffixIconConstraints,
    filled: true,
    fillColor: fillColor ?? colors.surfaceContainerLowest,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
    border: outline(colors.outlineVariant),
    enabledBorder: outline(colors.outlineVariant),
    focusedBorder: outline(colors.secondary, 2),
    errorBorder: outline(colors.error),
    focusedErrorBorder: outline(colors.error, 2),
  );
}

/// Styled, identity-consistent text field used across the redesign.
class UffField extends StatelessWidget {
  const UffField({
    super.key,
    required this.controller,
    this.hint,
    this.label,
    this.placeholder,
    this.prefixIcon,
    this.suffix,
    this.keyboardType,
    this.enabled = true,
    this.onChanged,
    this.textDirection,
    this.autofocus = false,
    this.inputFormatters,
  });

  final TextEditingController controller;

  /// The field name. Rendered as a Material floating label: it sits inside the
  /// border while the field is empty and rises above the border on focus / when
  /// filled. Kept named `hint` for backward compatibility with existing callers.
  final String? hint;

  /// Explicit floating label. Takes precedence over [hint] when both are given
  /// (use this when you also want a separate format [placeholder]).
  final String? label;

  /// Optional placeholder shown inside the field once the label has floated up
  /// (e.g. a format example like `7XXXXXXXX`). Hidden while the resting label
  /// occupies the field.
  final String? placeholder;

  final IconData? prefixIcon;
  final Widget? suffix;
  final TextInputType? keyboardType;
  final bool enabled;
  final ValueChanged<String>? onChanged;
  final TextDirection? textDirection;
  final bool autofocus;
  final List<TextInputFormatter>? inputFormatters;

  @override
  Widget build(BuildContext context) {
    final colors = context.bankColors;
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      enabled: enabled,
      onChanged: onChanged,
      textDirection: textDirection,
      autofocus: autofocus,
      inputFormatters: inputFormatters,
      style: AppTextStyles.bodyMd(color: colors.onSurface)
          .copyWith(fontWeight: FontWeight.w600, fontSize: 16),
      decoration: uffInputDecoration(
        context,
        label: label ?? hint,
        placeholder: placeholder,
        prefixIcon: prefixIcon != null
            ? Icon(prefixIcon, color: colors.outline, size: 20)
            : null,
        suffixIcon: suffix,
      ),
    );
  }
}

/// Styled dropdown field matching [UffField]'s look (filled surface, rounded
/// border, indigo focus ring) — used wherever a form needs a closed set of
/// choices (account type, currency, ...) instead of free text.
class UffDropdownField<T> extends StatelessWidget {
  const UffDropdownField({
    super.key,
    required this.value,
    required this.items,
    required this.labelBuilder,
    required this.onChanged,
    this.prefixIcon,
  });

  final T value;
  final List<T> items;
  final String Function(T) labelBuilder;
  final ValueChanged<T> onChanged;
  final IconData? prefixIcon;

  @override
  Widget build(BuildContext context) {
    final colors = context.bankColors;
    return DropdownButtonFormField<T>(
      initialValue: value,
      isExpanded: true,
      icon: Icon(Icons.keyboard_arrow_down_rounded, color: colors.outline),
      dropdownColor: colors.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(AppColors.radiusField),
      style: AppTextStyles.bodyMd(color: colors.onSurface).copyWith(fontWeight: FontWeight.w600),
      decoration: uffInputDecoration(
        context,
        prefixIcon: prefixIcon != null
            ? Icon(prefixIcon, color: colors.outline, size: 20)
            : null,
      ),
      items: [
        for (final item in items)
          DropdownMenuItem(value: item, child: Text(labelBuilder(item))),
      ],
      onChanged: (selected) {
        if (selected != null) onChanged(selected);
      },
    );
  }
}

/// Section label with a trailing hairline (e.g. "Services ─────").
class UffSectionLabel extends StatelessWidget {
  const UffSectionLabel({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.bankColors;
    final languageCode = Localizations.localeOf(context).languageCode;
    return Row(
      children: [
        Text(
          label,
          style: AppTextStyles.labelSm(
            color: colors.onSurface,
            languageCode: languageCode,
          ).copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(width: 12),
        Expanded(child: Container(height: 1, color: colors.surfaceContainerHighest)),
      ],
    );
  }
}
