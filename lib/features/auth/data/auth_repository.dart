import 'dart:developer';
import 'package:portal_assoc/core/services/http_service.dart';
import 'package:portal_assoc/core/services/response_model.dart';
import 'package:portal_assoc/features/auth/data/associate_model.dart';
import 'package:portal_assoc/features/auth/data/user_model.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';

class AuthRepository {
  final httpService = HttpService();

  Future<UserModel> login(String email, String password) async {
    try {
      ResponseModel response = await httpService.post("signin", {"email": email, "password": password});
      return UserModel.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  Future<ResponseModel> getCompanies() async {
    try {
      ResponseModel response = await httpService.get("companies");

      List list = response.data as List;
      final item = list.map((e) => CompaniesModel.fromJson(e)).toList();
      response.data = item;
      return response;
    } catch (e) {
      log("Error Get Associates by User: $e");
      rethrow;
    }
  }

  Future<ResponseModel> getOrdersItems() async {
    final prefs = await SharedPreferences.getInstance();
    final company = prefs.getInt('company') ?? 0;
    try {
      ResponseModel response = await httpService.get("count/orders-items/$company");

      response.data = response.data;
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<ResponseModel> sendEmailForgotPassword(String email) async {
    final bigHtml = await rootBundle.loadString('assets/template_email.txt');

    final data = {
      "email": email,
      "link": Uri.base.origin,
      "subject": "Recuperação de Senha",
      "html": bigHtml,
      // "<div><span>Olá @name, segue a senha para acesso a plataforma do associados.<br><br>Link: <a href='@link'>@link</a><br>E-mail: @email<br>Nova senha: @password<br>Atenciosamente - Equipe Multishow.</span></div>",
      "text": "E-mail de recuperação de senha.",
    };
    try {
      ResponseModel response = await httpService.post("send-email", data);
      return response;
    } catch (e) {
      rethrow;
    }
  }
}
