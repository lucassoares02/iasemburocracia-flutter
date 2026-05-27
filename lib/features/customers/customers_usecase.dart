import 'package:portal_assoc/core/services/response_model.dart';
import 'customers_repository.dart';

class CustomersUseCase {
  final CustomersRepository _repo;
  CustomersUseCase(this._repo);

  Future<ResponseModel> fetchAll({String search = '', String filter = 'all'}) =>
      _repo.fetchAll(search: search, filter: filter);

  Future<ResponseModel> fetchSummary() => _repo.fetchSummary();

  Future<ResponseModel> fetchDetails(int clientId) => _repo.fetchDetails(clientId);

  Future<ResponseModel> createCustomer(Map<String, dynamic> data) =>
      _repo.createCustomer(data);

  Future<ResponseModel> updateCustomer(int clientId, Map<String, dynamic> data) =>
      _repo.updateCustomer(clientId, data);

  Future<ResponseModel> deleteCustomer(int clientId) => _repo.deleteCustomer(clientId);
}
