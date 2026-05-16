import 'package:portal_assoc/features/additional_info/additional_info_usecase.dart';
import 'package:portal_assoc/core/state/app_state.dart';
import '../../core/state/base_controller.dart';
import 'package:flutter/material.dart';
import 'additional_info_model.dart';

class AdditionalInfoController extends BaseController<AdditionalInfoModel> {
  final AdditionalInfoUseCase additional_infoUsecase;

  AdditionalInfoController(super.initialState, this.additional_infoUsecase);

  ValueNotifier<StateApp> stateFind = ValueNotifier(StartState());
  ValueNotifier<StateApp> stateFindAll = ValueNotifier(StartState());
  ValueNotifier<StateApp> stateCreate = ValueNotifier(StartState());
  ValueNotifier<StateApp> stateUpdate = ValueNotifier(StartState());
  ValueNotifier<StateApp> stateDelete = ValueNotifier(StartState());

  Future<void> find(int id) async => runWithState(() => additional_infoUsecase.find(id), stateFind);
  Future<void> findAll() async => runWithState(() => additional_infoUsecase.findAll(), stateFindAll);
  Future<void> create(AdditionalInfoModel data) async => runWithState(() => additional_infoUsecase.create(data), stateCreate);
  Future<void> update(AdditionalInfoModel data) async => runWithState(() => additional_infoUsecase.update(data), stateUpdate);
  Future<void> delete(int id) async => runWithState(() => additional_infoUsecase.delete(id), stateDelete);
}
