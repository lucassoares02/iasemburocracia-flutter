// Arquivo gerado automaticamente
import 'package:portal_assoc/features/connections/connections_model.dart';

import '../../core/services/response_model.dart';
import 'connections_repository.dart';

class ConnectionsUseCase {
  final ConnectionsRepository repository;

  ConnectionsUseCase(this.repository);

  Future<ResponseModel> find(int id) async {
    return await repository.find(id);
  }

  Future<ResponseModel> findAll() async {
    return await repository.findAll();
  }

  Future<ResponseModel> create(ConnectionsModel data) async {
    return await repository.create(data);
  }

  Future<ResponseModel> update(ConnectionsModel data) async {
    return await repository.update(data);
  }

  Future<ResponseModel> delete(int id, String instance) async {
    return await repository.delete(id, instance);
  }
}
