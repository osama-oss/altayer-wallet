import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/bank_sync_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../kyc_camera_permission.dart';
import '../kyc_document.dart';
import 'kyc_camera_overlay.dart';

/// Opens the custom in-app capture screen for [docType] and resolves with the
/// confirmed [XFile], or `null` if the user backs out. [stepIndex]/[stepCount]
/// drive the "X of N" progress chip.
Future<XFile?> openKycCamera(
  BuildContext context, {
  required KycDocType docType,
  int? stepIndex,
  int? stepCount,
}) {
  return Navigator.of(context).push<XFile>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => KycCameraScreen(
        docType: docType,
        stepIndex: stepIndex,
        stepCount: stepCount,
      ),
    ),
  );
}

enum _CamPhase { initializing, live, capturing, review, permission, unavailable }

/// A bespoke document / selfie camera — full-bleed preview, a dark scrim with a
/// document-shaped cutout, glowing brand-blue frame, live guidance, flash and an
/// in-place capture→review→confirm loop. It never opens the system camera app
/// or the gallery. Returns the confirmed photo via [Navigator.pop].
class KycCameraScreen extends StatefulWidget {
  const KycCameraScreen({
    super.key,
    required this.docType,
    this.stepIndex,
    this.stepCount,
  });

  final KycDocType docType;
  final int? stepIndex;
  final int? stepCount;

  @override
  State<KycCameraScreen> createState() => _KycCameraScreenState();
}

