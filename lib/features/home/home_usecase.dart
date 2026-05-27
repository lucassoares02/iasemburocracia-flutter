import '../../core/services/response_model.dart';
import 'home_repository.dart';

class HomeUseCase {
  final HomeRepository repository;

  HomeUseCase(this.repository);

  Future<ResponseModel> getDashboard() => repository.getDashboard();
}
