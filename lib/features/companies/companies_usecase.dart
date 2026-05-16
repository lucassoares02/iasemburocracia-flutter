// Arquivo gerado automaticamente
import 'package:portal_assoc/features/companies/companies_model.dart';
import 'package:portal_assoc/features/companies/models/business_address_model.dart';

import '../../core/services/response_model.dart';
import 'companies_repository.dart';

class CompaniesUseCase {
  final CompaniesRepository repository;

  CompaniesUseCase(this.repository);

  Future<ResponseModel> find() async {
    return await repository.find();
  }

  Future<ResponseModel> findBusinessAddress() async {
    return await repository.findBusinessAddress();
  }

  Future<ResponseModel> findAll() async {
    return await repository.findAll();
  }

  Future<ResponseModel> create(CompaniesModel data) async {
    return await repository.create(data);
  }

  Future<ResponseModel> update(CompaniesModel data) async {
    return await repository.update(data);
  }

  Future<ResponseModel> updateBusiness(BusinessAddressModel data) async {
    return await repository.updateBusiness(data);
  }

  Future<ResponseModel> delete(int id) async {
    return await repository.delete(id);
  }
}
