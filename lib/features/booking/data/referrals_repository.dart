import '../../../core/api_client.dart';
import '../../../models/referral.dart';

class ReferralsRepository {
  ReferralsRepository(this._api);
  final ApiClient _api;

  Future<ReferralSummary> fetchSummary() async {
    final data = await _api.get('/api/referrals/summary') as Map<String, dynamic>;
    return ReferralSummary.fromJson(data);
  }
}
