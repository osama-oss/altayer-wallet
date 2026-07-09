import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

enum CardNetwork { visa, mastercard }

class PaymentCardWidget extends StatelessWidget {
  const PaymentCardWidget({
    super.key,
    required this.label,
    required this.lastFour,
    required this.expiry,
    required this.network,
    this.cardholderName = 'CARDHOLDER',
    this.width = 280,
    this.gradientColors,
  });

  final String label;
  final String lastFour;
  final String expiry;
  final CardNetwork network;
  final String cardholderName;
  final double width;
  final List<Color>? gradientColors;

  static const _visaGradient = [
    Color(0xFF1A1F71),
    Color(0xFF0D47A1),
    Color(0xFF1565C0),
  ];

  static const _mastercardGradient = [
    Color(0xFF1A1A2E),
    Color(0xFF16213E),
    Color(0xFF0F3460),
  ];

  @override
  Widget build(BuildContext context) {
    final isVisa = network == CardNetwork.visa;
    final height = width / 1.5;
    final languageCode = Localizations.localeOf(context).languageCode;
    final isAr = languageCode == 'ar';

    return SizedBox(
      width: width,
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppColors.radiusLg),
          boxShadow: const [
            BoxShadow(
              color: Color(0x33000000),
              blurRadius: 16,
              offset: Offset(0, 6),
            ),
          ],
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradientColors ?? (isVisa ? _visaGradient : _mastercardGradient),
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppColors.radiusLg),
          child: Stack(
            children: [
              _CardBackgroundDecor(isVisa: isVisa),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          isAr ? label : label.toUpperCase(),
                          style: AppTextStyles.labelSm(
                            color: Colors.white.withValues(alpha: 0.85),
                            languageCode: languageCode,
                          ).copyWith(
                            letterSpacing: isAr ? 0 : 1.2,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        Icon(
                          Icons.contactless,
                          color: Colors.white.withValues(alpha: 0.8),
                          size: 20,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const _EmvChip(),
                    const Spacer(),
                    Text(
                      '•••• •••• •••• $lastFour',
                      style: AppTextStyles.monoLabel(color: Colors.white).copyWith(
                        fontSize: 16,
                        letterSpacing: 1.6,
                        fontWeight: FontWeight.w600,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'CARDHOLDER',
                                style: AppTextStyles.labelSm(
                                  color: Colors.white.withValues(alpha: 0.55),
                                  languageCode: languageCode,
                                ).copyWith(fontSize: 8, letterSpacing: 0.8, height: 1),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                cardholderName.toUpperCase(),
                                style: AppTextStyles.labelSm(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  languageCode: languageCode,
                                ).copyWith(
                                  fontSize: 10,
                                  letterSpacing: 0.6,
                                  fontWeight: FontWeight.w600,
                                  height: 1.1,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'VALID THRU',
                              style: AppTextStyles.labelSm(
                                color: Colors.white.withValues(alpha: 0.55),
                                languageCode: languageCode,
                              ).copyWith(fontSize: 8, letterSpacing: 0.8, height: 1),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              expiry,
                              style: AppTextStyles.monoLabel(
                                color: Colors.white.withValues(alpha: 0.9),
                              ).copyWith(fontSize: 11, height: 1.1),
                            ),
                          ],
                        ),
                        const SizedBox(width: 10),
                        SizedBox(
                          height: 32,
                          child: Align(
                            alignment: Alignment.bottomRight,
                            child: isVisa ? const _VisaLogo() : const _MastercardLogo(),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CardBackgroundDecor extends StatelessWidget {
  const _CardBackgroundDecor({required this.isVisa});

  final bool isVisa;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          right: -40,
          top: -30,
          child: Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: isVisa ? 0.06 : 0.04),
            ),
          ),
        ),
        Positioned(
          right: 20,
          bottom: -50,
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: isVisa ? 0.04 : 0.03),
            ),
          ),
        ),
        if (!isVisa)
          Positioned(
            left: -30,
            bottom: -20,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFEB001B).withValues(alpha: 0.12),
              ),
            ),
          ),
      ],
    );
  }
}

class _EmvChip extends StatelessWidget {
  const _EmvChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 28,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE8D48A), Color(0xFFC9A227), Color(0xFF9A7B0A)],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25), width: 0.5),
      ),
      child: CustomPaint(painter: _ChipLinesPainter()),
    );
  }
}

class _ChipLinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withValues(alpha: 0.15)
      ..strokeWidth = 0.8;

    for (var i = 1; i < 4; i++) {
      final x = size.width * i / 4;
      canvas.drawLine(Offset(x, 4), Offset(x, size.height - 4), paint);
    }
    canvas.drawLine(
      Offset(4, size.height * 0.45),
      Offset(size.width - 4, size.height * 0.45),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _VisaLogo extends StatelessWidget {
  const _VisaLogo();

  @override
  Widget build(BuildContext context) {
    return Text(
      'VISA',
      style: TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.w800,
        fontStyle: FontStyle.italic,
        letterSpacing: 1.2,
        height: 1,
        shadows: [
          Shadow(
            color: Colors.black.withValues(alpha: 0.2),
            offset: const Offset(0, 1),
            blurRadius: 2,
          ),
        ],
      ),
    );
  }
}

class _MastercardLogo extends StatelessWidget {
  const _MastercardLogo();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        SizedBox(
          width: 40,
          height: 24,
          child: CustomPaint(painter: _MastercardCirclesPainter()),
        ),
        Text(
          'mastercard',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.9),
            fontSize: 7,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
            height: 1,
          ),
        ),
      ],
    );
  }
}

class _MastercardCirclesPainter extends CustomPainter {
  static const _red = Color(0xFFEB001B);
  static const _orange = Color(0xFFF79E1B);

  @override
  void paint(Canvas canvas, Size size) {
    final radius = size.height / 2;
    final centerY = size.height / 2;
    final leftCenter = Offset(size.width * 0.38, centerY);
    final rightCenter = Offset(size.width * 0.62, centerY);

    canvas.drawCircle(leftCenter, radius, Paint()..color = _red);
    canvas.drawCircle(rightCenter, radius, Paint()..color = _orange);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
