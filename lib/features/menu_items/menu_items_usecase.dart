// Arquivo gerado automaticamente
import 'package:portal_assoc/features/menu_items/menu_items_model.dart';

import '../../core/services/response_model.dart';
import 'menu_items_repository.dart';

class MenuItemsUseCase {
  final MenuItemsRepository repository;

  MenuItemsUseCase(this.repository);

  Future<ResponseModel> find(int id) async {
    return await repository.find(id);
  }

  Future<ResponseModel> findAll() async {
    return await repository.findAll();
  }

  Future<ResponseModel> create(MenuItemsModel data) async {
    return await repository.create(data);
  }

  Future<ResponseModel> update(MenuItemsModel data) async {
    return await repository.update(data);
  }

  Future<ResponseModel> delete(int id) async {
    return await repository.delete(id);
  }
}
