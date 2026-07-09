import 'package:freerasp/freerasp.dart' show Threat;

/// Graded response policy for RASP threats, per the agreed rollout:
///   monitor  → observe + report only (never blocks a user)
///   warn     → restrict sensitive operations on real-posture threats
///   enforce  → block only on high-confidence tamper / active attack
///
/// Tunable from app_config.json (and, later, a remote-config override) so we
/// can ship in `monitor`, measure false positives on the real install base,
/// then tighten — the rollout pattern PCI-DSS / MASVS-RESILIENCE expect.
enum ThreatPolicy {
  monitor,
  warn,
  enforce;

  static ThreatPolicy fromName(String? value) {
    switch (value?.trim().toLowerCase()) {
      case 'warn':
        return ThreatPolicy.warn;
      case 'enforce':
        return ThreatPolicy.enforce;
      default:
        return ThreatPolicy.monitor; // safe default: never lock users out
    }
  }
}

/// What the app does in response to a single detected threat.
/// Ordered by escalation so `index` comparisons work (observe < restrict < block).
enum SecurityAction { observe, restrict, block }

enum _Severity { high, medium, low }

/// Maps a freeRASP [Threat] to a severity tier:
///   HIGH   = high-confidence tamper / active attack (repackaging, hooks,
///            debugger, emulator) → block under `enforce`.
///   MEDIUM = device posture worth restricting sensitive ops (root/jailbreak)
///            — NOT block, since custom ROMs cause false positives.
///   LOW    = low-confidence / high-false-positive signals (system VPN, public
///            Wi-Fi, screenshots, developer mode/ADB — near-100% hit rate on
///            the team's own test devices, so telemetry only while `warn` is
///            the shipped default).
_Severity _severityOf(Threat threat) {
  switch (threat) {
    case Threat.appIntegrity:
    case Threat.unofficialStore:
    case Threat.hooks:
    case Threat.debug:
    case Threat.simulator:
    case Threat.multiInstance:
      return _Severity.high;
    case Threat.privilegedAccess: // root / jailbreak
    case Threat.automation:
    case Threat.secureHardwareNotAvailable:
    case Threat.deviceBinding:
      return _Severity.medium;
    case Threat.devMode:
    case Threat.adbEnabled:
    case Threat.passcode:
    case Threat.deviceId:
    case Threat.obfuscationIssues:
    case Threat.systemVPN:
    case Threat.unsecureWiFi:
    case Threat.screenshot:
    case Threat.screenRecording:
    case Threat.timeSpoofing:
    case Threat.locationSpoofing:
      return _Severity.low;
  }
}

/// Pure policy decision: given a [threat] and the active [policy], what action
/// should the app take? Pure & total for exhaustive unit testing.
SecurityAction actionFor(Threat threat, ThreatPolicy policy) {
  switch (policy) {
    case ThreatPolicy.monitor:
      return SecurityAction.observe;
    case ThreatPolicy.warn:
      return _severityOf(threat) == _Severity.low
          ? SecurityAction.observe
          : SecurityAction.restrict;
    case ThreatPolicy.enforce:
      switch (_severityOf(threat)) {
        case _Severity.high:
          return SecurityAction.block;
        case _Severity.medium:
          return SecurityAction.restrict;
        case _Severity.low:
          return SecurityAction.observe;
      }
  }
}
