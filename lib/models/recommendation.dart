class RecommendationCar {
  const RecommendationCar({
    required this.id,
    required this.make,
    required this.model,
    this.year,
    this.licensePlate,
    this.vincode,
  });

  final String id;
  final String make;
  final String model;
  final int? year;
  final String? licensePlate;
  final String? vincode;

  factory RecommendationCar.fromJson(Map<String, dynamic> json) {
    return RecommendationCar(
      id: json['id']?.toString() ?? '',
      make: json['make']?.toString() ?? '',
      model: json['model']?.toString() ?? '',
      year:
          json['year'] is num
              ? (json['year'] as num).toInt()
              : int.tryParse(json['year']?.toString() ?? ''),
      licensePlate: json['license_plate']?.toString(),
      vincode: json['vincode']?.toString(),
    );
  }

  String get title {
    final parts = <String>[
      if (make.trim().isNotEmpty) make.trim(),
      if (model.trim().isNotEmpty) model.trim(),
      if (year != null) year.toString(),
    ];
    return parts.join(' ');
  }
}

class Recommendation {
  const Recommendation({
    required this.id,
    required this.text,
    required this.priority,
    required this.status,
    required this.authorName,
    required this.createdAt,
    this.bookingId,
    this.carId,
    this.mileage,
    this.updatedAt,
    this.car,
  });

  final String id;
  final String? bookingId;
  final String? carId;
  final int? mileage;
  final String text;
  final String priority;
  final String status;
  final String authorName;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final RecommendationCar? car;

  factory Recommendation.fromJson(Map<String, dynamic> json) {
    final rawCar = json['car'];

    return Recommendation(
      id: json['id']?.toString() ?? '',
      bookingId: json['booking_id']?.toString(),
      carId: json['car_id']?.toString(),
      mileage:
          json['mileage'] is num
              ? (json['mileage'] as num).toInt()
              : int.tryParse(json['mileage']?.toString() ?? ''),
      text: json['text']?.toString() ?? '',
      priority: json['priority']?.toString() ?? 'normal',
      status: json['status']?.toString() ?? 'active',
      authorName: json['author_name']?.toString() ?? '',
      createdAt:
          DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      updatedAt: DateTime.tryParse(json['updated_at']?.toString() ?? ''),
      car:
          rawCar is Map
              ? RecommendationCar.fromJson(Map<String, dynamic>.from(rawCar))
              : null,
    );
  }

  Recommendation copyWith({String? status}) {
    return Recommendation(
      id: id,
      bookingId: bookingId,
      carId: carId,
      mileage: mileage,
      text: text,
      priority: priority,
      status: status ?? this.status,
      authorName: authorName,
      createdAt: createdAt,
      updatedAt: updatedAt,
      car: car,
    );
  }
}
