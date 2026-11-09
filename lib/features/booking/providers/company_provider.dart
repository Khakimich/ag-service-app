import 'package:flutter/material.dart';
import '../data/company_repository.dart';
import '../../../models/company_profile.dart';
import '../../../models/specialist.dart';
import '../../../models/work_example.dart';

class CompanyProvider with ChangeNotifier {
  CompanyProvider(this._repo);
  final CompanyRepository _repo;

  CompanyProfile? _profile;
  CompanyProfile? get profile => _profile;

  List<Specialist> _specialists = [];
  List<Specialist> get specialists => _specialists;

  List<WorkExample> _workExamples = [];
  List<WorkExample> get workExamples => _workExamples;

  bool _loading = false;
  bool get loading => _loading;

  String? _error;
  String? get error => _error;

  Future<void> loadAll() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _repo.fetchProfile(),
        _repo.listSpecialists(),
        _repo.listWorkExamples(),
      ]);

      _profile = results[0] as CompanyProfile;
      _specialists = results[1] as List<Specialist>;
      _workExamples = results[2] as List<WorkExample>;
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