class _KycCameraScreenState extends State<KycCameraScreen>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  static const _permission = KycCameraPermission();

  CameraController? _controller;
  List<CameraDescription> _cameras = const [];
  _CamPhase _phase = _CamPhase.initializing;
  bool _torchOn = false;
  bool _permanentlyDenied = false;
  XFile? _shot;

  late final AnimationController _glow = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..repeat(reverse: true);

  bool get _isSelfie => widget.docType.useFrontCamera;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _bootstrap();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _glow.dispose();
    _controller?.dispose();
    // A captured-but-not-confirmed shot is a temp file we're abandoning.
    if (_shot != null) _safeDelete(_shot!);
    super.dispose();
  }

  // ── Lifecycle: release the camera in the background, restore on resume ──
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      final controller = _controller;
      if (controller != null && controller.value.isInitialized) {
        controller.dispose();
        _controller = null;
      }
    } else if (state == AppLifecycleState.resumed) {
      // Rebuild the controller only when a live viewfinder is expected. The
      // review state uses the captured file and needs no camera; retake
      // re-initializes on demand.
      if (_controller == null &&
          (_phase == _CamPhase.live || _phase == _CamPhase.initializing)) {
        _initController();
      }
    }
  }

  // ── Bootstrap: permission → cameras → controller ───────────────────────
  Future<void> _bootstrap() async {
    final result = await _permission.ensure();
    if (!mounted) return;
    if (result != KycCameraPermissionResult.granted) {
      setState(() {
        _phase = _CamPhase.permission;
        _permanentlyDenied =
            result == KycCameraPermissionResult.permanentlyDenied;
      });
      return;
    }
    try {
      _cameras = await availableCameras();
    } catch (_) {
      _cameras = const [];
    }
    if (!mounted) return;
    if (_cameras.isEmpty) {
      setState(() => _phase = _CamPhase.unavailable);
      return;
    }
    await _initController();
  }

  Future<void> _initController() async {
    final lens = _isSelfie ? CameraLensDirection.front : CameraLensDirection.back;
    final description = _cameras.firstWhere(
      (c) => c.lensDirection == lens,
      orElse: () => _cameras.first,
    );
    final controller = CameraController(
      description,
      // veryHigh keeps ID text crisp without the memory cost of max.
      ResolutionPreset.veryHigh,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );
    try {
      await controller.initialize();
      await controller.lockCaptureOrientation(DeviceOrientation.portraitUp);
      if (!_isSelfie) {
        await controller.setFlashMode(FlashMode.off);
      }
    } catch (_) {
      if (mounted) setState(() => _phase = _CamPhase.unavailable);
      return;
    }
    if (!mounted) {
      controller.dispose();
      return;
    }
    setState(() {
      _controller = controller;
      _torchOn = false;
      _phase = _CamPhase.live;
    });
  }

  // ── Actions ────────────────────────────────────────────────────────────
  Future<void> _toggleTorch() async {
    final controller = _controller;
    if (controller == null || _isSelfie) return;
    try {
      final next = _torchOn ? FlashMode.off : FlashMode.torch;
      await controller.setFlashMode(next);
      if (mounted) setState(() => _torchOn = !_torchOn);
    } catch (_) {
      // Torch may be unsupported (front lens / emulator) — ignore.
    }
  }

  Future<void> _capture() async {
    final controller = _controller;
    if (controller == null ||
        !controller.value.isInitialized ||
        _phase != _CamPhase.live ||
        controller.value.isTakingPicture) {
      return;
    }
    setState(() => _phase = _CamPhase.capturing);
    try {
      final file = await controller.takePicture();
      if (_torchOn) {
        await controller.setFlashMode(FlashMode.off);
      }
      if (!mounted) {
        _safeDelete(file);
        return;
      }
      setState(() {
        _shot = file;
        _torchOn = false;
        _phase = _CamPhase.review;
      });
    } catch (_) {
      if (mounted) {
        setState(() => _phase = _CamPhase.live);
        _snack(context.l10n.kycUploadFailed);
      }
    }
  }

  void _retake() {
    final shot = _shot;
    if (shot != null) _safeDelete(shot);
    setState(() {
      _shot = null;
      _phase = _CamPhase.live;
    });
    // If the app was backgrounded during review, the controller was released —
    // bring it back for the live viewfinder.
    if (_controller == null || !_controller!.value.isInitialized) {
      _initController();
    }
  }

  void _usePhoto() {
    final shot = _shot;
    if (shot == null) return;
    // Handing ownership to the caller — clear so dispose won't delete it.
    _shot = null;
    Navigator.of(context).pop(shot);
  }

  Future<void> _openSettings() async {
    await _permission.openSettings();
  }

  Future<void> _safeDelete(XFile file) async {
    try {
      final f = File(file.path);
      if (await f.exists()) await f.delete();
    } catch (_) {
      // Best-effort temp cleanup.
    }
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  // ── Build ──────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final colors = context.bankColors;
    return Scaffold(
      backgroundColor: Colors.black,
      body: switch (_phase) {
        _CamPhase.permission => _PermissionState(
            permanentlyDenied: _permanentlyDenied,
            onOpenSettings: _openSettings,
            onRetry: _bootstrap,
            onBack: () => Navigator.of(context).maybePop(),
          ),
        _CamPhase.unavailable => _UnavailableState(
            onBack: () => Navigator.of(context).maybePop(),
          ),
        _CamPhase.review => _ReviewState(
            file: _shot!,
            docType: widget.docType,
            onRetake: _retake,
            onUse: _usePhoto,
          ),
        _ => _LiveState(
            controller: _controller,
            docType: widget.docType,
            glow: _glow,
            torchOn: _torchOn,
            capturing: _phase == _CamPhase.capturing,
            frameColor: AppColors.walletBrandAlt,
            stepIndex: widget.stepIndex,
            stepCount: widget.stepCount,
            onCapture: _capture,
            onToggleTorch: _toggleTorch,
            onBack: () => Navigator.of(context).maybePop(),
            colors: colors,
          ),
      },
    );
  }
}

// ── Live viewfinder ─────────────────────────────────────────────────────────
class _LiveState extends StatelessWidget {
  const _LiveState({
    required this.controller,
    required this.docType,
    required this.glow,
    required this.torchOn,
    required this.capturing,
    required this.frameColor,
    required this.stepIndex,
    required this.stepCount,
    required this.onCapture,
    required this.onToggleTorch,
    required this.onBack,
    required this.colors,
  });

  final CameraController? controller;
  final KycDocType docType;
  final Animation<double> glow;
  final bool torchOn;
  final bool capturing;
  final Color frameColor;
  final int? stepIndex;
  final int? stepCount;
  final VoidCallback onCapture;
  final VoidCallback onToggleTorch;
  final VoidCallback onBack;
  final BankSyncColors colors;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final ready = controller != null && controller!.value.isInitialized;

