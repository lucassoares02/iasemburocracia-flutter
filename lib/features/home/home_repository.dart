import 'package:shared_preferences/shared_preferences.dart';

import '../../core/services/http_service.dart';
import '../../core/services/response_model.dart';
import 'home_model.dart';

class HomeRepository {
  final httpService = HttpService();

  Future<int> _companyId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('company') ?? 0;
  }

  Future<ResponseModel> getDashboard() async {
    var id = await _companyId();
    // Após login, a company pode ser persistida alguns instantes depois.
    // Faz pequenas tentativas para evitar carregar dashboard zerado.
    if (id <= 0) {
      for (var i = 0; i < 12; i++) {
        await Future.delayed(const Duration(milliseconds: 150));
        id = await _companyId();
        if (id > 0) break;
      }
    }
    if (id <= 0) {
      return ResponseModel(
        success: true,
        message: 'Company not selected yet',
        data: DashboardModel.fromJson({}),
      );
    }
    try {
      final response = await httpService.get("dashboard/$id");
      if (response.success && response.data is Map<String, dynamic>) {
        response.data =
            DashboardModel.fromJson(response.data as Map<String, dynamic>);
      }
      return response;
    } catch (e) {
      rethrow;
    }
  }
}
