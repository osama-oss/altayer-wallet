import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/mobile_transaction.dart';
import '../../core/wallet_account_id.dart';
import '../../core/providers/app_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/bank_sync_colors.dart';
import '../../l10n/app_localizations.dart';
import '../bill_payments/bill_payments_providers.dart';
import '../bill_payments/data/biller.dart';
import '../../core/widgets/uff_loader.dart';

/// Bill payments hub — live `BILLER_CATALOG` categories, UN Money entry and
/// the customer's recent BILL_PAYMENT rows from the server-side log.
class UtilityPaymentsScreen extends ConsumerWidget {
  const UtilityPaymentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.bankColors;
    final lang = Localizations.localeOf(context).languageCode;
    final l10n = context.l10n;
    final catalog = ref.watch(billerCatalogProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.payBills,
            style: AppTextStyles.headlineMd(color: colors.onSurface, languageCode: lang)
                .copyWith(fontWeight: FontWeight.w700, fontSize: 22),
          ),
          const SizedBox(height: 18),
          _SearchField(
            hint: l10n.searchBillersHint,
            onTap: () => context.push('/bills/providers'),
          ),
          const SizedBox(height: 24),
          _SectionLabel(l10n.categories),
          const SizedBox(height: 14),
          catalog.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(child: UffLoader()),
            ),
            error: (e, _) => _CatalogError(message: e.toString()),
            data: (billers) => _CategoriesGrid(billers: billers),
          ),
          const SizedBox(height: 26),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _SectionLabel(l10n.paymentHistory),
              TextButton(
                onPressed: () => context.push('/bills/history'),
                child: Text(l10n.categoryViewAll),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const _RecentPayments(),
        ],
      ),
    );
  }
}

class _CategoriesGrid extends ConsumerWidget {
  const _CategoriesGrid({required this.billers});

  final List<Biller> billers;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final present = billers.map((b) => b.category).toSet();

    final categories = <_Category>[
      // الاتصالات: straight to the auto-detect سداد الاتصالات screen (no list).
      if (present.contains('TELECOM'))
        _Category(svgName: 'ic_telecom', label: l10n.categoryTelecom, route: '/bills/telecom'),
      // الإنترنت: the full non-mobile bill list (يمن فورجي، الهاتف الثابت، يمن
      // نت ADSL، عدن نت، ستارلينك) — same list as عرض الكل since the landline
      // is TELECOM-tagged but has no operator prefix, so a category filter
      // would wrongly exclude it.
      if (present.contains('INTERNET'))
        _Category(svgName: 'ic_internet', label: l10n.categoryInternet, route: '/bills/providers'),
      if (present.contains('ENTERTAINMENT'))
        _Category(
          svgName: 'ic_entertainment',
          label: l10n.categoryEntertainment,
          route: '/bills/providers?cat=ENTERTAINMENT',
        ),
      _Category(svgName: 'ic_grid_view', label: l10n.categoryViewAll, route: '/bills/providers'),
    ];

    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 16,
      crossAxisSpacing: 8,
      childAspectRatio: 0.78,
      children: [
        for (final c in categories)
          _CategoryTile(category: c, onTap: () => context.push(c.route)),
      ],
    );
  }
}

/// Recent BILL_PAYMENT rows (top 3) — refreshes when a payment lands.
class _RecentPayments extends ConsumerStatefulWidget {
  const _RecentPayments();

  @override
  ConsumerState<_RecentPayments> createState() => _RecentPaymentsState();
}

