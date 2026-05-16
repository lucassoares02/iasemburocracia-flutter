import 'dart:developer';

import 'package:portal_assoc/features/register/companies_model.dart';
import 'package:portal_assoc/features/register/register_usecase.dart';
import 'package:portal_assoc/core/state/app_state.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/state/base_controller.dart';
import 'package:flutter/material.dart';
import 'register_model.dart';

class RegisterController extends BaseController<RegisterModel> {
  final RegisterUseCase registerUsecase;

  RegisterController(super.initialState, this.registerUsecase);

  ValueNotifier<StateApp> stateFind = ValueNotifier(StartState());
  ValueNotifier<StateApp> stateFindAll = ValueNotifier(StartState());
  ValueNotifier<StateApp> stateCreate = ValueNotifier(StartState());
  ValueNotifier<StateApp> stateCreateCompany = ValueNotifier(StartState());
  ValueNotifier<StateApp> stateUpdate = ValueNotifier(StartState());
  ValueNotifier<StateApp> stateDelete = ValueNotifier(StartState());
  int step = 1;
  int? user;

  Future<void> create(RegisterModel data) async => runWithState(() => registerUsecase.create(data), stateCreate, additionalAction: () {
        step = 2;
        user = stateCreate.value is SuccessState ? (stateCreate.value as SuccessState).data["id"] as int : null;
        SharedPreferences.getInstance().then((prefs) {
          prefs.setInt('user_id', user!);
          prefs.setInt('step', step);
        });
      });
  Future<void> createCompany(CompaniesModel data, type) async => runWithState(() {
        if (user == null) {
          return registerUsecase.createCompanyWithoutId(data, type);
        } else {
          return registerUsecase.createCompany(data, user!, type);
        }
      }, stateCreateCompany);
  Future<void> find(String cnpj) async => runWithState(() => registerUsecase.find(cnpj), stateFind);
  Future<void> findAll() async => runWithState(() => registerUsecase.findAll(), stateFindAll);
  Future<void> update(RegisterModel data) async => runWithState(() => registerUsecase.update(data), stateUpdate);
  Future<void> delete(int id) async => runWithState(() => registerUsecase.delete(id), stateDelete);
}
