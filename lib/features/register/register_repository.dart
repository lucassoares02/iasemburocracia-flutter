import 'package:portal_assoc/features/register/companies_model.dart';
import '../../core/services/response_model.dart';
import '../../core/services/http_service.dart';
import 'register_model.dart';

class RegisterRepository {
  final httpService = HttpService();

  Future<ResponseModel> find(String cnpj) async {
    try {
      ResponseModel response = await httpService.get("cnpj/$cnpj");

      final item = CompaniesModel.fromJson(response.data);
      response.data = item;
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<ResponseModel> findAll() async {
    try {
      ResponseModel response = await httpService.get("register");
      List list = response.data as List;
      final item = list.map((e) => RegisterModel.fromJson(e)).toList();
      response.data = item;
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<ResponseModel> create(RegisterModel data) async {
    try {
      ResponseModel response = await httpService.post("register", data.toJson());
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<ResponseModel> createCompany(CompaniesModel data, int user, int type) async {
    Map<String, dynamic> dataSend = data.toJson();
    dataSend['user'] = user;
    dataSend['type'] = type;
    try {
      ResponseModel response = await httpService.post("companies", dataSend);
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<ResponseModel> createCompanyWithoutId(CompaniesModel data, int type) async {
    Map<String, dynamic> dataSend = data.toJson();
    dataSend['type'] = type;
    try {
      ResponseModel response = await httpService.post("companies/withoutid", dataSend);
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<ResponseModel> update(RegisterModel data) async {
    try {
      ResponseModel response = await httpService.patch("register", data.toJson());
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<ResponseModel> delete(int id) async {
    try {
      ResponseModel response = await httpService.delete("register/$id");
      return response;
    } catch (e) {
      rethrow;
    }
  }
}
