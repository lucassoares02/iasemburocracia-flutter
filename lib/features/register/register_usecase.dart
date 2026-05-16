// Arquivo gerado automaticamente
import 'package:portal_assoc/features/register/companies_model.dart';
import 'package:portal_assoc/features/register/register_model.dart';

import '../../core/services/response_model.dart';
import 'register_repository.dart';

class RegisterUseCase {
  final RegisterRepository repository;

  RegisterUseCase(this.repository);

  Future<ResponseModel> find(String cpnj) async {
    return await repository.find(cpnj);
  }

  Future<ResponseModel> findAll() async {
    return await repository.findAll();
  }

  Future<ResponseModel> create(RegisterModel data) async {
    return await repository.create(data);
  }

  Future<ResponseModel> createCompany(CompaniesModel data, int user, type) async {
    return await repository.createCompany(data, user, type);
  }

  Future<ResponseModel> createCompanyWithoutId(CompaniesModel data, type) async {
    return await repository.createCompanyWithoutId(data, type);
  }

  Future<ResponseModel> update(RegisterModel data) async {
    return await repository.update(data);
  }

  Future<ResponseModel> delete(int id) async {
    return await repository.delete(id);
  }
}
