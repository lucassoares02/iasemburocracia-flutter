// Arquivo gerado automaticamente
import 'package:portal_assoc/features/account/account_model.dart';
import 'package:portal_assoc/features/register/companies_model.dart';

import '../../core/services/response_model.dart';
import 'account_repository.dart';

class AccountUseCase {
  final AccountRepository repository;

  AccountUseCase(this.repository);

  Future<ResponseModel> find() async {
    return await repository.find();
  }

  Future<ResponseModel> findCompanyId() async {
    return await repository.findCompanyId();
  }

  Future<ResponseModel> update(AccountModel data) async {
    return await repository.update(data);
  }

  Future<ResponseModel> updateCompany(CompaniesModel data) async {
    return await repository.updateCompany(data);
  }
}
