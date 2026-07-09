import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/bank_sync_colors.dart';
import '../../l10n/app_localizations.dart';
import 'bill_payments_providers.dart';
import 'bill_inquiry_screen.dart';
import 'data/biller.dart';
import '../../core/widgets/uff_loader.dart';

/// Providers of one category (or all), with instant client-side search.
/// Money-transfer entries route to the UN Money hub instead of the bill flow.
class BillerListScreen extends ConsumerStatefulWidget {
  const BillerListScreen({super.key, this.category});

  final String? category;

  @override
  ConsumerState<BillerListScreen> createState() => _BillerListScreenState();
}

class _BillerListScreenState extends ConsumerState<BillerListScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.bankColors;
    final languageCode = Localizations.localeOf(context).languageCode;
    final catalog = ref.watch(billerCatalogProvider);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(title: Text(l10n.serviceProviders), centerTitle: true),
      body: catalog.when(
        loading: () => const Center(child: UffLoader()),
        error: (e, _) => _ErrorRetry(message: e.toString()),
        data: (billers) {
          final filtered = billers.where((b) {
            if (widget.category != null && b.category != widget.category) return false;
            // Mobile operators are handled by the auto-detect سداد الاتصالات
            // page, and money transfers by the network-transfers hub — neither
            // belongs in the دفع الفواتير list.
            if (b.prefixes.isNotEmpty) return false;
            if (b.category == 'MONEY_TRANSFER') return false;
            if (_query.isEmpty) return true;
            final q = _query.toLowerCase();
            return b.localizedName(languageCode).toLowerCase().contains(q) ||
                b.nameEn.toLowerCase().contains(q) ||
                b.nameAr.contains(_query);
          }).toList();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
                child: TextField(
                  onChanged: (v) => setState(() => _query = v.trim()),
                  decoration: InputDecoration(
                    hintText: l10n.searchBillersHint,
                    prefixIcon: Icon(Icons.search_rounded, color: colors.outline),
                    filled: true,
                    fillColor: colors.surfaceContainerLowest,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppColors.radiusLg),
                      borderSide: BorderSide(color: colors.outlineVariant),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppColors.radiusLg),
                      borderSide: BorderSide(color: colors.outlineVariant),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Text(
                          l10n.noProvidersFound,
                          style: AppTextStyles.bodyMd(color: colors.onSurfaceVariant),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) => _BillerTile(
                          biller: filtered[index],
                          languageCode: languageCode,
                          onTap: () => _open(filtered[index]),
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _open(Biller biller) {
    if (biller.category == 'MONEY_TRANSFER') {
      context.push('/unmoney');
      return;
    }
    if (biller.code == 'YEMEN-4G') {
      context.push('/bills/yemen4g');
      return;
    }
    if (biller.code == 'ADENNET') {
      context.push('/bills/adennet');
      return;
    }
    if (biller.code == 'STARLINK') {
      context.push('/bills/starlink');
      return;
    }
    if (biller.code == Biller.internetBillerCode) {
      context.push('/bills/internet');
      return;
    }
    if (biller.code == Biller.landlineBillerCode) {
      context.push('/bills/landline');
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => BillInquiryScreen(biller: biller)),
    );
  }
}

class _BillerTile extends StatelessWidget {
  const _BillerTile({
    required this.biller,
    required this.languageCode,
    required this.onTap,
  });

  final Biller biller;
  final String languageCode;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.bankColors;
    final themeAsset = biller.getThemeAssetIcon(context);
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
                  color: biller.accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: themeAsset != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: themeAsset.endsWith('.svg')
                            ? SvgPicture.asset(
                                themeAsset,
                                width: 36,
                                height: 36,
                                fit: BoxFit.contain,
                              )
                            : Image.asset(
                                themeAsset,
                                width: 36,
                                height: 36,
                                fit: BoxFit.contain,
                              ),
                      )
                    : Icon(biller.icon, color: biller.accentColor, size: 22),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Text(
                  biller.localizedName(languageCode),
                  style: AppTextStyles.labelSm(
                    color: colors.onSurface,
                    languageCode: languageCode,
                  ).copyWith(fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
              Icon(
                Directionality.of(context) == TextDirection.rtl
                    ? Icons.chevron_left_rounded
                    : Icons.chevron_right_rounded,
                color: colors.outline,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorRetry extends ConsumerWidget {
  const _ErrorRetry({required this.message});

  final String message;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => ref.invalidate(billerCatalogProvider),
              child: Text(context.l10n.continueLabel),
            ),
          ],
        ),
      ),
    );
  }
}
