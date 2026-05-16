import 'package:portal_assoc/features/company_opening_hours/company_opening_hours_usecase.dart';
import 'package:portal_assoc/core/state/app_state.dart';
import '../../core/state/base_controller.dart';
import 'package:flutter/material.dart';
import 'company_opening_hours_model.dart';

class CompanyOpeningHoursController extends BaseController<CompanyOpeningHoursModel> {
  final CompanyOpeningHoursUseCase company_opening_hoursUsecase;

  CompanyOpeningHoursController(super.initialState, this.company_opening_hoursUsecase);

  ValueNotifier<StateApp> stateFind = ValueNotifier(StartState());
  ValueNotifier<StateApp> stateFindAll = ValueNotifier(StartState());
  ValueNotifier<StateApp> stateCreate = ValueNotifier(StartState());
  ValueNotifier<StateApp> stateUpdate = ValueNotifier(StartState());
  ValueNotifier<StateApp> stateDelete = ValueNotifier(StartState());

  Future<void> find(int id) async => runWithState(() => company_opening_hoursUsecase.find(id), stateFind);
  Future<void> findAll() async => runWithState(() => company_opening_hoursUsecase.findAll(), stateFindAll);
  Future<void> create(CompanyOpeningHoursModel data) async => runWithState(
        () => company_opening_hoursUsecase.create(data),
        stateCreate,
        additionalAction: () {
          findAll();
        },
      );
  Future<void> update(CompanyOpeningHoursModel data) async => runWithState(
        () => company_opening_hoursUsecase.update(data),
        stateCreate,
        additionalAction: () {
          findAll();
        },
      );
  Future<void> delete(int id) async => runWithState(
        () => company_opening_hoursUsecase.delete(id),
        stateDelete,
        additionalAction: () {
          findAll();
        },
      );
}
