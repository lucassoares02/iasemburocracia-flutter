import 'package:flutter/material.dart';

import '../../core/state/app_state.dart';
import '../../core/state/base_controller.dart';
import 'address_model.dart';
import 'address_usecase.dart';

class AddressController extends BaseController<AddressModel> {
  final AddressUseCase _useCase;

  AddressController(super.initialState, this._useCase);

  final ValueNotifier<StateApp> stateList = ValueNotifier(StartState());
  final ValueNotifier<StateApp> stateSuggestions = ValueNotifier(StartState());
  final ValueNotifier<StateApp> stateDetails = ValueNotifier(StartState());
  final ValueNotifier<StateApp> stateCreate = ValueNotifier(StartState());
  final ValueNotifier<StateApp> stateDelete = ValueNotifier(StartState());

  Future<void> findAll() => runWithState(_useCase.findAll, stateList);

  Future<void> autocomplete(String input, {String? sessionToken}) =>
      runWithState(() => _useCase.autocomplete(input, sessionToken: sessionToken), stateSuggestions);

  Future<void> details(String placeId, {String? sessionToken}) =>
      runWithState(() => _useCase.details(placeId, sessionToken: sessionToken), stateDetails);

  Future<void> create(AddressModel data) =>
      runWithState(() => _useCase.create(data), stateCreate);

  Future<void> delete(int id) =>
      runWithState(() => _useCase.delete(id), stateDelete);
}
