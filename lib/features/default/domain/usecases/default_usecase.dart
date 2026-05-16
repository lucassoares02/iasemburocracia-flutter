import 'package:portal_assoc/core/services/response_model.dart';
import 'package:portal_assoc/features/default/data/default_repository.dart';

class DefaultUsecase {
  final DefaultRepository repository;

  DefaultUsecase(this.repository);

  Future<ResponseModel> defaultUseCase() {
    return repository.defaultRepository();
  }
}
