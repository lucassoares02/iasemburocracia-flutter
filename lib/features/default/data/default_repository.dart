import 'package:portal_assoc/core/services/response_model.dart';
import 'package:portal_assoc/core/services/http_service.dart';
import 'package:portal_assoc/features/default/data/default_model.dart';

class DefaultRepository {
  final httpService = HttpService();

  Future<ResponseModel> defaultRepository() async {
    try {
      ResponseModel response = await httpService.get("default");
      List list = response.data as List;
      final item = list.map((e) => DefaultModel.fromJson(e)).toList();
      response.data = item;
      return response;
    } catch (e) {
      rethrow;
    }
  }
}
