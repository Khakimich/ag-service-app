class Booking {
  Booking({
    required this.id,
    required this.serviceId,
    required this.specialistId,
    required this.scheduledAt,
    required this.durationMinutes,
    required this.status,
  });

  final String id;
  final String serviceId;
  final String specialistId;
  final DateTime scheduledAt;
  final int durationMinutes;
  final String status;

  factory Booking.fromJson(Map<String, dynamic> json) => Booking(
        id: json['id'] as String,
        serviceId: json['service_id'] as String,
        specialistId: json['specialist_id'] as String,
        scheduledAt: DateTime.parse(json['scheduled_at'] as String),
        durationMinutes: json['duration_minutes'] as int,
        status: json['status'] as String,
      );
}