class _RecentPaymentsState extends ConsumerState<_RecentPayments> {
  List<MobileTransaction>? _payments;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final token = await ref.read(authServiceProvider).readToken();
      if (token == null || token.isEmpty) return;
      final rows = await ref.read(apiClientProvider).transactions(token);
      if (!mounted) return;
      setState(() {
        _payments = MobileTransaction.listFrom(rows)
            .where((t) => t.type.toUpperCase() == 'BILL_PAYMENT')
            .take(3)
            .toList();
      });
    } catch (_) {
      // The hub stays usable without the preview; the history screen
      // surfaces errors properly.
      if (mounted) setState(() => _payments = const []);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.bankColors;
    final lang = Localizations.localeOf(context).languageCode;
    ref.listen(billPaymentsRevisionProvider, (_, __) => _load());
    final payments = _payments;

    if (payments == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(child: UffLoader()),
      );
    }
    if (payments.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 26, horizontal: 16),
        decoration: BoxDecoration(
          color: colors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(AppColors.radiusXl),
          border: Border.all(color: colors.outlineVariant),
        ),
        child: Text(
          l10n.billPaymentHistoryEmpty,
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyMd(color: colors.onSurfaceVariant, languageCode: lang),
        ),
      );
    }
    return Column(
      children: [
        for (final tx in payments) ...[
          _HistoryItem(tx: tx, onTap: () => context.push('/bills/history')),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _Category {
  const _Category({required this.svgName, required this.label, required this.route});

  /// SVG asset name under assets/icons (without theme suffix).
  final String svgName;
  final String label;

  /// Router path opened when the tile is tapped.
  final String route;
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.hint, required this.onTap});
  final String hint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.bankColors;
    final suffix = Theme.of(context).brightness == Brightness.dark ? 'dark' : 'light';
    return Material(
      color: colors.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(AppColors.radiusLg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppColors.radiusLg),
        child: Container(
          height: 54,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppColors.radiusLg),
            border: Border.all(color: colors.outlineVariant),
          ),
          child: Row(
            children: [
              SvgPicture.asset(
                'assets/icons/ic_search_$suffix.svg',
                width: 20,
                height: 20,
                colorFilter: ColorFilter.mode(colors.outline, BlendMode.srcIn),
              ),
              const SizedBox(width: 12),
              Text(
                hint,
                style: AppTextStyles.bodyMd(color: colors.outline)
                    .copyWith(fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.bankColors;
    final lang = Localizations.localeOf(context).languageCode;
    return Text(
      label,
      style: AppTextStyles.labelSm(color: colors.onSurfaceVariant, languageCode: lang)
          .copyWith(fontWeight: FontWeight.w600),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({required this.category, required this.onTap});
  final _Category category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.bankColors;
    final lang = Localizations.localeOf(context).languageCode;
    final suffix = Theme.of(context).brightness == Brightness.dark ? 'dark' : 'light';
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: colors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(AppColors.radiusMd),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppColors.radiusMd),
            child: Container(
              width: 58,
              height: 58,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppColors.radiusMd),
                border: Border.all(color: colors.outlineVariant),
              ),
              child: SvgPicture.asset(
                'assets/icons/${category.svgName}_$suffix.svg',
                width: 24,
                height: 24,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          category.label,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.labelSm(color: colors.onSurface, languageCode: lang)
              .copyWith(fontSize: 11, fontWeight: FontWeight.w600, height: 1.2),
        ),
      ],
    );
  }
}

class _CatalogError extends ConsumerWidget {
  const _CatalogError({required this.message});
  final String message;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.bankColors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppColors.radiusXl),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 13),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => ref.invalidate(billerCatalogProvider),
            child: Text(context.l10n.continueLabel),
          ),
        ],
      ),
    );
  }
}

class _HistoryItem extends StatelessWidget {
  const _HistoryItem({required this.tx, required this.onTap});

  final MobileTransaction tx;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.bankColors;
    final lang = Localizations.localeOf(context).languageCode;
    final suffix = Theme.of(context).brightness == Brightness.dark ? 'dark' : 'light';
    final status = tx.status.toUpperCase();
    final (badgeBg, badgeFg, badgeLabel) = switch (status) {
      'COMPLETED' => (AppColors.successContainer, AppColors.onSuccessContainer, l10n.paidStatus),
      'PENDING' => (AppColors.warningContainer, AppColors.warning, l10n.statusPending),
      _ => (AppColors.errorContainer, AppColors.error, l10n.statusFailed),
    };

    return Material(
      color: colors.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(AppColors.radiusLg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppColors.radiusLg),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppColors.radiusLg),
            border: Border.all(color: colors.outlineVariant),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: colors.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: SvgPicture.asset(
                  'assets/icons/ic_receipt_$suffix.svg',
                  width: 20,
                  height: 20,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tx.billerCode ?? walletDisplayNumber(tx.creditAccount),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.labelSm(color: colors.onSurface, languageCode: lang)
                          .copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      tx.formattedDate(),
                      style: AppTextStyles.labelSm(
                        color: colors.onSurfaceVariant,
                        languageCode: lang,
                      ).copyWith(fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    tx.formattedAmount(),
                    textDirection: TextDirection.ltr,
                    style: AppTextStyles.monoLabel(color: colors.onSurface)
                        .copyWith(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 5),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: badgeBg,
                      borderRadius: BorderRadius.circular(AppColors.radiusPill),
                    ),
                    child: Text(
                      badgeLabel,
                      style: AppTextStyles.labelSm(color: badgeFg, languageCode: lang)
                          .copyWith(fontSize: 10, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
