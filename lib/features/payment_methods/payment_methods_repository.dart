import 'package:shared_preferences/shared_preferences.dart';

import '../../core/services/response_model.dart';
import '../../core/services/http_service.dart';
import 'payment_methods_model.dart';

class PaymentMethodsRepository {
  final httpService = HttpService();

  Future<ResponseModel> find(int id) async {
    try {
      ResponseModel response = await httpService.get("payment_methods/$id");
      List list = response.data as List;
      final item = list.map((e) => PaymentMethodsModel.fromJson(e)).toList();
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
      ResponseModel response = await httpService.get("payment_methods/company/$id");
      List list = response.data as List;
      final item = list.map((e) => PaymentMethodsModel.fromJson(e)).toList();
      response.data = item;
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<ResponseModel> create(PaymentMethodsModel data) async {
    try {
      ResponseModel response = await httpService.post("payment_methods", data.toJson());
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<ResponseModel> update(PaymentMethodsModel data) async {
    try {
      ResponseModel response = await httpService.patch("payment_methods", data.toJson());
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<ResponseModel> delete(int id) async {
    try {
      ResponseModel response = await httpService.delete("payment_methods/$id");
      return response;
    } catch (e) {
      rethrow;
    }
  }
}
