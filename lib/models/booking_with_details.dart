import 'service.dart';
import 'specialist.dart';
import 'user_car.dart';
import '../core/i18n.dart'; // AG_I18N1

class BookingWithDetails {
  BookingWithDetails({
    required this.id,
    required this.scheduledAt,
    required this.durationMinutes,
    required this.status,
    required this.customerName,
    required this.customerPhone,
    required this.service,
    required this.specialist,
    this.car,
  });

  final String id;
  final DateTime scheduledAt;
  final int durationMinutes;
  final String status;
  final String customerName;
  final String customerPhone;
  final Service service;
  final Specialist specialist;
  final UserCar? car;

  factory BookingWithDetails.fromJson(
    Map<String, dynamic> json,
  ) => BookingWithDetails(
    id: json['id'].toString(),
    scheduledAt: DateTime.parse(json['scheduled_at'] as String).toLocal(),
    durationMinutes: (json['duration_minutes'] as num?)?.toInt() ?? 30,
    status: json['status']?.toString() ?? 'pending',
    customerName: json['customer_name']?.toString() ?? '',
    customerPhone: json['customer_phone']?.toString() ?? '',
    service: Service.fromJson(json['service'] is Map /* AG_BKFIX1 */
        ? Map<String, dynamic>.from(json['service'] as Map)
        : {'id': '', 'title': tr('Услуга'), 'price_from': 0, 'duration_minutes': (json['duration_minutes'] as num?)?.toInt() ?? 30}),
    specialist: Specialist.fromJson(json['specialist'] is Map /* AG_BKFIX1 */
        ? Map<String, dynamic>.from(json['specialist'] as Map)
        : {'id': '', 'full_name': tr('Мастер AG Service')}),
    car:
        json['car'] == null
            ? null
            : UserCar.fromJson(Map<String, dynamic>.from(json['car'] as Map)),
  );

  bool get isActive =>
      status == 'pending' || status == 'confirmed' || status == 'in_progress';

  String get statusLabel {
    switch (status) {
      case 'pending':
        return tr('Ожидает');
      case 'confirmed':
        return tr('Подтверждена');
      case 'in_progress':
        return tr('В работе');
      case 'completed':
        return tr('Завершена');
      case 'cancelled':
        return tr('Отменена');
      default:
        return status;
    }
  }
}
