import 'package:portal_assoc/features/default/domain/usecases/default_usecase.dart';
import 'package:portal_assoc/features/default/data/default_repository.dart';
import 'package:portal_assoc/features/default/data/default_model.dart';
import 'package:portal_assoc/core/services/response_model.dart';
import 'package:portal_assoc/core/state/app_state.dart';
import 'package:flutter/material.dart';

class DefaultController extends ValueNotifier<StateApp> {
  final DefaultUsecase _defaultUsecase;

  DefaultController(StateApp initialState, DefaultRepository repository)
      : _defaultUsecase = DefaultUsecase(repository),
        super(initialState);

  List<DefaultModel> listDefault = [];

  ValueNotifier<StateApp> stateGetCommercialActions = ValueNotifier(StartState());

  Future<void> defaultGetItems() async {
    stateGetCommercialActions.value = LoadingState();
    ResponseModel response = await _defaultUsecase.defaultUseCase();
    if (response.success) {
      listDefault = response.data as List<DefaultModel>;
      stateGetCommercialActions.value = SuccessState("Save Success!");
    } else {
      stateGetCommercialActions.value = ErrorState("Save Error!");
    }
  }
}
