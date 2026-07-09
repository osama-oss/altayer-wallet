import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/api_exception.dart';
import '../../core/profile_helpers.dart';
import '../../core/providers/app_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/bank_sync_colors.dart';
import '../../core/widgets/uff_ui.dart';
import '../../l10n/app_localizations.dart';

enum _BeneficiaryMethod { account, mobile, iban }

/// Add-beneficiary flow rebuilt to the UBS identity:
///   Step 1 — choose method (account / mobile / IBAN), enter the value, verify.
///   Step 2 — review the verified owner returned by the core, add a nickname,
///            then save.
class AddBeneficiaryScreen extends ConsumerStatefulWidget {
  const AddBeneficiaryScreen({super.key});

  @override
  ConsumerState<AddBeneficiaryScreen> createState() =>
      _AddBeneficiaryScreenState();
}

class _AddBeneficiaryScreenState extends ConsumerState<AddBeneficiaryScreen> {
  final _accountController = TextEditingController();
  final _nicknameController = TextEditingController();

  _BeneficiaryMethod _method = _BeneficiaryMethod.account;
  String _currency = 'YER';

  bool _isValidating = false;
  bool _isValidated = false;
  bool _isSaving = false;
  String? _validationError;
  String _ownerName = '';
  String? _targetCustomerId;

  bool get _ar => Localizations.localeOf(context).languageCode == 'ar';

  @override
  void dispose() {
    _accountController.dispose();
    _nicknameController.dispose();
    super.dispose();
  }

  String _methodLabel(_BeneficiaryMethod m) {
    final l10n = context.l10n;
    switch (m) {
      case _BeneficiaryMethod.account:
        return l10n.methodAccount;
      case _BeneficiaryMethod.mobile:
        return l10n.methodMobile;
      case _BeneficiaryMethod.iban:
        return l10n.methodIban;
    }
  }

  String get _fieldHint {
    final l10n = context.l10n;
    switch (_method) {
      case _BeneficiaryMethod.account:
        return l10n.hintEnterAccount;
      case _BeneficiaryMethod.mobile:
        return l10n.hintEnterMobile;
      case _BeneficiaryMethod.iban:
        return l10n.hintEnterIban;
    }
  }

  IconData get _fieldIcon {
    switch (_method) {
      case _BeneficiaryMethod.account:
        return Icons.account_balance_outlined;
      case _BeneficiaryMethod.mobile:
        return Icons.smartphone_outlined;
      case _BeneficiaryMethod.iban:
        return Icons.credit_card_outlined;
    }
  }

  void _selectMethod(_BeneficiaryMethod m) {
    setState(() {
      _method = m;
      _isValidated = false;
      _ownerName = '';
      _validationError = null;
    });
  }

  Future<void> _validateAccount() async {
    final value = _accountController.text.trim();
    if (value.isEmpty) {
      setState(() => _validationError =
          context.l10n.validationEnterValue);
      return;
    }

    setState(() {
      _isValidating = true;
      _validationError = null;
      _isValidated = false;
      _ownerName = '';
    });

    try {
      final auth = ref.read(authServiceProvider);
      final token = await auth.readToken();
      if (token == null) throw const ApiException('Session expired');

      final result = await ref
          .read(apiClientProvider)
          .validateBeneficiaryAccount(token, value);
      final name = _findNameInValidation(result);
      final fetchedCurrency = _findCurrencyInValidation(result);
      var fetchedCustomerId = _findTargetCustomerIdInValidation(result);

      if (fetchedCustomerId == null || fetchedCustomerId.isEmpty) {
        // Fallback to first 9 characters of the account number if it's numeric and >= 9 chars
        final cleanVal = value.trim();
        if (RegExp(r'^\d+$').hasMatch(cleanVal) && cleanVal.length >= 9) {
          fetchedCustomerId = cleanVal.substring(0, 9);
        }
      }

      if (!mounted) return;
      setState(() {
        _ownerName = name;
        if (fetchedCurrency != null && fetchedCurrency.isNotEmpty) {
          _currency = fetchedCurrency;
        }
        if (fetchedCustomerId != null && fetchedCustomerId.isNotEmpty) {
          _targetCustomerId = fetchedCustomerId;
        }
        _isValidated = true;
        _isValidating = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _validationError = e.message;
        _isValidating = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _validationError = e.toString();
        _isValidating = false;
      });
    }
  }

