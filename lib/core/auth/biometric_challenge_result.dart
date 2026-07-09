class BiometricChallengeResult {
  const BiometricChallengeResult({
    required this.challengeId,
    required this.nonce,
    required this.expiresInSeconds,
  });

  final String challengeId;
  final String nonce;
  final int expiresInSeconds;

  factory BiometricChallengeResult.fromJson(Map<String, dynamic> json) {
    return BiometricChallengeResult(
      challengeId: json['challengeId']?.toString() ?? '',
      nonce: json['nonce']?.toString() ?? '',
      expiresInSeconds: json['expiresInSeconds'] is int
          ? json['expiresInSeconds'] as int
          : int.tryParse(json['expiresInSeconds']?.toString() ?? '') ?? 60,
    );
  }
}