    return Stack(
      fit: StackFit.expand,
      children: [
        if (ready)
          _CoveredPreview(controller: controller!)
        else
          const Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),

        // Dark scrim + document/face frame.
        if (ready)
          LayoutBuilder(
            builder: (context, constraints) {
              final size = Size(constraints.maxWidth, constraints.maxHeight);
              final cutout =
                  KycFrameGeometry.cutout(size, docType.frameShape);
              return Stack(
                children: [
                  Positioned.fill(
                    child: AnimatedBuilder(
                      animation: glow,
                      builder: (_, __) => CustomPaint(
                        painter: KycCameraOverlayPainter(
                          cutout: cutout,
                          shape: docType.frameShape,
                          frameColor: frameColor,
                          scrimColor: Colors.black.withValues(alpha: 0.62),
                          glow: Curves.easeInOut.transform(glow.value),
                        ),
                      ),
                    ),
                  ),
                  // Guidance above the frame.
                  Positioned(
                    left: 24,
                    right: 24,
                    top: (cutout.top - 92).clamp(90.0, size.height),
                    child: _Guidance(
                      title: docType.label(l10n),
                      subtitle: docType.guide(l10n),
                    ),
                  ),
                  // Lighting hint below the frame.
                  Positioned(
                    left: 24,
                    right: 24,
                    top: cutout.bottom + 18,
                    child: _LightingHint(text: l10n.kycCameraLightingHint),
                  ),
                ],
              );
            },
          ),

        // Top bar: back + step chip + flash.
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                _GlassButton(icon: Icons.arrow_back_rounded, onTap: onBack),
                const Spacer(),
                if (stepIndex != null && stepCount != null)
                  _StepChip(
                    label: l10n.kycStepProgress(stepIndex!, stepCount!),
                  ),
                const Spacer(),
                if (!docType.useFrontCamera)
                  _GlassButton(
                    icon: torchOn
                        ? Icons.flash_on_rounded
                        : Icons.flash_off_rounded,
                    onTap: onToggleTorch,
                    active: torchOn,
                  )
                else
                  const SizedBox(width: 44),
              ],
            ),
          ),
        ),

        // Capture button.
        Align(
          alignment: Alignment.bottomCenter,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 28, top: 12),
              child: _ShutterButton(
                busy: capturing,
                onTap: capturing ? null : onCapture,
                color: frameColor,
              ),
            ),
          ),
        ),

        // Processing veil.
        if (capturing)
          Positioned.fill(
            child: ColoredBox(
              color: Colors.black.withValues(alpha: 0.35),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(color: Colors.white),
                    const SizedBox(height: 14),
                    Text(
                      l10n.kycProcessing,
                      style: const TextStyle(
                        fontFamily: 'Tajawal',
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Full-bleed camera preview using a cover fit on the sensor preview size.
class _CoveredPreview extends StatelessWidget {
  const _CoveredPreview({required this.controller});

  final CameraController controller;

  @override
  Widget build(BuildContext context) {
    final preview = controller.value.previewSize;
    if (preview == null) return CameraPreview(controller);
    return ClipRect(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          // previewSize is reported in sensor (landscape) orientation; swap for
          // the portrait viewfinder.
          width: preview.height,
          height: preview.width,
          child: CameraPreview(controller),
        ),
      ),
    );
  }
}

class _Guidance extends StatelessWidget {
  const _Guidance({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'Tajawal',
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w800,
            shadows: [Shadow(color: Colors.black54, blurRadius: 8)],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'Tajawal',
            color: Colors.white70,
            fontSize: 13,
            height: 1.4,
            fontWeight: FontWeight.w600,
            shadows: [Shadow(color: Colors.black54, blurRadius: 8)],
          ),
        ),
      ],
    );
  }
}

class _LightingHint extends StatelessWidget {
  const _LightingHint({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lightbulb_outline_rounded,
                color: Colors.white70, size: 16),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                text,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Tajawal',
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepChip extends StatelessWidget {
  const _StepChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: 'Tajawal',
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _GlassButton extends StatelessWidget {
  const _GlassButton({
    required this.icon,
    required this.onTap,
    this.active = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: active
          ? AppColors.walletBrandAlt.withValues(alpha: 0.9)
          : Colors.black.withValues(alpha: 0.4),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(icon, color: Colors.white, size: 22),
        ),
      ),
    );
  }
}

class _ShutterButton extends StatelessWidget {
  const _ShutterButton({
    required this.busy,
    required this.onTap,
    required this.color,
  });

