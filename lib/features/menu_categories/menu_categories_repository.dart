import '../../core/services/response_model.dart';
import '../../core/services/http_service.dart';
import 'menu_categories_model.dart';

class MenuCategoriesRepository {
  final httpService = HttpService();

  Future<ResponseModel> find(int id) async {
    try {
      ResponseModel response = await httpService.get("menu_categories/$id");
      List list = response.data as List;
      final item = list.map((e) => MenuCategoriesModel.fromJson(e)).toList();
      response.data = item;
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<ResponseModel> findAll() async {
    try {
      ResponseModel response = await httpService.get("menu_categories");
      List list = response.data as List;
      final item = list.map((e) => MenuCategoriesModel.fromJson(e)).toList();
      response.data = item;
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<ResponseModel> findByCompany(int companyId) async {
    try {
      ResponseModel response =
          await httpService.get("menu_categories/company/$companyId");
      List list = response.data as List;
      final item = list.map((e) => MenuCategoriesModel.fromJson(e)).toList();
      response.data = item;
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<ResponseModel> create(MenuCategoriesModel data) async {
    try {
      ResponseModel response = await httpService.post("menu_categories", data.toJson());
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<ResponseModel> update(MenuCategoriesModel data) async {
    try {
      ResponseModel response = await httpService.patch("menu_categories", data.toJson());
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<ResponseModel> delete(int id) async {
    try {
      ResponseModel response = await httpService.delete("menu_categories/$id");
      return response;
    } catch (e) {
      rethrow;
    }
  }
}
