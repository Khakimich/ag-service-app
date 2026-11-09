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
    this.friendReward = 100,
    this.referrerSignupReward = 0,
    this.referrerFirstVisitReward = 300,
  });

  final String referralCode;
  final int bonusPoints;
  final List<ReferralFriend> referrals;
  // AG_REFLVL1: суммы наград из настроек сервера
  final int friendReward;
  final int referrerSignupReward;
  final int referrerFirstVisitReward;
  int get referrerTotal => referrerSignupReward + referrerFirstVisitReward;

  factory ReferralSummary.fromJson(Map<String, dynamic> json) {
    final list = json['referrals'] as List? ?? [];
    final rw = json['rewards'] is Map ? json['rewards'] as Map : const {};
    int n(Object? v, int d) => v is num ? v.toInt() : int.tryParse('$v') ?? d;
    return ReferralSummary(
      friendReward: n(rw['friend'], 100),
      referrerSignupReward: n(rw['referrer_signup'], 0),
      referrerFirstVisitReward: n(rw['referrer_first_visit'], 300),
      referralCode: json['referral_code'] as String,
      bonusPoints: json['bonus_points'] as int? ?? 0,
      referrals: list
          .map((item) => ReferralFriend.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}
