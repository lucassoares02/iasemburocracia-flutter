import 'dart:typed_data';

import 'package:portal_assoc/core/services/http_service.dart';
import 'package:portal_assoc/core/services/response_model.dart';
import 'package:portal_assoc/features/promotions/promotions_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PromotionsRepository {
  final _http = HttpService();

  Future<int> _companyId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('company') ?? 0;
  }

  Future<ResponseModel> findAll() async {
    final companyId = await _companyId();
    final res = await _http.get('promotions/company/$companyId');
    if (res.success && res.data is List) {
      res.data = (res.data as List)
          .map((e) => PromotionModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return res;
  }

  Future<ResponseModel> create(PromotionModel model) async {
    final companyId = await _companyId();
    return _http.post('promotions', {
      ...model.toJson(),
      'company_id': companyId,
    });
  }

  Future<ResponseModel> update(PromotionModel model) async {
    final companyId = await _companyId();
    return _http.patch('promotions/${model.id}', {
      ...model.toJson(),
      'company_id': companyId,
    });
  }

  Future<ResponseModel> toggle(int id, bool active) async {
    final companyId = await _companyId();
    return _http.patch('promotions/$id/status', {
      'company_id': companyId,
      'active': active,
    });
  }

  Future<ResponseModel> delete(int id) async {
    final companyId = await _companyId();
    return _http.delete('promotions/$id?company_id=$companyId');
  }

  Future<ResponseModel> uploadImage(
      Uint8List bytes, String filename, String mimeType) async {
    return _http.uploadFile(
        'menu_items/upload-image', bytes, filename, mimeType);
  }
}
