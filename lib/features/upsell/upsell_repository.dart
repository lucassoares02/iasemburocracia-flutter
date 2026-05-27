import 'package:shared_preferences/shared_preferences.dart';
import '../../core/services/http_service.dart';
import '../../core/services/response_model.dart';
import 'upsell_model.dart';

class UpsellRepository {
  final _http = HttpService();

  Future<int> _companyId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('company') ?? 0;
  }

  Future<ResponseModel> findAll() async {
    final companyId = await _companyId();
    final res = await _http.get('upsell/company/$companyId');
    if (res.success && res.data is List) {
      res.data = (res.data as List)
          .map((e) => UpsellRuleModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return res;
  }

  Future<ResponseModel> create(UpsellRuleModel model) async {
    final companyId = await _companyId();
    return _http.post('upsell', {...model.toJson(), 'company_id': companyId});
  }

  Future<ResponseModel> update(UpsellRuleModel model) async {
    final companyId = await _companyId();
    return _http.patch('upsell/${model.id}', {...model.toJson(), 'company_id': companyId});
  }

  Future<ResponseModel> toggle(int id, bool active) async {
    final companyId = await _companyId();
    return _http.patch('upsell/$id/status', {'company_id': companyId, 'active': active});
  }

  Future<ResponseModel> duplicate(int id) async {
    final companyId = await _companyId();
    return _http.post('upsell/$id/duplicate', {'company_id': companyId});
  }

  Future<ResponseModel> delete(int id) async {
    final companyId = await _companyId();
    return _http.delete('upsell/$id?company_id=$companyId');
  }
}
