import '../../core/services/response_model.dart';
import 'orders_repository.dart';

class OrdersUseCase {
  final OrdersRepository repository;

  OrdersUseCase(this.repository);

  Future<ResponseModel> findAll() => repository.findAll();
  Future<ResponseModel> findToday() => repository.findToday();
  Future<ResponseModel> summary() => repository.summary();
  Future<ResponseModel> create(Map<String, dynamic> data) => repository.create(data);
  Future<ResponseModel> updateStatus(int orderId, int status, {String? cancelReason}) =>
      repository.updateStatus(orderId, status, cancelReason: cancelReason);
  Future<ResponseModel> delete(int id) => repository.delete(id);
  Future<ResponseModel> searchClients(String search) => repository.searchClients(search);
  Future<ResponseModel> getClient(int id) => repository.getClient(id);
  Future<ResponseModel> createClient(String name, String? phone, {Map<String, dynamic>? addressData}) =>
      repository.createClient(name, phone, addressData: addressData);
  Future<ResponseModel> updateClientAddress(int id, String name, String? phone, Map<String, dynamic> addressData) =>
      repository.updateClientAddress(id, name, phone, addressData);
}