  String? _findCurrencyInValidation(Map<String, dynamic> validation) {
    final data = validation['data'] ?? validation;
    if (data is Map) {
      for (final key in [
        'currency',
        'ccy',
        'currencyCode',
        'currency_code',
        'cur',
      ]) {
        if (data.containsKey(key) && data[key] != null) {
          final val = data[key].toString().trim().toUpperCase();
          if (val.isNotEmpty) return val;
        }
      }
      for (final entry in data.entries) {
        if (entry.value is Map) {
          final nested = _findCurrencyInValidation(
              Map<String, dynamic>.from(entry.value as Map));
          if (nested != null && nested.isNotEmpty) return nested;
        }
      }
    }
    return null;
  }

  String? _findTargetCustomerIdInValidation(Map<String, dynamic> validation) {
    final data = validation['data'] ?? validation;
    if (data is Map) {
      for (final key in [
        'cutomer',
        'customer',
        'customer_id',
        'customerId',
        'coreCustomerId',
        'customerCode',
        'customerNo',
        'customerNumber',
        'customer_no',
        'customer_number',
        'custNo',
        'cust_no',
        'customerid'
      ]) {
        if (data.containsKey(key) && data[key] != null) {
          final val = data[key].toString().trim();
          if (val.isNotEmpty) return val;
        }
      }
      for (final entry in data.entries) {
        if (entry.value is Map) {
          final nested = _findTargetCustomerIdInValidation(
              Map<String, dynamic>.from(entry.value as Map));
          if (nested != null && nested.isNotEmpty) return nested;
        }
      }
    }
    return null;
  }

  String _findNameInValidation(Map<String, dynamic> validation) {
    final data = validation['data'] ?? validation;
    if (data is Map) {
      for (final key in [
        'creditCustomerName',
        'customerName',
        'fullName',
        'full_name',
        'nameAr',
        'name',
        'accountName',
        'beneficiaryName',
        'credit_customer_name',
        'customer_name',
      ]) {
        if (data.containsKey(key) && data[key] != null) {
          final val = _extractName(data[key]);
          if (val != null && val.isNotEmpty) return val;
        }
      }
      for (final entry in data.entries) {
        if (entry.value is Map) {
          final nested = _findNameInValidation(
              Map<String, dynamic>.from(entry.value as Map));
          if (nested.isNotEmpty) return nested;
        }
      }
    }
    return '';
  }

  /// The core returns customer names as bilingual objects
  /// (`{"ar": "...", "en": "..."}`), never as a flat string. Saved as
  /// `nameAr`, so Arabic wins when both are present; English is the fallback
  /// for accounts that only carry a Latin name.
  String? _extractName(dynamic value) {
    if (value is Map) {
      final map = Map<String, dynamic>.from(value);
      final ar = map['ar']?.toString().trim();
      if (ar != null && ar.isNotEmpty) return ar;
      final en = map['en']?.toString().trim();
      if (en != null && en.isNotEmpty) return en;
      for (final nestedValue in map.values) {
        final extracted = _extractName(nestedValue);
        if (extracted != null && extracted.isNotEmpty) return extracted;
      }
      return null;
    }
    final str = value?.toString().trim();
    return (str != null && str.isNotEmpty) ? str : null;
  }

