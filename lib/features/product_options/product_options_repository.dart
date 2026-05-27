import 'dart:typed_data';

import 'package:portal_assoc/core/services/http_service.dart';
import 'package:portal_assoc/core/services/public_http_service.dart';
import 'package:portal_assoc/core/services/response_model.dart';

import 'product_options_model.dart';

class ProductOptionsRepository {
  final _http = HttpService();
  final _public = PublicHttpService();

  Future<ResponseModel> findByProduct(int productId) async {
    final res = await _http.get('product-options/product/$productId');
    if (res.success && res.data is List) {
      res.data = (res.data as List)
          .map((e) => ProductOptionGroupModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return res;
  }

  Future<ResponseModel> findPublicByProduct(int productId) async {
    final res = await _public.get('public/product-options/$productId');
    if (res.success && res.data is List) {
      res.data = (res.data as List)
          .map((e) => ProductOptionGroupModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return res;
  }

  Future<ResponseModel> create(Map<String, dynamic> data) async {
    return await _http.post('product-options', data);
  }

  Future<ResponseModel> update(int groupId, Map<String, dynamic> data) async {
    return await _http.patch('product-options/$groupId', data);
  }

  Future<ResponseModel> remove(int groupId, int companyId) async {
    return await _http.delete('product-options/$groupId?company_id=$companyId');
  }

  Future<ResponseModel> reorder(int productId, int companyId, List<int> orderedIds) async {
    return await _http.patch('product-options/reorder/$productId', {
      'company_id': companyId,
      'ordered_ids': orderedIds,
    });
  }

  Future<ResponseModel> uploadItemImage(Uint8List bytes, String filename, String mimeType) async {
    return await _http.uploadFile('product-options/upload-item-image', bytes, filename, mimeType);
  }
}
