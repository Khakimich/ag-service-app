import 'package:flutter/foundation.dart';

import '../../../models/booking_with_details.dart';
import '../data/booking_repository.dart';
import '../../../core/repair_push.dart';

class MyBookingsProvider extends ChangeNotifier {
  MyBookingsProvider(this._repo);
  final BookingRepository _repo;

  List<BookingWithDetails> _bookings = [];
  bool _loading = false;
  String? _error;

  List<BookingWithDetails> get activeBookings =>
      _bookings.where((b) => b.isActive).toList();
  List<BookingWithDetails> get archiveBookings =>
      _bookings.where((b) => !b.isActive).toList();
  bool get loading => _loading;
  String? get error => _error;

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _bookings = await _repo.myBookingsByUser();
      RepairPush.registerIds(_bookings.map((b) => b.id));
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void clear() {
    _bookings = [];
    _loading = false;
    _error = null;
    notifyListeners();
  }

  Future<bool> cancel(String bookingId) async {
    try {
      await _repo.cancelBooking(bookingId);
      await load();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<String?> delete(String bookingId) async {
    try {
      await _repo.deleteBooking(bookingId);
      await load();
      return null;
    } catch (e) {
      return e.toString();
    }
  }
}
