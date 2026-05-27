import 'package:portal_assoc/features/connections/connections_model.dart';

import '../../core/services/response_model.dart';
import 'connections_repository.dart';

class ConnectionsUseCase {
  final ConnectionsRepository repository;

  ConnectionsUseCase(this.repository);

  Future<ResponseModel> find(int id) => repository.find(id);
  Future<ResponseModel> findAll() => repository.findAll();
  Future<ResponseModel> create(ConnectionsModel data) => repository.create(data);
  Future<ResponseModel> update(ConnectionsModel data) => repository.update(data);
  Future<ResponseModel> delete(int id, String instance) => repository.delete(id, instance);
  Future<ResponseModel> testConnection(String instance) => repository.testConnection(instance);
  Future<ResponseModel> getQrCode(String instance) => repository.getQrCode(instance);
  Future<ResponseModel> getConnectionStatus(String instance) => repository.getConnectionStatus(instance);
}
