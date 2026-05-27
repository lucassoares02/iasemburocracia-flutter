import 'package:portal_assoc/core/services/public_http_service.dart';
import 'package:portal_assoc/core/services/response_model.dart';
import 'package:portal_assoc/features/public_order/public_order_model.dart';

class PublicOrderRepository {
  final _http = PublicHttpService();

  Future<ResponseModel> getCompanyMenu(int companyId) async {
    final res = await _http.get('public/company/$companyId');
    if (res.success && res.data is Map<String, dynamic>) {
      res.data = PublicCompanyPageModel.fromJson(res.data as Map<String, dynamic>);
    }
    return res;
  }

  Future<ResponseModel> findClientByPhone(String phone, int companyId) async {
    final encoded = Uri.encodeComponent(phone);
    final res = await _http.get('public/client?phone=$encoded&company_id=$companyId');
    if (res.success && res.data is Map<String, dynamic>) {
      res.data = PublicClientModel.fromJson(res.data as Map<String, dynamic>);
    }
    return res;
  }

  Future<ResponseModel> createClient(Map<String, dynamic> data) async {
    final res = await _http.post('public/clients', data);
    if (res.success && res.data is Map<String, dynamic>) {
      res.data = PublicClientModel.fromJson(res.data as Map<String, dynamic>);
    }
    return res;
  }

  Future<ResponseModel> updateClient(int id, Map<String, dynamic> data) async {
    final res = await _http.patch('public/clients/$id', data);
    if (res.success && res.data is Map<String, dynamic>) {
      res.data = PublicClientModel.fromJson(res.data as Map<String, dynamic>);
    }
    return res;
  }

  Future<ResponseModel> createOrder(Map<String, dynamic> data) async {
    return _http.post('public/orders', data);
  }

  Future<ResponseModel> reorderOrder(int orderId, {String? phone}) async {
    final qp = phone != null && phone.isNotEmpty
        ? '?phone=${Uri.encodeComponent(phone)}'
        : '';
    final res = await _http.get('public/orders/$orderId/reorder$qp');
    if (res.success && res.data is Map<String, dynamic>) {
      res.data = ReorderResultModel.fromJson(res.data as Map<String, dynamic>);
    }
    return res;
  }

  Future<ResponseModel> getOrder(int orderId, {String? phone}) async {
    final qp = phone != null && phone.isNotEmpty
        ? '?phone=${Uri.encodeComponent(phone)}'
        : '';
    final res = await _http.get('public/orders/$orderId$qp');
    if (res.success && res.data is Map<String, dynamic>) {
      res.data =
          PublicOrderDetailModel.fromJson(res.data as Map<String, dynamic>);
    }
    return res;
  }

  Future<ResponseModel> findOrdersByPhone(int companyId, String phone) async {
    final encoded = Uri.encodeComponent(phone);
    final res = await _http
        .get('public/orders?company_id=$companyId&phone=$encoded');
    if (res.success && res.data is List) {
      res.data = (res.data as List)
          .map((e) =>
              PublicOrderDetailModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return res;
  }

  // ── Order messages ────────────────────────────────────────────────────────

  Future<ResponseModel> getOrderMessages(int orderId, String phone) async {
    final encoded = Uri.encodeComponent(phone);
    return _http.get('public/orders/$orderId/messages?phone=$encoded');
  }

  Future<ResponseModel> sendPublicMessage(
    int orderId,
    String phone,
    String message, {
    String? senderName,
  }) async {
    return _http.post('public/orders/$orderId/messages', {
      'phone': phone,
      'message': message,
      if (senderName != null) 'sender_name': senderName,
    });
  }
}
