import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:portal_assoc/core/services/response_model.dart';
import 'package:portal_assoc/core/state/app_state.dart';
import 'package:portal_assoc/core/state/base_controller.dart';
import 'package:portal_assoc/features/promotions/promotions_model.dart';
import 'package:portal_assoc/features/promotions/promotions_usecase.dart';

class PromotionsController extends BaseController<PromotionModel> {
  final PromotionsUseCase usecase;
  PromotionsController(super.initialState, this.usecase);

  ValueNotifier<StateApp> stateFindAll = ValueNotifier(StartState());
  ValueNotifier<StateApp> stateCreate = ValueNotifier(StartState());
  ValueNotifier<StateApp> stateUpdate = ValueNotifier(StartState());
  ValueNotifier<StateApp> stateDelete = ValueNotifier(StartState());

  Future<void> findAll() => runWithState(() => usecase.findAll(), stateFindAll);

  Future<void> create(PromotionModel model, BuildContext context) =>
      runWithState(
        () => usecase.create(model),
        stateCreate,
        additionalAction: () {
          Navigator.pop(context);
          findAll();
        },
      );

  Future<void> update(PromotionModel model, BuildContext context) =>
      runWithState(
        () => usecase.update(model),
        stateUpdate,
        additionalAction: () {
          Navigator.pop(context);
          findAll();
        },
      );

  Future<void> delete(int id) => runWithState(
        () => usecase.delete(id),
        stateDelete,
        additionalAction: findAll,
      );

  Future<void> toggle(int id, bool active) => runWithState(
        () => usecase.toggle(id, active),
        stateUpdate,
        additionalAction: findAll,
      );

  Future<ResponseModel> uploadImage(
          Uint8List bytes, String filename, String mimeType) =>
      usecase.uploadImage(bytes, filename, mimeType);
}
