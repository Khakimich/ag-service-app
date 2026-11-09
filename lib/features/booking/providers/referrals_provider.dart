import 'package:flutter/material.dart';
import '../data/referrals_repository.dart';
import '../../../models/referral.dart';

class ReferralsProvider with ChangeNotifier {
  ReferralsProvider(this._repo);
  final ReferralsRepository _repo;

  ReferralSummary? _summary;
  ReferralSummary? get summary => _summary;

  bool _loading = false;
  bool get loading => _loading;

  String? _error;
  String? get error => _error;

  Future<void> loadSummary() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      _summary = await _repo.fetchSummary();
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void clear() {
    _summary = null;
    _error = null;
    notifyListeners();
  }
}
