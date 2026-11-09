import '../../../core/api_client.dart';
import '../../../models/company_profile.dart';
import '../../../models/specialist.dart';
import '../../../models/work_example.dart';

class CompanyRepository {
  CompanyRepository(this._api);
  final ApiClient _api;

  Future<CompanyProfile> fetchProfile() async {
    final data = await _api.get('/api/company/profile') as Map<String, dynamic>;
    return CompanyProfile.fromJson(data['profile'] as Map<String, dynamic>);
  }

  Future<List<Specialist>> listSpecialists() async {
    final data = await _api.get('/api/specialists') as Map<String, dynamic>;
    final raw = data['specialists'] as List<dynamic>;
    return raw
        .map((e) => Specialist.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
  }

  Future<List<WorkExample>> listWorkExamples() async {
    final data = await _api.get('/api/company/work-examples') as Map<String, dynamic>;
    final raw = data['work_examples'] as List<dynamic>;
    return raw
        .map((e) => WorkExample.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
  }
}
