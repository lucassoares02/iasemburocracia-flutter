// Arquivo gerado automaticamente
import 'package:portal_assoc/features/company_opening_hours/company_opening_hours_model.dart';

import '../../core/services/response_model.dart';
import 'company_opening_hours_repository.dart';

class CompanyOpeningHoursUseCase {
  final CompanyOpeningHoursRepository repository;

  CompanyOpeningHoursUseCase(this.repository);

  Future<ResponseModel> find(int id) async {
    return await repository.find(id);
  }

  Future<ResponseModel> findAll() async {
    return await repository.findAll();
  }

  Future<ResponseModel> create(CompanyOpeningHoursModel data) async {
    return await repository.create(data);
  }

  Future<ResponseModel> update(CompanyOpeningHoursModel data) async {
    return await repository.update(data);
  }

  Future<ResponseModel> delete(int id) async {
    return await repository.delete(id);
  }
}