  Future<void> _saveBeneficiary() async {
    setState(() => _isSaving = true);
    try {
      final auth = ref.read(authServiceProvider);
      final token = await auth.readToken();
      if (token == null) throw const ApiException('Session expired');

      // belongingCustomer = the signed-in user's core customer ID.
      final profile =
          await ref.read(apiClientProvider).userDetail(token);
      final belongingCustomer = coreCustomerIdFromProfile(
        profile,
        usernameFallback: await auth.readUsername(),
      );

      final value = _accountController.text.trim();
      final body = {
        'account_number': value,
        'nameAr': _ownerName.isNotEmpty ? _ownerName : value,
        if (_nicknameController.text.trim().isNotEmpty)
          'nickname': _nicknameController.text.trim(),
        if (_method == _BeneficiaryMethod.iban) 'iban': value,
        'currency': _currency,
        // customer_id = the beneficiary's customer key from validation.
        if (_targetCustomerId != null && _targetCustomerId!.isNotEmpty)
          'customer_id': _targetCustomerId,
        if (belongingCustomer.isNotEmpty)
          'belongingCustomer': belongingCustomer,
      };

      await ref.read(apiClientProvider).addBeneficiary(token, body);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.beneficiaryAddedSuccessfully)),
      );
      context.pop(true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _validationError = e.message;
        _isSaving = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _validationError = e.toString();
        _isSaving = false;
      });
    }
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}';
    return parts.first.characters.first;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.bankColors;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        centerTitle: true,
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.addBeneficiary),
            Text(
              l10n.localTransferSubtitle,
              style: AppTextStyles.labelSm(color: colors.onSurfaceVariant)
                  .copyWith(fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    UffStepIndicator(current: _isValidated ? 1 : 0),
                    const SizedBox(height: 24),
                    if (!_isValidated)
                      _buildStepOne(colors, l10n)
                    else
                      _buildStepTwo(colors, l10n),
                    if (_validationError != null) ...[
                      const SizedBox(height: 16),
                      _ErrorBanner(message: _validationError!),
                    ],
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 22),
              child: _isValidated
                  ? UffPrimaryButton(
                      label: l10n.addBeneficiary,
                      loading: _isSaving,
                      onPressed: _saveBeneficiary,
                    )
                  : UffPrimaryButton(
                      label: l10n.verifyAccount,
                      icon: Icons.verified_user_outlined,
                      trailingChevron: false,
                      loading: _isValidating,
                      onPressed: _validateAccount,
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Step 1: method + value ─────────────────────────────────────────────
  Widget _buildStepOne(BankSyncColors colors, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.addBeneficiaryBy,
          style: AppTextStyles.labelSm(color: AppColors.inkMuted)
              .copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            UffMethodChip(
              icon: Icons.account_balance_outlined,
              label: _methodLabel(_BeneficiaryMethod.account),
              selected: _method == _BeneficiaryMethod.account,
              onTap: () => _selectMethod(_BeneficiaryMethod.account),
            ),
            const SizedBox(width: 12),
            UffMethodChip(
              icon: Icons.smartphone_outlined,
              label: _methodLabel(_BeneficiaryMethod.mobile),
              selected: _method == _BeneficiaryMethod.mobile,
              onTap: () => _selectMethod(_BeneficiaryMethod.mobile),
            ),
            const SizedBox(width: 12),
            UffMethodChip(
              icon: Icons.credit_card_outlined,
              label: _methodLabel(_BeneficiaryMethod.iban),
              selected: _method == _BeneficiaryMethod.iban,
              onTap: () => _selectMethod(_BeneficiaryMethod.iban),
            ),
          ],
        ),
        const SizedBox(height: 26),
        UffField(
          controller: _accountController,
          label: _methodLabel(_method),
          placeholder: _fieldHint,
          prefixIcon: _fieldIcon,
          textDirection: TextDirection.ltr,
          keyboardType: _method == _BeneficiaryMethod.mobile
              ? TextInputType.phone
              : TextInputType.text,
          inputFormatters: _method == _BeneficiaryMethod.mobile
              ? [FilteringTextInputFormatter.allow(RegExp(r'[0-9+]'))]
              : null,
          onChanged: (_) {
            if (_isValidated || _validationError != null) {
              setState(() {
                _isValidated = false;
                _validationError = null;
              });
            }
          },
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Icon(Icons.shield_outlined,
                size: 16, color: colors.onSurfaceVariant),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                l10n.verifiedSecurelyNote,
                style: AppTextStyles.labelSm(color: colors.onSurfaceVariant)
                    .copyWith(fontSize: 12.5, height: 1.5),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Step 2: verified owner + nickname ──────────────────────────────────
  Widget _buildStepTwo(BankSyncColors colors, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // collapsed value row
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: colors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(AppColors.radiusMd),
            border: Border.all(color: colors.outlineVariant),
          ),
          child: Row(
            children: [
              Icon(_fieldIcon, size: 18, color: colors.onSurfaceVariant),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _accountController.text.trim(),
                  textDirection: TextDirection.ltr,
                  textAlign: _ar ? TextAlign.right : TextAlign.left,
                  style: AppTextStyles.bodyMd(color: colors.onSurface)
                      .copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              GestureDetector(
                onTap: () => setState(() {
                  _isValidated = false;
                  _ownerName = '';
                }),
                child: Text(
                  l10n.change,
                  style: AppTextStyles.labelSm(color: colors.secondary)
                      .copyWith(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // verified owner card
        Container(
          decoration: BoxDecoration(
            color: colors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(AppColors.radiusXl),
            border: Border.all(color: AppColors.brandIndigoBorder),
            boxShadow: [
              BoxShadow(
                color: colors.cardShadow,
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
                decoration: const BoxDecoration(
                  color: AppColors.successContainer,
                  borderRadius: BorderRadius.vertical(
                      top: Radius.circular(AppColors.radiusXl)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.verified_rounded,
                        size: 18, color: AppColors.success),
                    const SizedBox(width: 9),
                    Text(
                      l10n.accountVerified,
                      style: AppTextStyles.labelSm(
                              color: AppColors.onSuccessContainer)
                          .copyWith(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        gradient: AppColors.brandGradient,
                        borderRadius: BorderRadius.circular(AppColors.radiusLg),
                      ),
                      child: Text(
                        _initials(_ownerName.isNotEmpty ? _ownerName : '؟'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.accountHolder,
                            style: AppTextStyles.labelSm(
                                    color: colors.onSurfaceVariant)
                                .copyWith(
                                    fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            _ownerName.isNotEmpty
                                ? _ownerName
                                : l10n.accountHolder,
                            style: AppTextStyles.bodyMd(color: colors.onSurface)
                                .copyWith(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        UffField(
          controller: _nicknameController,
          label: l10n.nicknameOptional,
          placeholder: l10n.nicknameExample,
          prefixIcon: Icons.sell_outlined,
        ),
        const SizedBox(height: 18),
        // compact currency selector
        Row(
          children: [
            Text(
              l10n.currencyLabel,
              style: AppTextStyles.labelSm(color: AppColors.inkMuted)
                  .copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(width: 12),
            for (final c in const ['YER', 'SAR', 'USD']) ...[
              _CurrencyPill(
                code: c,
                selected: _currency == c,
                onTap: () => setState(() => _currency = c),
              ),
              const SizedBox(width: 8),
            ],
          ],
        ),
      ],
    );
  }
}

class _CurrencyPill extends StatelessWidget {
  const _CurrencyPill(
      {required this.code, required this.selected, required this.onTap});

  final String code;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.bankColors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected
              ? colors.secondary.withValues(alpha: 0.12)
              : colors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(AppColors.radiusPill),
          border: Border.all(
            color: selected ? colors.secondary : colors.outlineVariant,
          ),
        ),
        child: Text(
          code,
          style: AppTextStyles.labelSm(
            color: selected ? colors.secondary : colors.onSurfaceVariant,
          ).copyWith(fontSize: 12, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppColors.errorContainer,
        borderRadius: BorderRadius.circular(AppColors.radiusMd),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: AppColors.error, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.labelSm(color: AppColors.error)
                  .copyWith(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
