import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import 'terms_content_ar.dart';

/// شاشة عرض الشروط والأحكام (سياسة فتح حساب المحفظة الإلكترونية).
///
/// المحتوى عربي بالكامل ويُعرض دائماً باتجاه من اليمين لليسار بغض النظر عن لغة
/// التطبيق. الشاشة للقراءة فقط، مع زر عائم للتمرير السريع إلى أسفل/أعلى الوثيقة.
class TermsScreen extends StatefulWidget {
  const TermsScreen({super.key});

  @override
  State<TermsScreen> createState() => _TermsScreenState();
}

class _TermsScreenState extends State<TermsScreen> {
  final ScrollController _controller = ScrollController();
  bool _atBottom = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onScroll);
  }

  void _onScroll() {
    if (!_controller.hasClients) return;
    final atBottom =
        _controller.offset >= _controller.position.maxScrollExtent - 24;
    if (atBottom != _atBottom) setState(() => _atBottom = atBottom);
  }

  void _jump() {
    if (!_controller.hasClients) return;
    _controller.animateTo(
      _atBottom ? 0 : _controller.position.maxScrollExtent,
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _controller.removeListener(_onScroll);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            l10n.termsAndConditions,
            style: const TextStyle(
              fontFamily: 'Tajawal',
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton.small(
          onPressed: _jump,
          backgroundColor: scheme.error,
          foregroundColor: scheme.onError,
          child: Icon(_atBottom
              ? Icons.keyboard_arrow_up_rounded
              : Icons.keyboard_arrow_down_rounded),
        ),
        body: ListView.builder(
          controller: _controller,
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 96),
          itemCount: termsSectionsAr.length + 1,
          itemBuilder: (context, index) {
            if (index == termsSectionsAr.length) {
              return _Disclaimer(scheme: scheme);
            }
            return _BlockView(block: termsSectionsAr[index], scheme: scheme);
          },
        ),
      ),
    );
  }
}

class _BlockView extends StatelessWidget {
  const _BlockView({required this.block, required this.scheme});

  final TermsBlock block;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    switch (block.kind) {
      case TermsBlockKind.heading:
        return Padding(
          padding: const EdgeInsets.only(top: 4, bottom: 16),
          child: Text(
            block.text,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 20,
              fontWeight: FontWeight.w800,
              height: 1.5,
              color: scheme.primary,
            ),
          ),
        );
      case TermsBlockKind.subheading:
        return Padding(
          padding: const EdgeInsets.only(top: 22, bottom: 8),
          child: Text(
            block.text,
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              height: 1.5,
              color: scheme.onSurface,
            ),
          ),
        );
      case TermsBlockKind.paragraph:
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            block.text,
            textAlign: TextAlign.justify,
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 14.5,
              height: 1.85,
              color: scheme.onSurfaceVariant,
            ),
          ),
        );
      case TermsBlockKind.bullet:
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 9),
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: scheme.primary,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  block.text,
                  textAlign: TextAlign.justify,
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 14.5,
                    height: 1.85,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        );
    }
  }
}

class _Disclaimer extends StatelessWidget {
  const _Disclaimer({required this.scheme});

  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 28),
      child: Text(
        context.l10n.termsAndConditionsFooter,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: 'Tajawal',
          fontSize: 12,
          height: 1.6,
          color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
        ),
      ),
    );
  }
}
