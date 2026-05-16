import 'package:shared_preferences/shared_preferences.dart';

import '../../core/services/response_model.dart';
import '../../core/services/http_service.dart';
import 'company_opening_hours_model.dart';

class CompanyOpeningHoursRepository {
  final httpService = HttpService();

  Future<ResponseModel> find(int id) async {
    try {
      ResponseModel response = await httpService.get("company_opening_hours/$id");
      List list = response.data as List;
      final item = list.map((e) => CompanyOpeningHoursModel.fromJson(e)).toList();
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
      ResponseModel response = await httpService.get("company_opening_hours/company/$id");
      List list = response.data as List;
      final item = list.map((e) => CompanyOpeningHoursModel.fromJson(e)).toList();
      response.data = item;
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<ResponseModel> create(CompanyOpeningHoursModel data) async {
    try {
      ResponseModel response = await httpService.post("company_opening_hours", data.toJson());
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<ResponseModel> update(CompanyOpeningHoursModel data) async {
    try {
      ResponseModel response = await httpService.patch("company_opening_hours", data.toJson());
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<ResponseModel> delete(int id) async {
    try {
      ResponseModel response = await httpService.delete("company_opening_hours/$id");
      return response;
    } catch (e) {
      rethrow;
    }
  }
}
