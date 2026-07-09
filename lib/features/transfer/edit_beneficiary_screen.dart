import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/api_exception.dart';
import '../../core/providers/app_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/bank_sync_colors.dart';
import '../../core/widgets/uff_ui.dart';
import '../../l10n/app_localizations.dart';

/// Edit-beneficiary screen — pre-fills fields from the existing beneficiary map.
///
/// Business logic:
///   • Nickname-only edit  → calls `BENEFICIARY_UPDATE` directly.
///   • Account-number edit → first validates via `BEBEFICIARY_ACC_LOOKUP`,
///     then calls `BENEFICIARY_UPDATE` on success.
class EditBeneficiaryScreen extends ConsumerStatefulWidget {
  const EditBeneficiaryScreen({super.key, required this.beneficiary});

  /// The full beneficiary map as returned by `BENEFICIARY_LIST`.
  final Map<String, dynamic> beneficiary;

  @override
  ConsumerState<EditBeneficiaryScreen> createState() =>
      _EditBeneficiaryScreenState();
}

class _EditBeneficiaryScreenState extends ConsumerState<EditBeneficiaryScreen> {
  late final TextEditingController _accountCtrl;
  late final TextEditingController _nicknameCtrl;

  late final String _originalAccount;
  late final String _originalNickname;

  bool _isVerifying = false;
  bool _isSaving = false;
  bool _accountVerified = false;
  String? _error;

  // Populated after a successful account lookup when the account is changed.
  String _verifiedName = '';
  String? _verifiedCustomerId;
  String? _verifiedCurrency;

  // Original beneficiary fields carried through to the update payload.
  int get _beneficiaryId => widget.beneficiary['id'] as int? ?? 0;
  String get _nameAr => widget.beneficiary['nameAr']?.toString() ?? '';
  String get _bankNameAr => widget.beneficiary['bankNameAr']?.toString() ?? '';
  String get _currency => widget.beneficiary['currency']?.toString() ?? 'YER';
  String? get _iban => widget.beneficiary['iban']?.toString();
  String? get _customerId {
    final b = widget.beneficiary;
    for (final key in ['customer_id', 'customerId', 'cutomer', 'customer']) {
      final val = b[key]?.toString().trim();
      if (val != null && val.isNotEmpty) return val;
    }
    return null;
  }

  bool get _accountChanged => _accountCtrl.text.trim() != _originalAccount;
  bool get _nicknameChanged => _nicknameCtrl.text.trim() != _originalNickname;
  bool get _hasChanges => _accountChanged || _nicknameChanged;

  @override
  void initState() {
    super.initState();
    _originalAccount = widget.beneficiary['accountNumber']?.toString() ?? '';
    _originalNickname = widget.beneficiary['nickname']?.toString() ?? '';
    _accountCtrl = TextEditingController(text: _originalAccount);
    _nicknameCtrl = TextEditingController(text: _originalNickname);
  }

  @override
  void dispose() {
    _accountCtrl.dispose();
    _nicknameCtrl.dispose();
    super.dispose();
  }

  // ── Account validation (reused when account number changes) ─────────────

  Future<void> _verifyNewAccount() async {
    final value = _accountCtrl.text.trim();
    if (value.isEmpty) {
      setState(() => _error = context.l10n.validationEnterValue);
      return;
    }

    setState(() {
      _isVerifying = true;
      _error = null;
      _accountVerified = false;
    });

    try {
      final auth = ref.read(authServiceProvider);
      final token = await auth.readToken();
      if (token == null) throw const ApiException('Session expired');

      final result = await ref
          .read(apiClientProvider)
          .validateBeneficiaryAccount(token, value);

      final name = _findNameInValidation(result);
      final currency = _findCurrencyInValidation(result);
      var customerId = _findTargetCustomerIdInValidation(result);

      if (customerId == null || customerId.isEmpty) {
        // Fallback to first 9 characters of the account number if it's numeric and >= 9 chars
        final cleanVal = value.trim();
        if (RegExp(r'^\d+$').hasMatch(cleanVal) && cleanVal.length >= 9) {
          customerId = cleanVal.substring(0, 9);
        }
      }

      if (!mounted) return;
      setState(() {
        _verifiedName = name;
        _verifiedCurrency = currency;
        _verifiedCustomerId = customerId;
        _accountVerified = true;
        _isVerifying = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _isVerifying = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isVerifying = false;
      });
    }
  }

