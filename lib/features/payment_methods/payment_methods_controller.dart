import 'package:portal_assoc/features/payment_methods/payment_methods_usecase.dart';
import 'package:portal_assoc/core/state/app_state.dart';
import '../../core/state/base_controller.dart';
import 'package:flutter/material.dart';
import 'payment_methods_model.dart';

class PaymentMethodsController extends BaseController<PaymentMethodsModel> {
  final PaymentMethodsUseCase payment_methodsUsecase;

  PaymentMethodsController(super.initialState, this.payment_methodsUsecase);

  ValueNotifier<StateApp> stateFind = ValueNotifier(StartState());
  ValueNotifier<StateApp> stateFindAll = ValueNotifier(StartState());
  ValueNotifier<StateApp> stateCreate = ValueNotifier(StartState());
  ValueNotifier<StateApp> stateUpdate = ValueNotifier(StartState());
  ValueNotifier<StateApp> stateDelete = ValueNotifier(StartState());

  Future<void> find(int id) async => runWithState(() => payment_methodsUsecase.find(id), stateFind);
  Future<void> findAll() async => runWithState(() => payment_methodsUsecase.findAll(), stateFindAll);
  Future<void> create(PaymentMethodsModel data, BuildContext context) async => runWithState(
        () => payment_methodsUsecase.create(data),
        stateCreate,
        additionalAction: () {
          findAll();
        },
      );
  Future<void> update(PaymentMethodsModel data) async => runWithState(() => payment_methodsUsecase.update(data), stateUpdate);
  Future<void> delete(int id) async => runWithState(() => payment_methodsUsecase.delete(id), stateDelete, additionalAction: () {
        findAll();
      });
}
