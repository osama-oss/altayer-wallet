import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/models/banking_account.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/bank_sync_colors.dart';
import '../../../l10n/app_localizations.dart';

class AccountCarousel extends StatefulWidget {
  const AccountCarousel({
    super.key,
    required this.accounts,
    required this.onDetails,
    this.initialIndex = 0,
  });

  final List<BankingAccount> accounts;
  final ValueChanged<BankingAccount> onDetails;
  final int initialIndex;

  @override
  State<AccountCarousel> createState() => _AccountCarouselState();
}

class _AccountCarouselState extends State<AccountCarousel> {
  late final PageController _pageController;
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex.clamp(0, widget.accounts.isEmpty ? 0 : widget.accounts.length - 1);
    _pageController = PageController(viewportFraction: 0.88, initialPage: _index);
  }

  @override
  void didUpdateWidget(covariant AccountCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialIndex != widget.initialIndex && widget.accounts.isNotEmpty) {
      final next = widget.initialIndex.clamp(0, widget.accounts.length - 1);
      if (next != _index) {
        _index = next;
        _pageController.jumpToPage(_index);
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.accounts.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        SizedBox(
          height: 128,
          child: PageView.builder(
            controller: _pageController,
            itemCount: widget.accounts.length,
            onPageChanged: (i) => setState(() => _index = i),
            itemBuilder: (context, i) {
              final account = widget.accounts[i];
              final selected = i == _index;
              return AnimatedScale(
                scale: selected ? 1 : 0.96,
                duration: const Duration(milliseconds: 220),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: _BalanceCard(
                    account: account,
                    emphasized: selected,
                    onDetails: () => widget.onDetails(account),
                  ),
                ),
              );
            },
          ),
        ),
        if (widget.accounts.length > 1) ...[
          const SizedBox(height: 8),
          _PageIndicator(count: widget.accounts.length, index: _index),
        ],
      ],
    );
  }
}

class _PageIndicator extends StatelessWidget {
  const _PageIndicator({required this.count, required this.index});

  final int count;
  final int index;

  static const _maxDots = 12;

  @override
  Widget build(BuildContext context) {
    if (count > _maxDots) {
      final l10n = AppLocalizations.of(context);
      final colors = context.bankColors;
      return Text(
        l10n.accountsPageIndicator(index + 1, count),
        style: AppTextStyles.bodyMd(color: colors.onSurfaceVariant)
            .copyWith(fontWeight: FontWeight.w600),
      );
    }

    final colors = context.bankColors;

    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(count, (i) {
          final active = i == index;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: active ? 22 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: active ? colors.secondary : colors.outlineVariant,
              borderRadius: BorderRadius.circular(4),
            ),
          );
        }),
      ),
    );
  }
}

/// BankSync total-balance style card (swipeable per account).
class _BalanceCard extends StatelessWidget {
  const _BalanceCard({
    required this.account,
    required this.emphasized,
    required this.onDetails,
  });

  final BankingAccount account;
  final bool emphasized;
  final VoidCallback onDetails;

  static String _maskedTail(String accountNumber) {
    final digits = accountNumber.replaceAll(RegExp(r'\D'), '');
    if (digits.length >= 4) {
      return digits.substring(digits.length - 4);
    }
    if (accountNumber.length >= 4) {
      return accountNumber.substring(accountNumber.length - 4);
    }
    return accountNumber;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final languageCode = Localizations.localeOf(context).languageCode;
    final colors = context.bankColors;
    final formatted = NumberFormat('#,##0.00').format(account.balance);
    final label = account.label.toUpperCase();
    final tail = _maskedTail(account.accountNumber);

    final decoration = emphasized
        ? BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [colors.secondary, colors.secondaryContainer],
            ),
            borderRadius: BorderRadius.circular(AppColors.radiusMd),
          )
        : BoxDecoration(
            color: colors.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(AppColors.radiusMd),
            border: Border.all(color: colors.outlineVariant),
          );

    final titleColor = emphasized
        ? colors.onSecondary.withValues(alpha: 0.85)
        : colors.onSurfaceVariant;
    final balanceColor = emphasized ? colors.onSecondary : colors.primary;
    final monoColor = emphasized
        ? colors.onSecondary.withValues(alpha: 0.75)
        : colors.onSurfaceVariant;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppColors.radiusMd),
      child: Ink(
        decoration: decoration,
        child: InkWell(
          onTap: onDetails,
          borderRadius: BorderRadius.circular(AppColors.radiusMd),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.labelSm(color: titleColor, languageCode: languageCode).copyWith(
                    fontSize: 10,
                    letterSpacing: 1,
                    fontWeight: FontWeight.w600,
                    height: 1.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const Spacer(),
                Text(
                  '$formatted ${account.currency}',
                  style: AppTextStyles.balanceDisplay(color: balanceColor)
                      .copyWith(fontSize: 22, height: 1.05, letterSpacing: -0.5),
                ),
                const SizedBox(height: 2),
                Text(
                  '**** $tail',
                  style: AppTextStyles.monoLabel(color: monoColor)
                      .copyWith(fontSize: 11, height: 1.2),
                ),
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: onDetails,
                    style: TextButton.styleFrom(
                      foregroundColor: emphasized ? colors.onSecondary : colors.secondary,
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    child: Text(l10n.details),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
