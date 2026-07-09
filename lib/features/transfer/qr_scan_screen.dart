import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../core/qr/account_qr_payload.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/bank_sync_colors.dart';

Future<String?> openQrScanScreen(BuildContext context) {
  return Navigator.of(context).push<String>(
    MaterialPageRoute(builder: (_) => const QrScanScreen()),
  );
}

class QrScanScreen extends StatefulWidget {
  const QrScanScreen({super.key});

  @override
  State<QrScanScreen> createState() => _QrScanScreenState();
}

class _QrScanScreenState extends State<QrScanScreen> {
  final _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
  );
  bool _handled = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_handled) return;
    final raw = capture.barcodes.firstOrNull?.rawValue;
    if (raw == null || raw.isEmpty) return;

    final payload = AccountQrPayload.decode(raw);
    if (payload == null) {
      setState(() => _error = 'Not a valid account QR');
      return;
    }

    _handled = true;
    Navigator.of(context).pop(payload.accountNumber);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.bankColors;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Scan account QR'),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(controller: _controller, onDetect: _onDetect),
          Center(
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                border: Border.all(color: colors.accentGreen, width: 2),
                borderRadius: BorderRadius.circular(AppColors.radiusMd),
              ),
            ),
          ),
          Positioned(
            left: 24,
            right: 24,
            bottom: 32 + MediaQuery.paddingOf(context).bottom,
            child: Column(
              children: [
                if (_error != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: colors.error.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(AppColors.radiusSm),
                    ),
                    child: Text(_error!, style: const TextStyle(color: Colors.white)),
                  ),
                Text(
                  'Point at an account QR code',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.85)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
