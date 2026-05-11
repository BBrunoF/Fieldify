import '../data/repositories/home_repository.dart';

class HomeController {
  final HomeRepository _repository;

  HomeController({HomeRepository? repository})
      : _repository = repository ?? HomeRepository();

  Future<bool> loadIsProfessional() => _repository.fetchIsProfessional();
}
