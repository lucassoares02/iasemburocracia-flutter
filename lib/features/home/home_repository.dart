import '../../core/services/response_model.dart';
import '../../core/services/http_service.dart';
import 'home_model.dart';

class HomeRepository {
  final httpService = HttpService();

  Future<ResponseModel> find(int id) async {
    try {
      ResponseModel response = await httpService.get("home/$id");
      List list = response.data as List;
      final item = list.map((e) => HomeModel.fromJson(e)).toList();
      response.data = item;
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<ResponseModel> findAll() async {
    try {
      ResponseModel response = await httpService.get("companies");
      List list = response.data as List;
      final item = list.map((e) => HomeModel.fromJson(e)).toList();
      response.data = item;
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<ResponseModel> create(HomeModel data) async {
    try {
      ResponseModel response = await httpService.post("home", data.toJson());
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<ResponseModel> update(HomeModel data) async {
    try {
      ResponseModel response = await httpService.patch("home", data.toJson());
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<ResponseModel> delete(int id) async {
    try {
      ResponseModel response = await httpService.delete("home/$id");
      return response;
    } catch (e) {
      rethrow;
    }
  }
}
