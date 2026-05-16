// Arquivo gerado automaticamente
import 'package:portal_assoc/features/home/home_model.dart';

import '../../core/services/response_model.dart';
import 'home_repository.dart';

class HomeUseCase {
  final HomeRepository repository;

  HomeUseCase(this.repository);

  Future<ResponseModel> find(int id) async {
    return await repository.find(id);
  }

  Future<ResponseModel> findAll() async {
    return await repository.findAll();
  }

  Future<ResponseModel> create(HomeModel data) async {
    return await repository.create(data);
  }

  Future<ResponseModel> update(HomeModel data) async {
    return await repository.update(data);
  }

  Future<ResponseModel> delete(int id) async {
    return await repository.delete(id);
  }
}
