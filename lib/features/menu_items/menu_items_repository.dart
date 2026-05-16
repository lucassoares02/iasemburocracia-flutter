import 'package:shared_preferences/shared_preferences.dart';

import '../../core/services/response_model.dart';
import '../../core/services/http_service.dart';
import 'menu_items_model.dart';

class MenuItemsRepository {
  final httpService = HttpService();

  Future<ResponseModel> find(int id) async {
    try {
      ResponseModel response = await httpService.get("menu_items/$id");
      List list = response.data as List;
      final item = list.map((e) => MenuItemsModel.fromJson(e)).toList();
      response.data = item;
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<ResponseModel> findAll() async {
    final prefs = await SharedPreferences.getInstance();
    int? id = prefs.getInt('company') ?? 0;

    try {
      ResponseModel response = await httpService.get("menu_items/company/$id");
      List list = response.data as List;
      final item = list.map((e) => MenuItemsModel.fromJson(e)).toList();
      response.data = item;
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<ResponseModel> create(MenuItemsModel data) async {
    try {
      ResponseModel response = await httpService.post("menu_items", data.toJson());
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<ResponseModel> update(MenuItemsModel data) async {
    try {
      ResponseModel response = await httpService.patch("menu_items", data.toJson());
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<ResponseModel> delete(int id) async {
    try {
      ResponseModel response = await httpService.delete("menu_items/$id");
      return response;
    } catch (e) {
      rethrow;
    }
  }
}
