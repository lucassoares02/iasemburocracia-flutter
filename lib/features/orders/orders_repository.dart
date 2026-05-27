import 'package:shared_preferences/shared_preferences.dart';

import '../../core/services/response_model.dart';
import '../../core/services/http_service.dart';
import 'orders_model.dart';

class OrdersRepository {
  final httpService = HttpService();

  Future<int> _companyId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('company') ?? 0;
  }

  // ── Orders ────────────────────────────────────────────────────────────────

  Future<ResponseModel> findAll() async {
    final id = await _companyId();
    try {
      final response = await httpService.get("orders/company/$id");
      final list = response.data as List;
      response.data = list.map((e) => OrderModel.fromJson(e)).toList();
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<ResponseModel> findToday() async {
    final id = await _companyId();
    try {
      final response = await httpService.get("orders/today/$id");
      final list = response.data as List;
      response.data = list.map((e) => OrderModel.fromJson(e)).toList();
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<ResponseModel> summary() async {
    final id = await _companyId();
    try {
      final response = await httpService.get("orders/summary/$id");
      response.data = OrderSummaryModel.fromJson(response.data as Map<String, dynamic>);
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<ResponseModel> create(Map<String, dynamic> data) async {
    final id = await _companyId();
    try {
      final response = await httpService.post("orders", {...data, 'company_id': id});
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<ResponseModel> updateStatus(int orderId, int status, {String? cancelReason}) async {
    try {
      final response = await httpService.patch(
        "orders/$orderId/status",
        {'status': status, if (cancelReason != null) 'cancel_reason': cancelReason},
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<ResponseModel> delete(int id) async {
    try {
      return await httpService.delete("orders/$id");
    } catch (e) {
      rethrow;
    }
  }

  // ── Order messages ────────────────────────────────────────────────────────

  Future<ResponseModel> getOrderMessages(int orderId) async {
    return httpService.get("orders/$orderId/messages");
  }

  Future<ResponseModel> sendAdminMessage(int orderId, String message) async {
    return httpService.post(
      "orders/$orderId/messages",
      {'message': message, 'sender_name': 'Empresa'},
    );
  }

  Future<ResponseModel> markOrderMessagesRead(int orderId) async {
    return httpService.patch("orders/$orderId/messages/read", {});
  }

  // ── Clients ───────────────────────────────────────────────────────────────

  Future<ResponseModel> searchClients(String search) async {
    final id = await _companyId();
    try {
      final response = await httpService.get("clients/company/$id?search=${Uri.encodeComponent(search)}");
      final list = response.data as List;
      response.data = list.map((e) => ClientModel.fromJson(e)).toList();
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<ResponseModel> getClient(int id) async {
    try {
      final response = await httpService.get("clients/$id");
      if (response.success && response.data is Map<String, dynamic>) {
        response.data = ClientModel.fromJson(response.data as Map<String, dynamic>);
      }
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<ResponseModel> createClient(String name, String? phone, {Map<String, dynamic>? addressData}) async {
    final id = await _companyId();
    try {
      final response = await httpService.post("clients", {
        'company_id': id,
        'name': name,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
        if (addressData != null) ...addressData,
      });
      if (response.success && response.data is Map<String, dynamic>) {
        response.data = ClientModel.fromJson(response.data as Map<String, dynamic>);
      }
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<ResponseModel> updateClientAddress(int id, String name, String? phone, Map<String, dynamic> addressData) async {
    try {
      final response = await httpService.patch("clients/$id", {
        'name': name,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
        ...addressData,
      });
      if (response.success && response.data is Map<String, dynamic>) {
        response.data = ClientModel.fromJson(response.data as Map<String, dynamic>);
      }
      return response;
    } catch (e) {
      rethrow;
    }
  }
}
