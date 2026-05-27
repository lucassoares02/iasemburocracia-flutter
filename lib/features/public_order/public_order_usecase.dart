import 'package:portal_assoc/core/services/response_model.dart';
import 'package:portal_assoc/features/public_order/public_order_repository.dart';

class PublicOrderUseCase {
  final PublicOrderRepository _repo;
  PublicOrderUseCase(this._repo);

  Future<ResponseModel> getCompanyMenu(int companyId) => _repo.getCompanyMenu(companyId);

  Future<ResponseModel> findClientByPhone(String phone, int companyId) =>
      _repo.findClientByPhone(phone, companyId);

  Future<ResponseModel> createClient(Map<String, dynamic> data) => _repo.createClient(data);

  Future<ResponseModel> updateClient(int id, Map<String, dynamic> data) =>
      _repo.updateClient(id, data);

  Future<ResponseModel> createOrder(Map<String, dynamic> data) => _repo.createOrder(data);

  Future<ResponseModel> getOrder(int orderId, {String? phone}) =>
      _repo.getOrder(orderId, phone: phone);

  Future<ResponseModel> reorderOrder(int orderId, {String? phone}) =>
      _repo.reorderOrder(orderId, phone: phone);

  Future<ResponseModel> findOrdersByPhone(int companyId, String phone) =>
      _repo.findOrdersByPhone(companyId, phone);
}
