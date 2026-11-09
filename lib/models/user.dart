class User {
  User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.phone,
    this.bonusPoints = 0,
    this.avatarUrl,
    this.birthDate,
  });

  final String id;
  final String name;
  final String email;
  final String? phone;
  final String role;
  final int bonusPoints;
  final String? avatarUrl;
  final String? birthDate;

  factory User.fromJson(Map<String, dynamic> json) => User(
    id: json['id'] as String,
    name: json['name'] as String,
    email: json['email'] as String,
    phone: json['phone'] as String?,
    role: json['role'] as String,
    bonusPoints: json['bonus_points'] as int? ?? 0,
    avatarUrl: json['avatar_url'] as String?,
    birthDate: json['birth_date'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'phone': phone,
    'role': role,
    'bonus_points': bonusPoints,
    'avatar_url': avatarUrl,
    'birth_date': birthDate,
  };
}
