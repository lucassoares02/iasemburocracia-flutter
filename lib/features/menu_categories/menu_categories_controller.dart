import 'package:portal_assoc/features/menu_categories/menu_categories_usecase.dart';
import 'package:portal_assoc/core/state/app_state.dart';
import '../../core/state/base_controller.dart';
import 'package:flutter/material.dart';
import 'menu_categories_model.dart';

class MenuCategoriesController extends BaseController<MenuCategoriesModel> {
  final MenuCategoriesUseCase menu_categoriesUsecase;

  MenuCategoriesController(super.initialState, this.menu_categoriesUsecase);

  ValueNotifier<StateApp> stateFind = ValueNotifier(StartState());
  ValueNotifier<StateApp> stateFindAll = ValueNotifier(StartState());
  ValueNotifier<StateApp> stateCreate = ValueNotifier(StartState());
  ValueNotifier<StateApp> stateUpdate = ValueNotifier(StartState());
  ValueNotifier<StateApp> stateDelete = ValueNotifier(StartState());

  Future<void> find(int id) async => runWithState(() => menu_categoriesUsecase.find(id), stateFind);
  Future<void> findAll() async => runWithState(() => menu_categoriesUsecase.findAll(), stateFindAll);
  Future<void> create(MenuCategoriesModel data) async => runWithState(() => menu_categoriesUsecase.create(data), stateCreate);
  Future<void> update(MenuCategoriesModel data) async => runWithState(() => menu_categoriesUsecase.update(data), stateUpdate);
  Future<void> delete(int id) async => runWithState(() => menu_categoriesUsecase.delete(id), stateDelete);
}
