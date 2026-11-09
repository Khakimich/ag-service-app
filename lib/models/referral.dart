class ReferralFriend {
  ReferralFriend({
    required this.id,
    required this.status,
    required this.createdAt,
    required this.refereeName,
    required this.refereeRegisteredAt,
  });

  final String id;
  final String status; // 'registered', 'first_visit'
  final DateTime createdAt;
  final String refereeName;
  final DateTime refereeRegisteredAt;

  factory ReferralFriend.fromJson(Map<String, dynamic> json) => ReferralFriend(
        id: json['id'] as String,
        status: json['status'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
        refereeName: json['referee_name'] as String,
        refereeRegisteredAt: DateTime.parse(json['referee_registered_at'] as String),
      );
}

class ReferralSummary {
  ReferralSummary({
    required this.referralCode,
    required this.bonusPoints,
    required this.referrals,
  });

  final String referralCode;
  final int bonusPoints;
  final List<ReferralFriend> referrals;

  factory ReferralSummary.fromJson(Map<String, dynamic> json) {
    final list = json['referrals'] as List? ?? [];
    return ReferralSummary(
      referralCode: json['referral_code'] as String,
      bonusPoints: json['bonus_points'] as int? ?? 0,
      referrals: list
          .map((item) => ReferralFriend.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}
