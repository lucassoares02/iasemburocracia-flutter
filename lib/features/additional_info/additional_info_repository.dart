import 'package:shared_preferences/shared_preferences.dart';

import '../../core/services/response_model.dart';
import '../../core/services/http_service.dart';
import 'additional_info_model.dart';

class AdditionalInfoRepository {
  final httpService = HttpService();

  Future<ResponseModel> find(int id) async {
    try {
      ResponseModel response = await httpService.get("additional_info/$id");
      List list = response.data as List;
      final item = list.map((e) => AdditionalInfoModel.fromJson(e)).toList();
      response.data = item;
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<ResponseModel> findAll() async {
    final prefs = await SharedPreferences.getInstance();
    final companyId = prefs.getInt('company') ?? 0;
    try {
      ResponseModel response = await httpService.get("additional_info/company/$companyId");
      List list = response.data as List;
      final item = list.map((e) => AdditionalInfoModel.fromJson(e)).toList();
      response.data = item;
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<ResponseModel> create(AdditionalInfoModel data) async {
    final prefs = await SharedPreferences.getInstance();
    final companyId = prefs.getInt('company') ?? 0;

    data.companyId = companyId;
    try {
      ResponseModel response = await httpService.post("additional_info", data.toJson());
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<ResponseModel> update(AdditionalInfoModel data) async {
    final prefs = await SharedPreferences.getInstance();
    final companyId = prefs.getInt('company') ?? 0;

    data.companyId = companyId;
    try {
      ResponseModel response = await httpService.patch("additional_info/${data.id}", data.toJson());
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<ResponseModel> delete(int id) async {
    try {
      ResponseModel response = await httpService.delete("additional_info/$id");
      return response;
    } catch (e) {
      rethrow;
    }
  }
}
