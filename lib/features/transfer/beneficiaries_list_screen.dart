import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/api_exception.dart';
import '../../core/providers/app_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/bank_sync_colors.dart';
import '../../core/wallet_account_id.dart';
import '../../l10n/app_localizations.dart';
import '../../core/widgets/uff_loader.dart';

class BeneficiariesListScreen extends ConsumerStatefulWidget {
  const BeneficiariesListScreen({super.key});

  @override
  ConsumerState<BeneficiariesListScreen> createState() => _BeneficiariesListScreenState();
}

class _BeneficiariesListScreenState extends ConsumerState<BeneficiariesListScreen> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _beneficiaries = [];

  @override
  void initState() {
    super.initState();
    _loadBeneficiaries();
  }

  Future<void> _loadBeneficiaries() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final auth = ref.read(authServiceProvider);
      final token = await auth.readToken();
      if (token == null) {
        throw const ApiException('Session expired. Please sign in again.');
      }

      final payload = await ref.read(apiClientProvider).getBeneficiaries(token);
      final list = payload['beneficiaries'] as List<dynamic>? ?? [];

      if (!mounted) return;
      setState(() {
        _beneficiaries = list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _deleteBeneficiary(int id) async {
    try {
      final auth = ref.read(authServiceProvider);
      final token = await auth.readToken();
      if (token == null) return;

      await ref.read(apiClientProvider).deleteBeneficiary(token, id);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.beneficiaryDeleted)),
      );
      _loadBeneficiaries();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<bool> _confirmDelete() async {
    final l10n = context.l10n;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final colors = context.bankColors;
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.surfaceContainerLowest,
        title: Text(l10n.deleteBeneficiary),
        content: Text(l10n.confirmDeleteBeneficiary),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(isArabic ? 'إلغاء' : 'Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.deleteBeneficiary),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  String _getInitials(String name) {
    if (name.isEmpty) return 'B';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final languageCode = Localizations.localeOf(context).languageCode;
    final colors = context.bankColors;
    final isArabic = languageCode == 'ar';

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(title: Text(l10n.beneficiaries), centerTitle: true),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final added = await context.push<bool>('/beneficiaries/add');
          if (added == true) _loadBeneficiaries();
        },
        label: Text(
          l10n.addBeneficiary,
          style: AppTextStyles.labelSm(color: colors.onSecondary, languageCode: languageCode)
              .copyWith(fontWeight: FontWeight.w600),
        ),
        icon: const Icon(Icons.person_add_alt_1_rounded),
        backgroundColor: colors.secondary,
        foregroundColor: colors.onSecondary,
      ),
      body: _buildBody(colors, l10n, languageCode, isArabic),
    );
  }

  Widget _buildBody(
    BankSyncColors colors,
    AppLocalizations l10n,
    String languageCode,
    bool isArabic,
  ) {
    if (_loading) {
      return const Center(child: UffLoader());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.error),
              const SizedBox(height: 16),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMd(color: colors.onSurface),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadBeneficiaries,
                icon: const Icon(Icons.refresh_rounded),
                label: Text(isArabic ? 'إعادة المحاولة' : 'Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_beneficiaries.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 96,
                height: 96,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: colors.secondary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.people_alt_outlined, size: 44, color: colors.secondary),
              ),
              const SizedBox(height: 20),
              Text(
                isArabic ? 'لم تقم بإضافة مستفيدين بعد' : "You haven't added any beneficiaries yet",
                textAlign: TextAlign.center,
                style: AppTextStyles.headlineMd(languageCode: languageCode)
                    .copyWith(color: colors.onSurface, fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                isArabic
                    ? 'اضغط على الزر بالأسفل لتبدأ بإضافة مستفيد'
                    : 'Tap the button below to add a beneficiary',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMd(color: colors.onSurfaceVariant, languageCode: languageCode)
                    .copyWith(fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadBeneficiaries,
      color: colors.secondary,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        itemCount: _beneficiaries.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final b = _beneficiaries[index];
          final id = b['id'] as int? ?? 0;
          final name = b['nameAr']?.toString() ?? '';
          final accountNum = b['accountNumber']?.toString() ?? '';
          final nickname = b['nickname']?.toString() ?? '';
          final bankName = b['bankNameAr']?.toString() ?? '';
          final currency = b['currency']?.toString() ?? 'YER';

          return Dismissible(
            key: Key(id.toString()),
            direction: DismissDirection.endToStart,
            background: Container(
              alignment: isArabic ? Alignment.centerLeft : Alignment.centerRight,
              padding: const EdgeInsets.symmetric(horizontal: 22),
              decoration: BoxDecoration(
                color: AppColors.error,
                borderRadius: BorderRadius.circular(AppColors.radiusLg),
              ),
              child: const Icon(Icons.delete_rounded, color: Colors.white),
            ),
            confirmDismiss: (_) => _confirmDelete(),
            onDismissed: (_) => _deleteBeneficiary(id),
            child: _BeneficiaryCard(
              colors: colors,
              languageCode: languageCode,
              initials: _getInitials(nickname.isNotEmpty ? nickname : name),
              title: nickname.isNotEmpty ? nickname : name,
              subtitle: (nickname.isNotEmpty && name.isNotEmpty) ? name : null,
              accountNum: accountNum,
              bankName: bankName,
              currency: currency,
              onTap: () {
                // Return the account number to the caller (e.g. transfer screen).
                context.pop(accountNum);
              },
              onEdit: () async {
                final updated = await context.push<bool>(
                  '/beneficiaries/edit',
                  extra: b,
                );
                if (updated == true) _loadBeneficiaries();
              },
              onDelete: () async {
                if (await _confirmDelete()) _deleteBeneficiary(id);
              },
            ),
          );
        },
      ),
    );
  }
}

