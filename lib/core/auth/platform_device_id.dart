import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';

/// Reads an OS-stable device identifier that **survives the app's data/cache
/// being cleared** (and reinstalls).
///
///  • Android → `Settings.Secure.ANDROID_ID` (read natively via the existing
///    device channel). Scoped to the app signing key; resets only on factory
///    reset / key change. No runtime permission needed.
///  • iOS / other → returns null. The caller then keeps a UUID in the Keychain,
///    which already persists across reinstall on iOS, so a stable id is not
///    required there.
class PlatformDeviceId {
  const PlatformDeviceId([MethodChannel? channel])
      : _channel = channel ??
            const MethodChannel('com.banksync.banksync_app/device_signing');

  final MethodChannel _channel;

  /// A famously-broken SSAID shipped by some emulators / cloned ROMs — must not
  /// be used as a unique id.
  static const _knownBadAndroidId = '9774d56d682e549c';

  Future<String?> stableId() async {
    if (kIsWeb || !Platform.isAndroid) return null;
    try {
      final raw = await _channel.invokeMethod<String>('getAndroidId');
      final id = raw?.trim() ?? '';
      if (id.isEmpty || id.toLowerCase() == _knownBadAndroidId) return null;
      return id;
    } catch (_) {
      // Channel missing / native error → let the caller fall back to a UUID.
      return null;
    }
  }
}
