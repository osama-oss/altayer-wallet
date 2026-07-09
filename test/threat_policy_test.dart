import 'package:banksync_app/core/security/threat_policy.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freerasp/freerasp.dart' show Threat;

void main() {
  test('monitor observes every threat and never acts', () {
    for (final t in Threat.values) {
      expect(actionFor(t, ThreatPolicy.monitor), SecurityAction.observe,
          reason: 'monitor must never block/restrict (${t.name})');
    }
  });

  test('enforce BLOCKS high-confidence tamper / active attack', () {
    for (final t in [
      Threat.appIntegrity,
      Threat.unofficialStore,
      Threat.hooks,
      Threat.debug,
      Threat.simulator,
      Threat.multiInstance,
    ]) {
      expect(actionFor(t, ThreatPolicy.enforce), SecurityAction.block,
          reason: '${t.name} should hard-block under enforce');
    }
  });

  test('enforce RESTRICTS (not blocks) root/jailbreak to avoid false-positive lockouts', () {
    expect(actionFor(Threat.privilegedAccess, ThreatPolicy.enforce), SecurityAction.restrict);
  });

  test('low-confidence signals never escalate beyond observe, even under enforce', () {
    for (final t in [
      Threat.systemVPN,
      Threat.unsecureWiFi,
      Threat.screenshot,
      Threat.screenRecording,
      Threat.passcode,
      // Dev mode / ADB are on for every internal test device — telemetry only,
      // otherwise shipping `warn` restricts the whole team.
      Threat.devMode,
      Threat.adbEnabled,
    ]) {
      expect(actionFor(t, ThreatPolicy.enforce), SecurityAction.observe,
          reason: '${t.name} is low-confidence telemetry only');
    }
  });

  test('warn restricts medium/high but only observes low-confidence signals', () {
    expect(actionFor(Threat.privilegedAccess, ThreatPolicy.warn), SecurityAction.restrict);
    expect(actionFor(Threat.appIntegrity, ThreatPolicy.warn), SecurityAction.restrict);
    expect(actionFor(Threat.systemVPN, ThreatPolicy.warn), SecurityAction.observe);
  });

  test('policy name parsing is case-insensitive and defaults to monitor', () {
    expect(ThreatPolicy.fromName('enforce'), ThreatPolicy.enforce);
    expect(ThreatPolicy.fromName('WARN'), ThreatPolicy.warn);
    expect(ThreatPolicy.fromName(null), ThreatPolicy.monitor);
    expect(ThreatPolicy.fromName('nonsense'), ThreatPolicy.monitor);
  });
}
