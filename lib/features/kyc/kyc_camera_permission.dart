import 'package:permission_handler/permission_handler.dart';

/// Outcome of requesting the camera permission.
enum KycCameraPermissionResult { granted, denied, permanentlyDenied }

/// Camera permission gate for the KYC capture screens.
///
/// `android.permission.CAMERA` is declared in the manifest (for the QR
/// scanner), so Android enforces a runtime grant before the camera hardware
/// opens. We request it explicitly here — before initializing the
/// [CameraController] — so we can present branded permission / settings UI
/// instead of a silent failure.
class KycCameraPermission {
  const KycCameraPermission();

  Future<KycCameraPermissionResult> ensure() async {
    final status = await Permission.camera.status;
    if (status.isGranted || status.isLimited) {
      return KycCameraPermissionResult.granted;
    }
    if (status.isPermanentlyDenied || status.isRestricted) {
      return KycCameraPermissionResult.permanentlyDenied;
    }
    final result = await Permission.camera.request();
    if (result.isGranted || result.isLimited) {
      return KycCameraPermissionResult.granted;
    }
    if (result.isPermanentlyDenied || result.isRestricted) {
      return KycCameraPermissionResult.permanentlyDenied;
    }
    return KycCameraPermissionResult.denied;
  }

  /// Opens the app's system settings page (used after a permanent denial).
  Future<bool> openSettings() => openAppSettings();
}
