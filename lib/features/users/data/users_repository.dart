import 'dart:developer';
import 'package:flutter/services.dart';
import 'package:portal_assoc/core/services/http_service.dart';
import 'package:portal_assoc/core/services/response_model.dart';
import 'package:portal_assoc/features/users/data/user_model.dart';

class UsersRepository {
  final httpService = HttpService();

  Future<ResponseModel> getUsers() async {
    try {
      ResponseModel response = await httpService.get("users");
      List list = response.data as List;

      final item = list.map((e) => UserModel.fromJson(e)).toList();
      response.data = item;
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<ResponseModel> createUser(int? id, String? name, String? email, int? type, List<UserModel> selectedAssociates, bool? active) async {
    final data = {
      "id": id,
      "name": name,
      "email": email,
      "type": type,
      "active": active ?? false,
      "link": Uri.base.origin,
      "associates": selectedAssociates.map((e) => e.id).toList(),
    };
    try {
      ResponseModel response = await httpService.post("users", data);
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<ResponseModel> sendEmailUser(int id) async {
    final bigHtml = await rootBundle.loadString('assets/template_email.txt');
    final data = {
      "id": id,
      "link": Uri.base.origin,
      "subject": "E-mail de acesso a plataforma",
      "html": bigHtml,
      // "<div><span>Olá @name, segue acesso a plataforma do associados.<br><br>Link: <a href='@link'>@link</a><br>E-mail: @email<br>Senha: @password<br>Atenciosamente - Equipe Multishow.</span></div>",
      "text": "E-mail de acesso a plataforma portal dos associados.",
    };
    try {
      ResponseModel response = await httpService.post("send-email", data);
      return response;
    } catch (e) {
      rethrow;
    }
  }
}
