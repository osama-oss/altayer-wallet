import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:freerasp/freerasp.dart';

import 'threat_policy.dart';

/// A single RASP detection mapped to the action the active policy demands.
class SecurityEvent {
  const SecurityEvent(this.threat, this.action);
  final Threat threat;
  final SecurityAction action;
}

/// Initializes and owns freeRASP runtime self-protection (root/jailbreak,
/// hooks/Frida, debugger, emulator, repackaging/tamper, screen capture, …).
///
/// IMPORTANT (defense-in-depth): on-device detection is ADVISORY. A rooted /
/// hooked device can defeat any client check, so the authoritative gate for
/// money movement must be SERVER-SIDE attestation (Google Play Integrity /
/// Apple App Attest) verified in mobile-service. This service runs a graded
/// [ThreatPolicy] (default: monitor) and surfaces events for telemetry/UI.
/// It is fail-open on init: RASP must never crash app startup.
class RaspService {
  RaspService._();
  static final RaspService instance = RaspService._();

  ThreatPolicy _policy = ThreatPolicy.monitor;
  StreamSubscription<Threat>? _sub;

  /// Most recent detection (null = none yet). UI can watch this once the policy
  /// graduates from `monitor` to `warn`/`enforce`.
  final ValueNotifier<SecurityEvent?> latestEvent = ValueNotifier(null);

  /// Highest action demanded this session (observe < restrict < block).
  final ValueNotifier<SecurityAction> highestAction =
      ValueNotifier(SecurityAction.observe);

  ThreatPolicy get policy => _policy;

  Future<void> start({
    required ThreatPolicy policy,
    required String watcherMail,
    required String androidPackageName,
    required List<String> androidSigningCertHashes,
    required List<String> iosBundleIds,
    required String iosTeamId,
    void Function(SecurityEvent event)? onEvent,
  }) async {
    _policy = policy;
    try {
      _sub = Talsec.instance.onThreatDetected.listen((threat) {
        final action = actionFor(threat, _policy);
        final event = SecurityEvent(threat, action);
        latestEvent.value = event;
        if (action.index > highestAction.value.index) {
          highestAction.value = action;
        }
        // Telemetry runs in ALL modes (incl. monitor) so we can measure the
        // real false-positive baseline before tightening the policy.
        // TODO(security): forward to mobile-service audit endpoint (no PII).
        debugPrint(
          '[security] threat=${threat.name} action=${action.name} policy=${_policy.name}',
        );
        onEvent?.call(event);
      });

      await Talsec.instance.start(
        TalsecConfig(
          watcherMail: watcherMail,
          isProd: kReleaseMode, // relaxes tamper checks for debug builds
          killOnBypass: false, // the graded policy owns the response, not a hard kill
          androidConfig: AndroidConfig(
            packageName: androidPackageName,
            signingCertHashes: androidSigningCertHashes,
          ),
          iosConfig: IOSConfig(bundleIds: iosBundleIds, teamId: iosTeamId),
        ),
      );
    } catch (e) {
      // Fail-open: a RASP init failure must never break app startup.
      debugPrint('[security] RASP init skipped: $e');
    }
  }

  Future<void> dispose() async {
    await _sub?.cancel();
    _sub = null;
  }
}
