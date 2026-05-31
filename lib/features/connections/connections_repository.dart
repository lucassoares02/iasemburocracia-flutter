import 'package:portal_assoc/features/connections/models/evolution_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/services/response_model.dart';
import '../../core/services/http_service.dart';
import 'connections_model.dart';

class ConnectionsRepository {
  final httpService = HttpService();

  Future<ResponseModel> find(int id) async {
    try {
      ResponseModel response = await httpService.get("connections/$id");
      List list = response.data as List;
      response.data = list.map((e) => ConnectionsModel.fromJson(e)).toList();
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<ResponseModel> findAll() async {
    final prefs = await SharedPreferences.getInstance();
    final company = prefs.getInt('company');
    try {
      ResponseModel response = await httpService.get("connections/all/$company");
      List list = response.data as List;
      response.data = list.map((e) => ConnectionsModel.fromJson(e)).toList();
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<ResponseModel> create(ConnectionsModel data) async {
    try {
      ResponseModel response = await httpService.post("connections", data.toJson());
      response.data = EvolutionModel.fromJson(response.data);
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<ResponseModel> update(ConnectionsModel data) async {
    try {
      ResponseModel response = await httpService.patch("connections", data.toJson());
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<ResponseModel> delete(int id, String instance) async {
    try {
      ResponseModel response = await httpService.delete("connections/$id/$instance");
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<ResponseModel> testConnection(String instance) async {
    try {
      return await httpService.get("connections/test/$instance");
    } catch (e) {
      rethrow;
    }
  }

  Future<ResponseModel> getQrCode(String instance) async {
    try {
      return await httpService.get("connections/qrcode/$instance");
    } catch (e) {
      rethrow;
    }
  }

  Future<ResponseModel> getConnectionStatus(String instance) async {
    try {
      return await httpService.get("connections/status/$instance");
    } catch (e) {
      rethrow;
    }
  }

  Future<ResponseModel> updateWorkflow(int id) async {
    try {
      return await httpService.post("connections/$id/update-workflow", {});
    } catch (e) {
      rethrow;
    }
  }
}
