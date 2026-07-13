import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/favorite_transfer.dart';
import '../../core/network/api_error_message.dart';
import '../../core/network/api_exception.dart';
import '../../core/providers/app_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/wallet_account_id.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/bank_sync_colors.dart';
import '../../l10n/app_localizations.dart';
import 'widgets/transfer_error.dart';
import '../../core/widgets/uff_loader.dart';

/// Standalone list of the customer's server-side favorite transfer targets.
/// Reached from the Transfers services grid. Tapping a favorite opens the
/// "to others" transfer form prefilled with that account; the trailing action
/// removes it (with confirmation). Backed by the shared [favoritesProvider].
class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  Future<void> _confirmRemove(
      BuildContext context, WidgetRef ref, FavoriteTransfer favorite) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.removeFavorite),
        content: Text(
          favorite.displayName == favorite.targetAccountNumber
              ? walletDisplayNumber(favorite.targetAccountNumber)
              : '${walletDisplayNumber(favorite.displayName)}\n${walletDisplayNumber(favorite.targetAccountNumber)}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.removeFavorite),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref
          .read(favoritesProvider.notifier)
          .removeByAccount(favorite.targetAccountNumber);
    } on ApiException catch (e) {
      if (context.mounted) showTransferErrorNotice(context, e.message);
    } catch (e) {
      if (context.mounted) {
        showTransferErrorNotice(context, formatThrowableMessage(e));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final colors = context.bankColors;
    final favoritesAsync = ref.watch(favoritesProvider);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(title: Text(l10n.favoritesLabel), centerTitle: true),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => ref.refresh(favoritesProvider.future),
          child: favoritesAsync.when(
            loading: () => const Center(child: UffLoader()),
            error: (_, __) => _EmptyState(message: l10n.favoritesEmpty),
            data: (favorites) {
              if (favorites.isEmpty) {
                return _EmptyState(message: l10n.favoritesEmpty);
              }
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                itemCount: favorites.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) => _FavoriteRow(
                  favorite: favorites[index],
                  onTap: () => context.push(
                    '/transfer/others?to=${Uri.encodeComponent(favorites[index].targetAccountNumber)}',
                  ),
                  onRemove: () =>
                      _confirmRemove(context, ref, favorites[index]),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _FavoriteRow extends StatelessWidget {
  const _FavoriteRow({
    required this.favorite,
    required this.onTap,
    required this.onRemove,
  });

  final FavoriteTransfer favorite;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final colors = context.bankColors;
    final lang = Localizations.localeOf(context).languageCode;
    final suffix = Theme.of(context).brightness == Brightness.dark ? 'dark' : 'light';
    return Material(
      color: colors.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(AppColors.radiusLg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppColors.radiusLg),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppColors.radiusLg),
            border: Border.all(color: colors.outlineVariant),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: colors.secondary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: SvgPicture.asset('assets/icons/ic_favorite_star_$suffix.svg',
                    width: 22, height: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      walletDisplayNumber(favorite.displayName),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.labelSm(
                        color: colors.onSurface,
                        languageCode: lang,
                      ).copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      walletDisplayNumber(favorite.targetAccountNumber),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.labelSm(
                        color: colors.onSurfaceVariant,
                        languageCode: lang,
                      ).copyWith(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onRemove,
                tooltip: context.l10n.removeFavorite,
                icon: Icon(Icons.delete_outline_rounded,
                    size: 20, color: colors.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = context.bankColors;
    final lang = Localizations.localeOf(context).languageCode;
    // Kept scrollable so RefreshIndicator still works when the list is empty.
    return ListView(
      padding: const EdgeInsets.fromLTRB(32, 96, 32, 32),
      children: [
        Icon(Icons.star_border_rounded,
            size: 64, color: colors.outline),
        const SizedBox(height: 18),
        Text(
          message,
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyMd(
            color: colors.onSurfaceVariant,
            languageCode: lang,
          ).copyWith(height: 1.5),
        ),
      ],
    );
  }
}
