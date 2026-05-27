import 'dart:typed_data';

import 'package:portal_assoc/features/menu_items/menu_items_usecase.dart';
import 'package:portal_assoc/core/state/app_state.dart';
import '../../core/services/response_model.dart';
import '../../core/state/base_controller.dart';
import 'package:flutter/material.dart';
import 'menu_items_model.dart';

class MenuItemsController extends BaseController<MenuItemsModel> {
  final MenuItemsUseCase menuItemsUsecase;

  MenuItemsController(super.initialState, this.menuItemsUsecase);

  ValueNotifier<StateApp> stateFind = ValueNotifier(StartState());
  ValueNotifier<StateApp> stateFindAll = ValueNotifier(StartState());
  ValueNotifier<StateApp> stateCreate = ValueNotifier(StartState());
  ValueNotifier<StateApp> stateUpdate = ValueNotifier(StartState());
  ValueNotifier<StateApp> stateDelete = ValueNotifier(StartState());

  Future<void> find(int id) async => runWithState(() => menuItemsUsecase.find(id), stateFind);
  Future<void> findAll() async => runWithState(() => menuItemsUsecase.findAll(), stateFindAll);
  Future<void> create(MenuItemsModel data, BuildContext context) async => runWithState(
        () => menuItemsUsecase.create(data),
        stateCreate,
        additionalAction: () {
          Navigator.pop(context);
          findAll();
        },
      );
  Future<void> update(MenuItemsModel data, BuildContext context) async => runWithState(
        () => menuItemsUsecase.update(data),
        stateCreate,
        additionalAction: () {
          Navigator.pop(context);
          findAll();
        },
      );
  Future<ResponseModel> uploadImage(Uint8List bytes, String filename, String mimeType) async {
    return await menuItemsUsecase.uploadImage(bytes, filename, mimeType);
  }

  // Toggle without navigation — used for quick enable/disable from the grid
  Future<void> toggle(MenuItemsModel data) async => runWithState(
        () => menuItemsUsecase.update(data),
        stateUpdate,
        additionalAction: findAll,
      );
  Future<void> delete(int id, BuildContext context) async => runWithState(
        () => menuItemsUsecase.delete(id),
        stateDelete,
        additionalAction: () {
          Navigator.pop(context);
          findAll();
        },
      );
}
