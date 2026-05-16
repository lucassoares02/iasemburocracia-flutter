import 'package:portal_assoc/features/account/account_usecase.dart';
import 'package:portal_assoc/core/state/app_state.dart';
import 'package:portal_assoc/features/register/companies_model.dart';
import '../../core/state/base_controller.dart';
import 'package:flutter/material.dart';
import 'account_model.dart';

class AccountController extends BaseController<AccountModel> {
  final AccountUseCase accountUsecase;

  AccountController(super.initialState, this.accountUsecase);

  ValueNotifier<StateApp> stateFind = ValueNotifier(StartState());
  ValueNotifier<StateApp> stateFindCompanies = ValueNotifier(StartState());
  ValueNotifier<StateApp> stateCreate = ValueNotifier(StartState());
  ValueNotifier<StateApp> stateUpdate = ValueNotifier(StartState());
  ValueNotifier<StateApp> stateDelete = ValueNotifier(StartState());

  Future<void> find() async => runWithState(() => accountUsecase.find(), stateFind);

  Future<void> update(AccountModel data) async => runWithState(() => accountUsecase.update(data), stateUpdate, additionalAction: () {
        find();
      }, toast: true);

  Future<void> updateCompany(CompaniesModel data) async => runWithState(() => accountUsecase.updateCompany(data), stateUpdate, additionalAction: () {
        findCompanyId();
      }, toast: true);

  Future<void> findCompanyId() async => runWithState(() => accountUsecase.findCompanyId(), stateFindCompanies);
}
