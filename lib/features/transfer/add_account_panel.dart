import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_error_message.dart';
import '../../core/network/api_exception.dart';
import '../../core/profile_helpers.dart';
import '../../core/providers/app_providers.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/bank_sync_colors.dart';
import '../../core/widgets/pin_entry_sheet.dart';
import '../../core/widgets/uff_ui.dart';
import '../../l10n/app_localizations.dart';
import 'widgets/transfer_error.dart';

/// Open an additional account for an existing customer.
///
/// Thin client: the customer inputs a ledger code and selects a currency.
/// The customer ID is retrieved automatically from their profile.
/// Validation (ACCOUNT_VALIDATE) runs first to fetch the generated account details,
/// and then the opening (ACCOUNT_OPEN_CURRENT) is triggered using the generated ID.
class AddAccountPanel extends ConsumerStatefulWidget {
  const AddAccountPanel({super.key});

  @override
  ConsumerState<AddAccountPanel> createState() => _AddAccountPanelState();
}

const _kCurrencies = ['YER', 'USD', 'SAR'];

class _AddAccountPanelState extends ConsumerState<AddAccountPanel> {
  bool _saving = false; // false = current (1001), true = saving (1000)
  String _currency = 'YER';
  String _customerId = '';
  bool _loadingCustomer = true;
  bool _loading = false;
  bool _success = false;
  Map<String, dynamic>? _result;

  bool get _isAr => Localizations.localeOf(context).languageCode == 'ar';

  @override
  void initState() {
    super.initState();
    _loadCustomerProfile();
  }

