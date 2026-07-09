import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/bank_sync_colors.dart';
import '../../l10n/app_localizations.dart';

/// شاشة توثيق الحساب (KYC): رفع وجه البطاقة الشخصية + ظهرها + صورة سيلفي.
///
/// واجهة فقط الآن — التقاط/رفع الصور الحقيقي (image_picker + صلاحيات الكاميرا)
/// والربط بالكور يُضافان لاحقاً. الضغط على خانة الرفع يفتح خيارات (الكاميرا /
/// المعرض) ويُعلّم الوثيقة كمُختارة لعرض تدفّق الشاشة.
class KycScreen extends StatefulWidget {
  const KycScreen({super.key});

  @override
  State<KycScreen> createState() => _KycScreenState();
}

class _KycScreenState extends State<KycScreen> {
  bool _idFront = false;
  bool _idBack = false;
  bool _selfie = false;

  bool get _ready => _idFront && _idBack && _selfie;

  Future<void> _pick(String label, ValueChanged<bool> onPicked) async {
    final l10n = context.l10n;
    final colors = context.bankColors;
    final source = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colors.outlineVariant,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: Icon(Icons.photo_camera_outlined, color: colors.secondary),
              title: Text(
                l10n.kycCamera,
                style: const TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.w700),
              ),
              onTap: () => Navigator.pop(ctx, 'camera'),
            ),
            ListTile(
              leading: Icon(Icons.photo_library_outlined, color: colors.secondary),
              title: Text(
                l10n.kycGallery,
                style: const TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.w700),
              ),
              onTap: () => Navigator.pop(ctx, 'gallery'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (source != null) onPicked(true);
  }

  void _submit() {
    if (!_ready) return;
    final l10n = context.l10n;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.kycSubmitted)),
    );
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.bankColors;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: Text(
          l10n.kycTitle,
          style: const TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.kycSubtitle,
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  height: 1.5,
                  color: colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 20),
              _UploadTile(
                colors: colors,
                icon: Icons.badge_outlined,
                label: l10n.kycIdFront,
                hint: l10n.kycUploadHint,
                selected: _idFront,
                onTap: () => _pick(l10n.kycIdFront, (v) => setState(() => _idFront = v)),
              ),
              const SizedBox(height: 14),
              _UploadTile(
                colors: colors,
                icon: Icons.badge_outlined,
                label: l10n.kycIdBack,
                hint: l10n.kycUploadHint,
                selected: _idBack,
                onTap: () => _pick(l10n.kycIdBack, (v) => setState(() => _idBack = v)),
              ),
              const SizedBox(height: 14),
              _UploadTile(
                colors: colors,
                icon: Icons.face_outlined,
                label: l10n.kycSelfie,
                hint: l10n.kycUploadHint,
                selected: _selfie,
                onTap: () => _pick(l10n.kycSelfie, (v) => setState(() => _selfie = v)),
              ),
              const SizedBox(height: 28),
              SizedBox(
                height: 54,
                child: FilledButton(
                  onPressed: _ready ? _submit : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: colors.secondary,
                    foregroundColor: colors.onSecondary,
                    disabledBackgroundColor: colors.secondary.withValues(alpha: 0.4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    l10n.kycSubmit,
                    style: const TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UploadTile extends StatelessWidget {
  const _UploadTile({
    required this.colors,
    required this.icon,
    required this.label,
    required this.hint,
    required this.selected,
    required this.onTap,
  });

  final BankSyncColors colors;
  final IconData icon;
  final String label;
  final String hint;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected
              ? colors.secondary.withValues(alpha: 0.08)
              : colors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? colors.secondary : colors.outlineVariant,
            width: 1.3,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: selected
                    ? colors.secondary.withValues(alpha: 0.15)
                    : colors.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: colors.secondary, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: colors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    hint,
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              selected ? Icons.check_circle_rounded : Icons.upload_file_outlined,
              color: selected ? colors.accentGreen : colors.onSurfaceVariant,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
}
