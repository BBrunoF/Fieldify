import '../services/home_service.dart';

class HomeRepository {
  final HomeService _service;

  HomeRepository({HomeService? service}) : _service = service ?? HomeService();

  Future<bool> fetchIsProfessional() async {
    try {
      return await _service.fetchIsProfessional();
    } catch (_) {
      return false;
    }
  }
}
