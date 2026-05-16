// Arquivo gerado automaticamente
import 'package:portal_assoc/features/menu_categories/menu_categories_model.dart';

import '../../core/services/response_model.dart';
import 'menu_categories_repository.dart';

class MenuCategoriesUseCase {
  final MenuCategoriesRepository repository;

  MenuCategoriesUseCase(this.repository);

  Future<ResponseModel> find(int id) async {
    return await repository.find(id);
  }

  Future<ResponseModel> findAll() async {
    return await repository.findAll();
  }

  Future<ResponseModel> create(MenuCategoriesModel data) async {
    return await repository.create(data);
  }

  Future<ResponseModel> update(MenuCategoriesModel data) async {
    return await repository.update(data);
  }

  Future<ResponseModel> delete(int id) async {
    return await repository.delete(id);
  }
}
