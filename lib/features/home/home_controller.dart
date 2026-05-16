import 'package:portal_assoc/core/state/app_state.dart';
import 'package:portal_assoc/features/home/home_usecase.dart';
import '../../core/state/base_controller.dart';
import 'package:flutter/material.dart';
import 'home_model.dart';

class HomeController extends BaseController<HomeModel> {
  final HomeUseCase homeUsecase;

  HomeController(super.initialState, this.homeUsecase);

  ValueNotifier<StateApp> stateFind = ValueNotifier(StartState());
  ValueNotifier<StateApp> stateFindAll = ValueNotifier(StartState());
  ValueNotifier<StateApp> stateCreate = ValueNotifier(StartState());
  ValueNotifier<StateApp> stateUpdate = ValueNotifier(StartState());
  ValueNotifier<StateApp> stateDelete = ValueNotifier(StartState());

  Future<void> find(int id) async => runWithState(() => homeUsecase.find(id), stateFind);
  Future<void> findAll() async => runWithState(() => homeUsecase.findAll(), stateFindAll);
  Future<void> create(HomeModel data) async => runWithState(() => homeUsecase.create(data), stateCreate);
  Future<void> update(HomeModel data) async => runWithState(() => homeUsecase.update(data), stateUpdate);
  Future<void> delete(int id) async => runWithState(() => homeUsecase.delete(id), stateDelete);
}
