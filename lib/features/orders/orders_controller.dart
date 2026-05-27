import 'package:flutter/material.dart';
import 'package:portal_assoc/features/orders/orders_usecase.dart';
import '../../core/services/response_model.dart';
import '../../core/state/app_state.dart';
import '../../core/state/base_controller.dart';
import 'orders_model.dart';

class OrdersController extends BaseController<OrderModel> {
  final OrdersUseCase useCase;

  OrdersController(super.initialState, this.useCase);

  ValueNotifier<StateApp> stateFindAll = ValueNotifier(StartState());
  ValueNotifier<StateApp> stateFindToday = ValueNotifier(StartState());
  ValueNotifier<StateApp> stateSummary = ValueNotifier(StartState());
  ValueNotifier<StateApp> stateCreate = ValueNotifier(StartState());
  ValueNotifier<StateApp> stateUpdateStatus = ValueNotifier(StartState());
  ValueNotifier<StateApp> stateDelete = ValueNotifier(StartState());

  Future<void> findAll() => runWithState(() => useCase.findAll(), stateFindAll);
  Future<void> findToday() => runWithState(() => useCase.findToday(), stateFindToday);
  Future<void> summary() => runWithState(() => useCase.summary(), stateSummary);

  Future<void> create(Map<String, dynamic> data, BuildContext context) => runWithState(
        () => useCase.create(data),
        stateCreate,
        additionalAction: () {
          Navigator.pop(context);
          _refresh();
        },
      );

  Future<ResponseModel> updateStatus(int orderId, int status, {String? cancelReason}) async {
    final result = await useCase.updateStatus(orderId, status, cancelReason: cancelReason);
    _refresh();
    return result;
  }

  Future<void> delete(int id, BuildContext context) => runWithState(
        () => useCase.delete(id),
        stateDelete,
        additionalAction: () {
          Navigator.pop(context);
          _refresh();
        },
      );

  void _refresh() {
    findAll();
    findToday();
    summary();
  }
}
