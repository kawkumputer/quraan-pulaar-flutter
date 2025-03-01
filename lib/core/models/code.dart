class Code {
  final String code;
  final bool isUsed;
  final int maxUses;
  final int currentUses;
  final String? deviceId;
  final DateTime? usedAt;

  Code({
    required this.code,
    this.isUsed = false,
    this.maxUses = 1,
    this.currentUses = 0,
    this.deviceId,
    this.usedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'isUsed': isUsed,
      'maxUses': maxUses,
      'currentUses': currentUses,
      'deviceId': deviceId,
      'usedAt': usedAt?.toIso8601String(),
    };
  }

  factory Code.fromJson(Map<String, dynamic> json) {
    return Code(
      code: json['code'],
      isUsed: json['isUsed'] ?? false,
      maxUses: json['maxUses'] ?? 1,
      currentUses: json['currentUses'] ?? 0,
      deviceId: json['deviceId'],
      usedAt: json['usedAt'] != null ? DateTime.parse(json['usedAt']) : null,
    );
  }

  bool get canBeUsed => !isUsed && currentUses < maxUses;
}
