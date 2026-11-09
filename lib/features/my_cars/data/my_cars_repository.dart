import '../../../core/api_client.dart';
import '../../../models/user_car.dart';

class MyCarsRepository {
  MyCarsRepository(this._api);
  final ApiClient _api;

  Future<List<UserCar>> listCars() async {
    final data = await _api.get('/api/cars') as Map<String, dynamic>;
    final raw = data['cars'] as List<dynamic>;
    return raw
        .map((e) => UserCar.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
  }

  Future<UserCar> createCar({
    required String make,
    required String model,
    String? vinCode,
    int? year,
    String? licensePlate,
  }) async {
    final data = await _api.post('/api/cars', {
      'make': make,
      'model': model,
      if (vinCode != null && vinCode.isNotEmpty) 'vincode': vinCode,
      if (year != null) 'year': year,
      if (licensePlate != null && licensePlate.isNotEmpty)
        'license_plate': licensePlate,
    }) as Map<String, dynamic>;
    return UserCar.fromJson(data['car'] as Map<String, dynamic>);
  }

  Future<UserCar> updateCar({
    required String id,
    required String make,
    required String model,
    String? vinCode,
    int? year,
    String? licensePlate,
  }) async {
    final data = await _api.patch('/api/cars/$id', {
      'make': make,
      'model': model,
      if (vinCode != null && vinCode.isNotEmpty) 'vincode': vinCode,
      if (year != null) 'year': year,
      if (licensePlate != null && licensePlate.isNotEmpty)
        'license_plate': licensePlate,
    }) as Map<String, dynamic>;
    return UserCar.fromJson(data['car'] as Map<String, dynamic>);
  }

  Future<void> deleteCar(String id) async {
    await _api.delete('/api/cars/$id');
  }
}
