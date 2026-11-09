import 'package:flutter/foundation.dart';

import '../../../models/service.dart';
import '../../../models/slot.dart';
import '../../../models/specialist.dart';

class BookingFlowProvider extends ChangeNotifier {
  Service? _service;
  Specialist? _specialist;
  Slot? _slot;
  String _customerName = '';
  String _customerPhone = '';
  String? _carId;

  Service? get service => _service;
  Specialist? get specialist => _specialist;
  Slot? get slot => _slot;
  String get customerName => _customerName;
  String get customerPhone => _customerPhone;
  String? get carId => _carId;

  void selectService(Service service) {
    _service = service;
    _specialist = null;
    _slot = null;
    notifyListeners();
  }

  void selectSpecialist(Specialist specialist) {
    _specialist = specialist;
    _slot = null;
    notifyListeners();
  }

  void selectSlot(Slot slot) {
    _slot = slot;
    notifyListeners();
  }

  void selectCar(String? carId) {
    _carId = carId;
    notifyListeners();
  }

  void setCustomer({required String name, required String phone}) {
    _customerName = name;
    _customerPhone = phone;
    notifyListeners();
  }

  void reset() {
    _service = null;
    _specialist = null;
    _slot = null;
    _customerName = '';
    _customerPhone = '';
    _carId = null;
    notifyListeners();
  }
}