  final bool busy;
  final VoidCallback? onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 78,
        height: 78,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.15),
          border: Border.all(color: Colors.white, width: 4),
        ),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: busy ? Colors.white54 : color,
            ),
            child: busy
                ? const Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      color: Colors.white,
                    ),
                  )
                : null,
          ),
        ),
      ),
    );
  }
}

// ── Review (captured photo) ─────────────────────────────────────────────────
class _ReviewState extends StatelessWidget {
  const _ReviewState({
    required this.file,
    required this.docType,
    required this.onRetake,
    required this.onUse,
  });

  final XFile file;
  final KycDocType docType;
  final VoidCallback onRetake;
  final VoidCallback onUse;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.bankColors;
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 16, 4),
            child: Row(
              children: [
                IconButton(
                  onPressed: onRetake,
                  icon: const Icon(Icons.close_rounded, color: Colors.white),
                ),
                Expanded(
                  child: Text(
                    l10n.kycPreviewTitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'Tajawal',
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: InteractiveViewer(
                    maxScale: 4,
                    child: Image.file(File(file.path), fit: BoxFit.contain),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 14, 24, 6),
            child: Text(
              l10n.kycPreviewHint,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Tajawal',
                color: Colors.white70,
                fontSize: 13,
                height: 1.45,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onRetake,
                    icon: const Icon(Icons.replay_rounded),
                    label: Text(
                      l10n.kycRetake,
                      style: const TextStyle(
                          fontFamily: 'Tajawal', fontWeight: FontWeight.w800),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white54),
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: onUse,
                    icon: const Icon(Icons.check_rounded),
                    label: Text(
                      l10n.kycUsePhoto,
                      style: const TextStyle(
                          fontFamily: 'Tajawal', fontWeight: FontWeight.w800),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: colors.secondary,
                      foregroundColor: colors.onSecondary,
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
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

// ── Permission / unavailable states ─────────────────────────────────────────
class _PermissionState extends StatelessWidget {
  const _PermissionState({
    required this.permanentlyDenied,
    required this.onOpenSettings,
    required this.onRetry,
    required this.onBack,
  });

  final bool permanentlyDenied;
  final VoidCallback onOpenSettings;
  final VoidCallback onRetry;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return _MessageScaffold(
      onBack: onBack,
      icon: Icons.no_photography_outlined,
      title: l10n.kycCameraPermissionTitle,
      body: l10n.kycCameraPermissionBody,
      primaryLabel: permanentlyDenied ? l10n.kycOpenSettings : l10n.kycRetry,
      onPrimary: permanentlyDenied ? onOpenSettings : onRetry,
    );
  }
}

class _UnavailableState extends StatelessWidget {
  const _UnavailableState({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return _MessageScaffold(
      onBack: onBack,
      icon: Icons.videocam_off_outlined,
      title: l10n.kycCameraUnavailable,
      body: l10n.kycCameraUnavailableBody,
      primaryLabel: l10n.kycBackToHome,
      onPrimary: onBack,
    );
  }
}

class _MessageScaffold extends StatelessWidget {
  const _MessageScaffold({
    required this.onBack,
    required this.icon,
    required this.title,
    required this.body,
    required this.primaryLabel,
    required this.onPrimary,
  });

  final VoidCallback onBack;
  final IconData icon;
  final String title;
  final String body;
  final String primaryLabel;
  final VoidCallback onPrimary;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Stack(
        children: [
          Align(
            alignment: AlignmentDirectional.topStart,
            child: IconButton(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 56, color: Colors.white70),
                  const SizedBox(height: 20),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'Tajawal',
                      color: Colors.white,
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    body,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'Tajawal',
                      color: Colors.white70,
                      fontSize: 14,
                      height: 1.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 26),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton(
                      onPressed: onPrimary,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.walletBrandAlt,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      child: Text(
                        primaryLabel,
                        style: const TextStyle(
                            fontFamily: 'Tajawal', fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
