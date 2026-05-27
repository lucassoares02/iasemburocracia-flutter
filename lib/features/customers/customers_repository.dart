import 'package:shared_preferences/shared_preferences.dart';
import 'package:portal_assoc/core/services/http_service.dart';
import 'package:portal_assoc/core/services/response_model.dart';
import 'customers_model.dart';

class CustomersRepository {
  final _http = HttpService();

  Future<int> _companyId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('company') ?? 0;
  }

  Future<ResponseModel> fetchAll({String search = '', String filter = 'all'}) async {
    final id = await _companyId();
    try {
      final params = <String, String>{};
      if (search.isNotEmpty) params['search'] = search;
      if (filter != 'all') params['filter'] = filter;
      final qs = params.isEmpty
          ? ''
          : '?${params.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&')}';
      final res = await _http.get('clients/company/$id$qs');
      if (res.success && res.data is List) {
        res.data = (res.data as List)
            .map((e) => CustomerModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return res;
    } catch (e) {
      rethrow;
    }
  }

  Future<ResponseModel> fetchSummary() async {
    final id = await _companyId();
    try {
      final res = await _http.get('clients/company/$id/summary');
      if (res.success && res.data is Map<String, dynamic>) {
        res.data = CustomerSummaryModel.fromJson(res.data as Map<String, dynamic>);
      }
      return res;
    } catch (e) {
      rethrow;
    }
  }

  Future<ResponseModel> fetchDetails(int clientId) async {
    try {
      final res = await _http.get('clients/$clientId/details');
      if (res.success && res.data is Map<String, dynamic>) {
        res.data = CustomerModel.fromJson(res.data as Map<String, dynamic>);
      }
      return res;
    } catch (e) {
      rethrow;
    }
  }

  Future<ResponseModel> createCustomer(Map<String, dynamic> data) async {
    final id = await _companyId();
    try {
      return await _http.post('clients', {...data, 'company_id': id});
    } catch (e) {
      rethrow;
    }
  }

  Future<ResponseModel> updateCustomer(int clientId, Map<String, dynamic> data) async {
    try {
      return await _http.patch('clients/$clientId', data);
    } catch (e) {
      rethrow;
    }
  }

  Future<ResponseModel> deleteCustomer(int clientId) async {
    try {
      return await _http.delete('clients/$clientId');
    } catch (e) {
      rethrow;
    }
  }
}