class _BeneficiaryCard extends StatelessWidget {
  const _BeneficiaryCard({
    required this.colors,
    required this.languageCode,
    required this.initials,
    required this.title,
    required this.subtitle,
    required this.accountNum,
    required this.bankName,
    required this.currency,
    required this.onEdit,
    required this.onTap,
    required this.onDelete,
  });

  final BankSyncColors colors;
  final String languageCode;
  final String initials;
  final String title;
  final String? subtitle;
  final String accountNum;
  final String bankName;
  final String currency;
  final VoidCallback onEdit;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: colors.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(AppColors.radiusLg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppColors.radiusLg),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppColors.radiusLg),
            border: Border.all(color: colors.outlineVariant),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: AppColors.brandGradient,
                  borderRadius: BorderRadius.circular(AppColors.radiusMd),
                ),
                child: Text(
                  initials,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodyMd(color: colors.onSurface, languageCode: languageCode)
                          .copyWith(fontWeight: FontWeight.w600),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.labelSm(
                          color: colors.onSurfaceVariant,
                          languageCode: languageCode,
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Text(
                      walletDisplayNumber(accountNum),
                      textDirection: TextDirection.ltr,
                      textAlign: languageCode == 'ar' ? TextAlign.right : TextAlign.left,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.monoLabel(color: colors.onSurfaceVariant)
                          .copyWith(fontSize: 13),
                    ),
                    if (bankName.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        bankName,
                        style: AppTextStyles.labelSm(
                          color: colors.onSurfaceVariant,
                          languageCode: languageCode,
                        ).copyWith(fontSize: 11),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: colors.secondary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppColors.radiusSm),
                    ),
                    child: Text(
                      currency,
                      style: AppTextStyles.labelSm(color: colors.secondary)
                          .copyWith(fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: onEdit,
                        child: Icon(
                          Icons.edit_outlined,
                          color: colors.secondary.withValues(alpha: 0.85),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: onDelete,
                        child: Icon(
                          Icons.delete_outline_rounded,
                          color: AppColors.error.withValues(alpha: 0.85),
                          size: 20,
                        ),
                      ),
                    ],
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
