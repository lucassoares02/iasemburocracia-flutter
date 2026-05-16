// Arquivo gerado automaticamente
import 'package:portal_assoc/features/payment_methods/payment_methods_model.dart';

import '../../core/services/response_model.dart';
import 'payment_methods_repository.dart';

class PaymentMethodsUseCase {
  final PaymentMethodsRepository repository;

  PaymentMethodsUseCase(this.repository);

  Future<ResponseModel> find(int id) async {
    return await repository.find(id);
  }

  Future<ResponseModel> findAll() async {
    return await repository.findAll();
  }

  Future<ResponseModel> create(PaymentMethodsModel data) async {
    return await repository.create(data);
  }

  Future<ResponseModel> update(PaymentMethodsModel data) async {
    return await repository.update(data);
  }

  Future<ResponseModel> delete(int id) async {
    return await repository.delete(id);
  }
}
