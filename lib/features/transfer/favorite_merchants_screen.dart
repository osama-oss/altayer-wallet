import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_text_styles.dart';
import '../../core/theme/bank_sync_colors.dart';
import '../../l10n/app_localizations.dart';
import 'widgets/transfer_buttons.dart';

/// "التجار المفضلون" — the favourite-merchants interface.
///
/// The merchant-favourites list is served by the core (wired later, same as the
/// rest of the wallet). Until then this shows an honest empty state — no mock
/// rows — plus a direct "pay a merchant" action so the screen is already useful.
/// When the backend provides favourites, they render here and tap through to
/// [MerchantPaymentScreen] prefilled.
class FavoriteMerchantsScreen extends StatelessWidget {
  const FavoriteMerchantsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.bankColors;
    final lang = Localizations.localeOf(context).languageCode;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(title: Text(l10n.svcFavoriteMerchants), centerTitle: true),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: colors.secondary.withValues(alpha: 0.10),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.storefront_rounded,
                            size: 48, color: colors.secondary),
                      ),
                      const SizedBox(height: 22),
                      Text(
                        l10n.favoriteMerchantsEmptyTitle,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.headlineMd(
                          color: colors.onSurface,
                          languageCode: lang,
                        ).copyWith(fontSize: 18, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        l10n.favoriteMerchantsEmpty,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodyMd(
                          color: colors.onSurfaceVariant,
                          languageCode: lang,
                        ).copyWith(height: 1.5),
                      ),
                    ],
                  ),
                ),
              ),
              TransferPrimaryButton(
                label: l10n.svcPayMerchant,
                icon: Icons.arrow_forward_rounded,
                onPressed: () => context.push('/merchant-payment'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
