import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';

class DeviceSigningService {
  DeviceSigningService({MethodChannel? channel, EventChannel? failureEvents})
      : _channel = channel ??
            const MethodChannel('com.banksync.banksync_app/device_signing'),
        _failureEvents = failureEvents ??
            const EventChannel('com.banksync.banksync_app/device_signing_failures');

  static const publicKeyAlg = 'EC_P256';

  final MethodChannel _channel;
  final EventChannel _failureEvents;

  Future<bool> hasEnrollmentKey() async {
    try {
      final result = await _channel.invokeMethod<bool>('hasEnrollmentKey');
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<String> createEnrollmentKey() async {
    final result = await _channel.invokeMethod<String>('createEnrollmentKey');
    if (result == null || result.isEmpty) {
      throw const DeviceSigningException('Failed to create enrollment key');
    }
    return result;
  }

  Future<String> signNonce(
    String nonceBase64, {
    Future<void> Function()? onBiometricAttemptFailed,
  }) async {
    StreamSubscription<dynamic>? failureSub;
    if (onBiometricAttemptFailed != null) {
      failureSub = _failureEvents.receiveBroadcastStream().listen((_) async {
        await onBiometricAttemptFailed();
      });
    }
    try {
      final result = await _channel.invokeMethod<String>(
        'signNonce',
        {'nonce': nonceBase64},
      );
      if (result == null || result.isEmpty) {
        throw const DeviceSigningException('Failed to sign biometric challenge');
      }
      return result;
    } on PlatformException catch (e) {
      if (onBiometricAttemptFailed != null && !kIsWeb && Platform.isIOS) {
        await onBiometricAttemptFailed();
      }
      throw DeviceSigningException(e.message ?? 'Biometric signing failed');
    } finally {
      await failureSub?.cancel();
    }
  }

  Future<void> deleteEnrollmentKey() async {
    await _channel.invokeMethod<void>('deleteEnrollmentKey');
  }
}

class DeviceSigningException implements Exception {
  const DeviceSigningException(this.message);

  final String message;

  @override
  String toString() => message;
}
