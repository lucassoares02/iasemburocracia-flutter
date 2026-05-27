import 'package:shared_preferences/shared_preferences.dart';

import '../../core/services/http_service.dart';
import '../../core/services/public_http_service.dart';
import '../../core/services/response_model.dart';
import 'purchase_goal_model.dart';

class PurchaseGoalRepository {
  final _http = HttpService();
  final _public = PublicHttpService();

  Future<int> _companyId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('company') ?? 0;
  }

  Future<ResponseModel> findAll() async {
    final companyId = await _companyId();
    final res = await _http.get('purchase-goals/company/$companyId');
    if (res.success && res.data is List) {
      res.data = (res.data as List)
          .map((e) => PurchaseGoalModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return res;
  }

  Future<ResponseModel> create(PurchaseGoalModel model) async {
    final companyId = await _companyId();
    final res = await _http.post('purchase-goals', model.toCreateJson(companyId: companyId));
    if (res.success && res.data is Map<String, dynamic>) {
      res.data = PurchaseGoalModel.fromJson(res.data as Map<String, dynamic>);
    }
    return res;
  }

  Future<ResponseModel> update(PurchaseGoalModel model) async {
    final companyId = await _companyId();
    final res = await _http.patch('purchase-goals/${model.id}', model.toUpdateJson(companyId: companyId));
    if (res.success && res.data is Map<String, dynamic>) {
      res.data = PurchaseGoalModel.fromJson(res.data as Map<String, dynamic>);
    }
    return res;
  }

  Future<ResponseModel> toggle(int id, bool active) async {
    final companyId = await _companyId();
    return _http.patch('purchase-goals/$id/status', {
      'company_id': companyId,
      'is_active': active,
    });
  }

  Future<ResponseModel> delete(int id) async {
    final companyId = await _companyId();
    return _http.delete('purchase-goals/$id?company_id=$companyId');
  }

  /// Endpoint público chamado pelo checkout do `public_order_page`.
  /// [excludedProductIds] evita sugerir produtos já oferecidos/aceitos na sessão.
  Future<ResponseModel> suggest({
    required int companyId,
    required List<int> categoryIds,
    List<int> excludedProductIds = const [],
  }) async {
    final res = await _public.post('public/purchase-goals/suggest', {
      'company_id': companyId,
      'category_ids': categoryIds,
      'excluded_product_ids': excludedProductIds,
    });
    if (res.success && res.data is Map<String, dynamic>) {
      final suggestion = PurchaseGoalSuggestionModel.fromJson(res.data as Map<String, dynamic>);
      res.data = suggestion;
    }
    return res;
  }
}
