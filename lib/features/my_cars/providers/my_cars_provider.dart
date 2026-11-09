import 'package:flutter/foundation.dart';

import '../../../models/user_car.dart';
import '../data/my_cars_repository.dart';

class MyCarsProvider extends ChangeNotifier {
  MyCarsProvider(this._repo);
  final MyCarsRepository _repo;

  List<UserCar> _cars = [];
  bool _loading = false;
  String? _error;

  List<UserCar> get cars => _cars;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _cars = await _repo.listCars();
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void clear() {
    _cars = [];
    _loading = false;
    _error = null;
    notifyListeners();
  }

  Future<bool> addCar({
    required String make,
    required String model,
    String? vinCode,
    int? year,
    String? licensePlate,
  }) async {
    try {
      await _repo.createCar(
        make: make,
        model: model,
        vinCode: vinCode,
        year: year,
        licensePlate: licensePlate,
      );
      await load();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> updateCar({
    required String id,
    required String make,
    required String model,
    String? vinCode,
    int? year,
    String? licensePlate,
  }) async {
    try {
      await _repo.updateCar(
        id: id,
        make: make,
        model: model,
        vinCode: vinCode,
        year: year,
        licensePlate: licensePlate,
      );
      await load();
      return true;
    } catch (error, stackTrace) {
      debugPrint('========== UPDATE CAR ERROR ==========');
      debugPrint('ERROR: $error');
      debugPrint('STACK: $stackTrace');
      debugPrint('======================================');
      return false;
    }
  }

  Future<bool> deleteCar(String id) async {
    try {
      await _repo.deleteCar(id);
      await load();
      return true;
    } catch (_) {
      return false;
    }
  }
}
