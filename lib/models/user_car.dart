class UserCar {
  UserCar({
    required this.id,
    required this.make,
    required this.model,
    this.vinCode,
    this.year,
    this.licensePlate,
    this.createdAt,
  });

  final String id;
  final String make;
  final String model;
  final String? vinCode;
  final int? year;
  final String? licensePlate;
  final DateTime? createdAt;

  factory UserCar.fromJson(Map<String, dynamic> json) => UserCar(
        id: json['id'] as String,
        make: json['make'] as String,
        model: json['model'] as String,
        vinCode: json['vincode'] as String?,
        year: json['year'] as int?,
        licensePlate: json['license_plate'] as String?,
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'] as String).toLocal()
            : null,
      );

  String get displayName {
    if (year != null) return '$make $model, $year';
    return '$make $model';
  }

  String get title => '$make $model';
}
