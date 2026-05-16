import '../../core/state/app_state.dart';
import 'package:flutter/material.dart';
import '../services/response_model.dart';

abstract class BaseController<T> extends ValueNotifier<StateApp> {
  BaseController(super.initialState);

  Future<void> runWithState(Future<ResponseModel> Function() action, ValueNotifier<StateApp> state,
      {String? errorMessage, Function()? additionalAction, bool? toast, String? successMessage, String? successDescription}) async {
    // if (toast == false) state.value = LoadingState();
    state.value = LoadingState();
    try {
      final response = await action();
      if (response.success) {
        state.value = SuccessState(response.data, message: successMessage, description: successDescription);
        if (additionalAction != null) {
          additionalAction();
        }
      } else {
        state.value = ErrorState(response.message);
        await Future.delayed(const Duration(milliseconds: 1000));
        state.value = StartState();
      }
    } catch (e) {
      state.value = ErrorState(e.toString());
    }
  }
}
