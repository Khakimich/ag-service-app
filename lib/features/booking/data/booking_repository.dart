import 'package:flutter/foundation.dart';
import '../../../core/api_client.dart';
import '../../../core/repair_push.dart';
import '../../../models/booking.dart';
import '../../../models/booking_with_details.dart';
import '../../../models/service.dart';
import '../../../models/slot.dart';
import '../../../models/specialist.dart';
import '../../../models/work_example.dart';

class BookingRepository {
  BookingRepository(this._api);
  final ApiClient _api;

  Future<BookingSettings> bookingSettings() async {
    final data =
        await _api.get('/api/company/booking-settings') as Map<String, dynamic>;

    return BookingSettings.fromJson(data);
  }

  Future<List<Service>> listServices() async {
    final data = await _api.get('/api/services') as Map<String, dynamic>;
    final raw = data['services'] as List<dynamic>;
    return raw
        .map((e) => Service.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
  }

  Future<ServiceDetail> serviceDetail(String id) async {
    final data = await _api.get('/api/services/$id') as Map<String, dynamic>;
    final service = Service.fromJson(data['service'] as Map<String, dynamic>);
    final specialists = (data['specialists'] as List<dynamic>)
        .map((e) => Specialist.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
    final workExamples = (data['work_examples'] as List<dynamic>? ?? [])
        .map((e) => WorkExample.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
    return ServiceDetail(
      service: service,
      specialists: specialists,
      workExamples: workExamples,
    );
  }

  Future<List<Slot>> slots({
    required String specialistId,
    required DateTime date,
    required int durationMinutes,
  }) async {
    final dateStr = _formatDate(date);
    final data =
        await _api.get(
              '/api/specialists/$specialistId/slots',
              query: {'date': dateStr, 'duration': durationMinutes},
            )
            as Map<String, dynamic>;
    final raw = data['slots'] as List<dynamic>;
    debugPrint('===== SLOTS API DEBUG =====');
    debugPrint('specialistId: $specialistId');
    debugPrint('date: $dateStr');
    debugPrint('duration: $durationMinutes');
    debugPrint('count: ${raw.length}');
    for (final item in raw) {
      debugPrint('SLOT: $item');
    }
    debugPrint('===========================');
    return raw
        .map((e) => Slot.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
  }

  Future<Booking> createBooking({
    required String serviceId,
    required String specialistId,
    required DateTime scheduledAt,
    required String customerName,
    required String customerPhone,
    String? carId,
  }) async {
    final data =
        await _api.post('/api/bookings', {
              'service_id': serviceId,
              'specialist_id': specialistId,
              'scheduled_at': scheduledAt.toUtc().toIso8601String(),
              'customer_name': customerName,
              'customer_phone': customerPhone,
              if (carId != null) 'car_id': carId,
            })
            as Map<String, dynamic>;
    final booking = Booking.fromJson(data['booking'] as Map<String, dynamic>);
    RepairPush.sync();
    return booking;
  }

  Future<List<BookingWithDetails>> myBookingsByUser() async {
    final data = await _api.get('/api/bookings/mine') as Map<String, dynamic>;
    final raw = data['bookings'] as List<dynamic>;

    debugPrint('========== MY BOOKINGS API ==========');
    for (final item in raw) {
      debugPrint('BOOKING: $item');
    }
    debugPrint('=====================================');

    return raw
        .map((e) => BookingWithDetails.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
  }

  Future<void> cancelBooking(String id) async {
    await _api.patch('/api/bookings/$id/cancel', {});
  }

  Future<void> rescheduleBooking(String id, DateTime newScheduledAt) async {
    await _api.patch('/api/bookings/$id/reschedule', {
      'scheduled_at': newScheduledAt.toUtc().toIso8601String(),
    });
  }

  Future<void> deleteBooking(String id) async {
    await _api.patch('/api/bookings/$id/remove', {});
  }

  /// Booking slots are wall-clock time in Asia/Yekaterinburg (UTC+5).
  ///
  /// Example:
  /// selected 17:30 Ekaterinburg -> 12:30 UTC.
  DateTime _ekaterinburgToUtc(DateTime value) {
    final ekaterinburgWallClockAsUtc = DateTime.utc(
      value.year,
      value.month,
      value.day,
      value.hour,
      value.minute,
      value.second,
      value.millisecond,
      value.microsecond,
    );

    return ekaterinburgWallClockAsUtc.subtract(const Duration(hours: 5));
  }

  String _formatDate(DateTime d) {
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '${d.year}-$m-$day';
  }
}

class ServiceDetail {
  ServiceDetail({
    required this.service,
    required this.specialists,
    required this.workExamples,
  });
  final Service service;
  final List<Specialist> specialists;
  final List<WorkExample> workExamples;
}

class BookingSettings {
  const BookingSettings({
    required this.bookingAvailable,
    required this.onlineBookingEnabled,
    required this.maintenanceMode,
    required this.message,
    required this.slotStepMinutes,
    required this.bookingDaysAhead,
    required this.allowCustomerCancel,
    required this.allowWithoutSpecialist,
  });

  final bool bookingAvailable;
  final bool onlineBookingEnabled;
  final bool maintenanceMode;
  final String message;
  final int slotStepMinutes;
  final int bookingDaysAhead;
  final bool allowCustomerCancel;
  final bool allowWithoutSpecialist;

  factory BookingSettings.fromJson(Map<String, dynamic> json) {
    return BookingSettings(
      bookingAvailable: json['booking_available'] == true,

      onlineBookingEnabled: json['online_booking_enabled'] == true,

      maintenanceMode: json['maintenance_mode'] == true,

      message: (json['message'] ?? '').toString(),

      slotStepMinutes: (json['slot_step_minutes'] as num?)?.toInt() ?? 30,

      bookingDaysAhead: (json['booking_days_ahead'] as num?)?.toInt() ?? 30,

      allowCustomerCancel: json['allow_customer_cancel'] != false,

      allowWithoutSpecialist: json['allow_without_specialist'] == true,
    );
  }
}
