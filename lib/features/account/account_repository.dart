import 'package:portal_assoc/features/register/companies_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/services/response_model.dart';
import '../../core/services/http_service.dart';
import 'account_model.dart';

class AccountRepository {
  final httpService = HttpService();

  Future<ResponseModel> find() async {
    try {
      ResponseModel response = await httpService.get("account");
      response.data = AccountModel.fromJson(response.data);
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<ResponseModel> findCompanyId() async {
    final prefs = await SharedPreferences.getInstance();
    final company = prefs.getInt('company');

    try {
      ResponseModel response = await httpService.get("companies/$company");
      List list = response.data as List;
      final item = list.map((e) => CompaniesModel.fromJson(e)).toList();
      response.data = item;
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<ResponseModel> update(AccountModel data) async {
    try {
      ResponseModel response = await httpService.patch("account", data.toJson());
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<ResponseModel> updateCompany(CompaniesModel data) async {
    try {
      ResponseModel response = await httpService.patch("companies", data.toJson());
      return response;
    } catch (e) {
      rethrow;
    }
  }
}
