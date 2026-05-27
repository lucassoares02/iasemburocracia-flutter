import 'package:flutter/material.dart';
import '../../core/state/app_state.dart';
import '../../core/state/base_controller.dart';
import 'upsell_model.dart';
import 'upsell_usecase.dart';

class UpsellController extends BaseController<UpsellRuleModel> {
  final UpsellUseCase usecase;
  UpsellController(super.initialState, this.usecase);

  ValueNotifier<StateApp> stateFindAll = ValueNotifier(StartState());
  ValueNotifier<StateApp> stateCreate = ValueNotifier(StartState());
  ValueNotifier<StateApp> stateUpdate = ValueNotifier(StartState());
  ValueNotifier<StateApp> stateDelete = ValueNotifier(StartState());

  Future<void> findAll() => runWithState(() => usecase.findAll(), stateFindAll);

  Future<void> create(UpsellRuleModel model, BuildContext context) =>
      runWithState(
        () => usecase.create(model),
        stateCreate,
        additionalAction: () {
          Navigator.pop(context);
          findAll();
        },
      );

  Future<void> update(UpsellRuleModel model, BuildContext context) =>
      runWithState(
        () => usecase.update(model),
        stateUpdate,
        additionalAction: () {
          Navigator.pop(context);
          findAll();
        },
      );

  Future<void> toggle(int id, bool active) => runWithState(
        () => usecase.toggle(id, active),
        stateUpdate,
        additionalAction: findAll,
      );

  Future<void> duplicate(int id) => runWithState(
        () => usecase.duplicate(id),
        stateCreate,
        additionalAction: findAll,
      );

  Future<void> delete(int id) => runWithState(
        () => usecase.delete(id),
        stateDelete,
        additionalAction: findAll,
      );
}