  // ── Save (update) ──────────────────────────────────────────────────────

  Future<void> _saveChanges() async {
    if (!_hasChanges) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.noChangesDetected)),
      );
      return;
    }

    setState(() {
      _isSaving = true;
      _error = null;
    });

    try {
      final auth = ref.read(authServiceProvider);
      final token = await auth.readToken();
      if (token == null) throw const ApiException('Session expired');

      // Resolve the customer_id:
      //  1. If account was changed and verified → use _verifiedCustomerId.
      //  2. If the beneficiary map already had it → use _customerId.
      //  3. Otherwise, look it up from the existing account number.
      String? resolvedCustomerId = _accountChanged && _verifiedCustomerId != null
          ? _verifiedCustomerId
          : _customerId;

      if (resolvedCustomerId == null || resolvedCustomerId.isEmpty) {
        // BENEFICIARY_LIST doesn't return customer_id — fetch it via lookup.
        final lookupResult = await ref
            .read(apiClientProvider)
            .validateBeneficiaryAccount(token, _accountCtrl.text.trim());
        resolvedCustomerId = _findTargetCustomerIdInValidation(lookupResult);
      }

      if (resolvedCustomerId == null || resolvedCustomerId.isEmpty) {
        // Fallback to first 9 characters of the account number if it's numeric and >= 9 chars
        final cleanVal = _accountCtrl.text.trim();
        if (RegExp(r'^\d+$').hasMatch(cleanVal) && cleanVal.length >= 9) {
          resolvedCustomerId = cleanVal.substring(0, 9);
        }
      }

      if (!mounted) return;

      // Build the update payload with all required fields.
      final body = <String, dynamic>{
        'beneficiaryId': _beneficiaryId,
        'account_number': _accountCtrl.text.trim(),
        'nameAr': _accountChanged && _verifiedName.isNotEmpty
            ? _verifiedName
            : _nameAr,
        if (resolvedCustomerId != null && resolvedCustomerId.isNotEmpty)
          'customer_id': resolvedCustomerId,
        if (_nicknameCtrl.text.trim().isNotEmpty)
          'nickname': _nicknameCtrl.text.trim(),
        if (_iban != null && _iban!.isNotEmpty) 'iban': _iban,
        if (_bankNameAr.isNotEmpty) 'bankNameAr': _bankNameAr,
        'currency': _accountChanged && _verifiedCurrency != null
            ? _verifiedCurrency
            : _currency,
      };

      await ref.read(apiClientProvider).updateBeneficiary(token, body);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(context.l10n.beneficiaryUpdatedSuccessfully)),
      );
      context.pop(true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _isSaving = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isSaving = false;
      });
    }
  }

  // ── Primary action (dynamic button) ────────────────────────────────────

  void _onPrimaryAction() {
    if (_accountChanged && !_accountVerified) {
      _verifyNewAccount();
    } else {
      _saveChanges();
    }
  }

  String get _primaryLabel {
    final l10n = context.l10n;
    if (_accountChanged && !_accountVerified) return l10n.verifyNewAccount;
    return l10n.saveChanges;
  }

  IconData? get _primaryIcon {
    if (_accountChanged && !_accountVerified) {
      return Icons.verified_user_outlined;
    }
    return null;
  }

  // ── Validation helpers ─────────────────────────────────────────────────
  // FIXME(shared-validation): These helpers are duplicated from
  // AddBeneficiaryScreen. Extract into a shared mixin or utility class
  // (e.g. `BeneficiaryValidationMixin` or `beneficiary_helpers.dart`) to
  // respect DRY when the beneficiary module grows further.

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

  String _getInitials(String name) {
    if (name.isEmpty) return 'B';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  // ── Build ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.bankColors;
    final languageCode = Localizations.localeOf(context).languageCode;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        centerTitle: true,
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.editBeneficiary),
            Text(
              l10n.editBeneficiarySubtitle,
              style: AppTextStyles.labelSm(color: colors.onSurfaceVariant)
                  .copyWith(fontSize: 11, fontWeight: FontWeight.w500),
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
                    // ── Beneficiary info card ──
                    _buildInfoCard(colors, languageCode),
                    const SizedBox(height: 24),

                    // ── Account number field ──
                    UffField(
                      controller: _accountCtrl,
                      label: l10n.beneficiaryAccountOrIban,
                      placeholder: l10n.hintEnterAccount,
                      prefixIcon: Icons.account_balance_outlined,
                      textDirection: TextDirection.ltr,
                      onChanged: (_) {
                        if (_accountVerified || _error != null) {
                          setState(() {
                            _accountVerified = false;
                            _error = null;
                          });
                        } else {
                          setState(() {}); // refresh button label
                        }
                      },
                    ),

                    // ── Verified card (shown after account lookup success) ──
                    if (_accountChanged && _accountVerified) ...[
                      const SizedBox(height: 16),
                      _buildVerifiedCard(colors, l10n),
                    ],

                    const SizedBox(height: 20),

                    // ── Nickname field ──
                    UffField(
                      controller: _nicknameCtrl,
                      label: l10n.nicknameOptional,
                      placeholder: l10n.nicknameExample,
                      prefixIcon: Icons.sell_outlined,
                      onChanged: (_) => setState(() {}),
                    ),

                    // ── Error banner ──
                    if (_error != null) ...[
                      const SizedBox(height: 16),
                      _ErrorBanner(message: _error!),
                    ],
                  ],
                ),
              ),
            ),

            // ── Primary action button ──
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 22),
              child: UffPrimaryButton(
                label: _primaryLabel,
                icon: _primaryIcon,
                trailingChevron: !(_accountChanged && !_accountVerified),
                loading: _isVerifying || _isSaving,
                onPressed: _onPrimaryAction,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Beneficiary info card ──────────────────────────────────────────────

  Widget _buildInfoCard(BankSyncColors colors, String languageCode) {
    final displayName =
        _originalNickname.isNotEmpty ? _originalNickname : _nameAr;
    final subtitle =
        (_originalNickname.isNotEmpty && _nameAr.isNotEmpty) ? _nameAr : null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLowest,
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
              _getInitials(displayName),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
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
                  displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyMd(
                          color: colors.onSurface, languageCode: languageCode)
                      .copyWith(fontWeight: FontWeight.w800),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.labelSm(
                      color: colors.onSurfaceVariant,
                      languageCode: languageCode,
                    ),
                  ),
                ],
                if (_bankNameAr.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    _bankNameAr,
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              color: colors.secondary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppColors.radiusSm),
            ),
            child: Text(
              _currency,
              style: AppTextStyles.labelSm(color: colors.secondary)
                  .copyWith(fontSize: 12, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }

  // ── Verified new-account card (after lookup) ───────────────────────────

  Widget _buildVerifiedCard(BankSyncColors colors, AppLocalizations l10n) {
    return Container(
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
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
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
                      .copyWith(fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: AppColors.brandGradient,
                    borderRadius:
                        BorderRadius.circular(AppColors.radiusLg),
                  ),
                  child: Text(
                    _getInitials(
                        _verifiedName.isNotEmpty ? _verifiedName : '؟'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
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
                        l10n.accountHolder,
                        style: AppTextStyles.labelSm(
                                color: colors.onSurfaceVariant)
                            .copyWith(
                                fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _verifiedName.isNotEmpty
                            ? _verifiedName
                            : l10n.accountHolder,
                        style:
                            AppTextStyles.bodyMd(color: colors.onSurface)
                                .copyWith(fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Private error banner (reused from add_beneficiary_screen) ────────────

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
