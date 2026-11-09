class Specialist {
  Specialist({
    required this.id,
    required this.fullName,
    required this.photoUrl,
    required this.specialization,
    required this.bio,
  });

  final String id;
  final String fullName;
  final String? photoUrl;
  final String? specialization;
  final String? bio;

  factory Specialist.fromJson(Map<String, dynamic> json) => Specialist(
        id: json['id'] as String,
        fullName: json['full_name'] as String,
        photoUrl: json['photo_url'] as String?,
        specialization: json['specialization'] as String?,
        bio: json['bio'] as String?,
      );
}