  Future<void> _loadCustomerProfile() async {
    try {
      final auth = ref.read(authServiceProvider);
      final token = await auth.readToken();
      if (token == null) {
        if (mounted) setState(() => _loadingCustomer = false);
        return;
      }
      final usernameFallback = await auth.readUsername();
      // Customer id never changes mid-session — try the locally cached
      // profile first (set at login/home) before a fresh network round-trip.
      var profile = await auth.readProfile();
      var customer = profile == null
          ? ''
          : coreCustomerIdFromProfile(profile, usernameFallback: usernameFallback);
      if (customer.isEmpty) {
        profile = await ref.read(apiClientProvider).userDetail(token);
        await auth.saveProfile(profile);
        customer = coreCustomerIdFromProfile(profile, usernameFallback: usernameFallback);
      }
      if (mounted) {
        setState(() {
          _customerId = customer;
          _loadingCustomer = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingCustomer = false);
      }
    }
  }

  /// Failures — the shared transfer error dialog (renders multi-line core
  /// messages as bullets), matching the rest of the transfer feature.
  void _error(String message) {
    if (!mounted) return;
    showTransferErrorNotice(context, message);
  }

  String? _extractIdFromValidation(Map<String, dynamic>? validation) {
    if (validation == null) return null;
    final data = validation['data'];
    final root = data is Map ? Map<String, dynamic>.from(data) : validation;
    
    // Look for ID, id, accountNumber, etc.
    String? pick(Map map) {
      for (final k in const ['ID', 'id', 'accountNumber', 'limitReference']) {
        final v = map[k];
        if (v != null && '$v'.trim().isNotEmpty) return '$v'.trim();
      }
      return null;
    }

    final direct = pick(root);
    if (direct != null) return direct;
    
    final response = root['response'] ?? root['resposn'];
    if (response is Map) return pick(response);
    
    return null;
  }

  Future<void> _openAccount() async {
    if (_customerId.isEmpty) {
      _error(_isAr ? 'لم يتم العثور على رقم العميل' : 'Customer ID not found');
      return;
    }

    // 1) Validate with the core — returns the account details to preview.
    setState(() => _loading = true);
    Map<String, dynamic> validation;
    try {
      final token = await ref.read(authServiceProvider).readToken();
      if (token == null) {
        if (mounted) setState(() => _loading = false);
        return;
      }
      validation = await ref.read(apiClientProvider).validateAccountOpen(
            token,
            currency: _currency,
            customer: _customerId,
            saving: _saving,
          );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      _error(e.message);
      return;
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      _error(formatThrowableMessage(e));
      return;
    }
    if (!mounted) return;
    setState(() => _loading = false);

    // 2) Confirm preview sheet.
    final confirmed = await _showConfirmSheet(validation);
    if (confirmed != true || !mounted) return;

    // 3) Transaction PIN.
    final pin = await showPinEntrySheet(
      context,
      title: _isAr ? 'تأكيد فتح الحساب' : 'Confirm account opening',
      subtitle: context.l10n.enterPinToComplete,
    );
    if (pin == null || !mounted) return;

    // 4) Open — saved + auto-authorized server-side (no pending state).
    setState(() => _loading = true);
    try {
      final token = await ref.read(authServiceProvider).readToken();
      if (token == null) {
        if (mounted) setState(() => _loading = false);
        return;
      }
      
      final validatedId = _extractIdFromValidation(validation);
      
      final result = await ref.read(apiClientProvider).openAccount(
            token,
            currency: _currency,
            customer: _customerId,
            pin: pin,
            saving: _saving,
            id: validatedId,
          );
      if (!mounted) return;
      // New account exists server-side now — nudge the cached account screens
      // (home carousel, All-accounts) to re-fetch so it shows immediately.
      ref.read(accountsRevisionProvider.notifier).state++;
      setState(() {
        _result = result;
        _success = true;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      _error(e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      _error(formatThrowableMessage(e));
    }
  }

  /// Friendly account-type name from the validate response (falls back to the
  /// selected ledger value).
  String _accountTypeName(Map<String, dynamic>? v) {
    final data = v?['data'];
    final t = data is Map ? data['accountType'] : null;
    if (t is Map) {
      final name = (_isAr ? t['ar'] : t['en']) ?? t['en'] ?? t['ar'];
      if (name != null && '$name'.trim().isNotEmpty) return '$name';
    }
    return _isAr
        ? (_saving ? 'حساب توفير' : 'حساب جاري')
        : (_saving ? 'Savings account' : 'Current account');
  }

  Future<bool?> _showConfirmSheet(Map<String, dynamic> validation) {
    final colors = context.bankColors;
    final lang = Localizations.localeOf(context).languageCode;
    return showModalBottomSheet<bool>(
      context: context,
      backgroundColor: colors.surfaceContainerLowest,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
              20, 14, 20, 20 + MediaQuery.of(ctx).viewInsets.bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colors.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                _isAr ? 'تأكيد فتح الحساب' : 'Confirm account opening',
                style: AppTextStyles.headlineMd(color: colors.onSurface, languageCode: lang)
                    .copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),
              _confirmRow(_isAr ? 'رقم العميل' : 'Customer ID', _customerId),
              _confirmRow(_isAr ? 'نوع الحساب' : 'Account type', _accountTypeName(validation)),
              _confirmRow(_isAr ? 'العملة' : 'Currency', _currency),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colors.accentGreen.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.bolt_rounded, size: 16, color: colors.accentGreen),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _isAr
                            ? 'سيُفتح الحساب ويُفعّل فوراً.'
                            : 'The account opens and activates instantly.',
                        style: AppTextStyles.labelSm(
                            color: colors.onSurfaceVariant, languageCode: lang),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              UffPrimaryButton(
                label: _isAr ? 'تأكيد ومتابعة' : 'Confirm & continue',
                loading: false,
                trailingChevron: false,
                onPressed: () => Navigator.of(ctx).pop(true),
                icon: Icons.arrow_forward_rounded,
              ),
              const SizedBox(height: 6),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: Text(
                  _isAr ? 'إلغاء' : 'Cancel',
                  style: AppTextStyles.bodyMd(
                      color: colors.onSurfaceVariant, languageCode: lang),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _confirmRow(String label, String value) {
    final colors = context.bankColors;
    final lang = Localizations.localeOf(context).languageCode;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: AppTextStyles.bodyMd(
                  color: colors.onSurfaceVariant, languageCode: lang)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: AppTextStyles.bodyMd(color: colors.onSurface, languageCode: lang)
                  .copyWith(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  void _reset() {
    setState(() {
      _success = false;
      _result = null;
    });
  }

  /// Best-effort extraction of the new account number from the gateway result.
  String? _newAccountNumber(Map<String, dynamic>? r) {
    if (r == null) return null;
    final data = r['data'];
    final root = data is Map ? Map<String, dynamic>.from(data) : r;
    
    final accountLike = RegExp(r'^\d{6,}$');
    String? pick(Map map) {
      for (final k in const ['accountNumber', 'ID', 'id', 'limitReference']) {
        final v = map[k];
        if (v == null) continue;
        final s = '$v'.trim();
        if (accountLike.hasMatch(s)) return s;
      }
      return null;
    }

    final direct = pick(root);
    if (direct != null) return direct;
    
    final resp = root['response'] ?? root['resposn'];
    if (resp is Map) return pick(resp);
    
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (_success) {
      return _SuccessView(accountNumber: _newAccountNumber(_result), onDone: _reset);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        _sectionLabel(_isAr ? 'نوع الحساب' : 'Account type'),
        const SizedBox(height: 10),
        UffDropdownField<bool>(
          value: _saving,
          items: const [false, true],
          prefixIcon: Icons.account_balance_wallet_outlined,
          labelBuilder: (saving) => saving
              ? (_isAr ? 'توفير' : 'Savings')
              : (_isAr ? 'جاري' : 'Current'),
          onChanged: (saving) => setState(() => _saving = saving),
        ),
        const SizedBox(height: 18),
        _sectionLabel(_isAr ? 'العملة' : 'Currency'),
        const SizedBox(height: 10),
        UffDropdownField<String>(
          value: _currency,
          items: _kCurrencies,
          prefixIcon: Icons.payments_outlined,
          labelBuilder: (c) => c,
          onChanged: (c) => setState(() => _currency = c),
        ),
        const SizedBox(height: 28),
        UffPrimaryButton(
          label: _isAr ? 'فتح الحساب' : 'Open account',
          loading: _loading,
          trailingChevron: false,
          onPressed: _loadingCustomer ? () {} : _openAccount,
          icon: Icons.add_rounded,
        ),
      ],
    );
  }

  Widget _sectionLabel(String text) {
    final colors = context.bankColors;
    return Text(
      text,
      style: AppTextStyles.labelSm(
        color: colors.onSurfaceVariant,
        languageCode: Localizations.localeOf(context).languageCode,
      ).copyWith(fontWeight: FontWeight.w600, letterSpacing: 0.2),
    );
  }
}

class _SuccessView extends StatelessWidget {
  const _SuccessView({required this.accountNumber, required this.onDone});

  final String? accountNumber;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final colors = context.bankColors;
    final lang = Localizations.localeOf(context).languageCode;
    final isAr = lang == 'ar';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          Container(
            width: 88,
            height: 88,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: colors.accentGreen.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.check_rounded, size: 46, color: colors.accentGreen),
          ),
          const SizedBox(height: 18),
          Text(
            isAr ? 'تم فتح حسابك بنجاح' : 'Account opened successfully',
            textAlign: TextAlign.center,
            style: AppTextStyles.headlineMd(color: colors.onSurface, languageCode: lang)
                .copyWith(fontWeight: FontWeight.w700),
          ),
          if (accountNumber != null) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                color: colors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.5)),
              ),
              child: Column(
                children: [
                  Text(
                    isAr ? 'رقم الحساب الجديد' : 'New account number',
                    style: AppTextStyles.labelSm(
                        color: colors.onSurfaceVariant, languageCode: lang),
                  ),
                  const SizedBox(height: 4),
                  SelectableText(
                    accountNumber!,
                    style: AppTextStyles.headlineMd(
                            color: colors.secondary, languageCode: lang)
                        .copyWith(fontWeight: FontWeight.w700, letterSpacing: 1),
                  ),
                ],
              ),
            ),
          ] else ...[
            const SizedBox(height: 12),
            Text(
              isAr
                  ? 'ستجد حسابك الجديد في «كل حساباتي».'
                  : 'You\'ll find your new account under "My Accounts".',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMd(
                      color: colors.onSurfaceVariant, languageCode: lang)
                  .copyWith(height: 1.4),
            ),
          ],
          const SizedBox(height: 28),
          UffPrimaryButton(
            label: isAr ? 'تم' : 'Done',
            loading: false,
            trailingChevron: false,
            onPressed: onDone,
          ),
        ],
      ),
    );
  }
}
