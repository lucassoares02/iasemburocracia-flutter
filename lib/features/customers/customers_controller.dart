import 'package:flutter/widgets.dart';
import 'package:portal_assoc/core/services/response_model.dart';
import 'package:portal_assoc/core/state/app_state.dart';
import 'customers_usecase.dart';

class CustomersController {
  final CustomersUseCase _useCase;
  CustomersController(this._useCase);

  final stateSummary = ValueNotifier<StateApp>(StartState());
  final stateFindAll = ValueNotifier<StateApp>(StartState());
  final stateDetails = ValueNotifier<StateApp>(StartState());
  final stateAction  = ValueNotifier<StateApp>(StartState());

  String _lastSearch = '';
  String _lastFilter = 'all';

  Future<void> fetchSummary() async {
    stateSummary.value = LoadingState();
    try {
      final res = await _useCase.fetchSummary();
      stateSummary.value =
          res.success ? SuccessState(res.data) : ErrorState(res.message);
    } catch (e) {
      stateSummary.value = ErrorState(e.toString());
    }
  }

  Future<void> fetchAll({String search = '', String filter = 'all'}) async {
    _lastSearch = search;
    _lastFilter = filter;
    stateFindAll.value = LoadingState();
    try {
      final res = await _useCase.fetchAll(search: search, filter: filter);
      stateFindAll.value =
          res.success ? SuccessState(res.data) : ErrorState(res.message);
    } catch (e) {
      stateFindAll.value = ErrorState(e.toString());
    }
  }

  Future<void> fetchDetails(int clientId) async {
    stateDetails.value = LoadingState();
    try {
      final res = await _useCase.fetchDetails(clientId);
      stateDetails.value =
          res.success ? SuccessState(res.data) : ErrorState(res.message);
    } catch (e) {
      stateDetails.value = ErrorState(e.toString());
    }
  }

  Future<ResponseModel> createCustomer(Map<String, dynamic> data) async {
    stateAction.value = LoadingState();
    try {
      final res = await _useCase.createCustomer(data);
      stateAction.value =
          res.success ? SuccessState(res.data) : ErrorState(res.message);
      if (res.success) _refresh();
      return res;
    } catch (e) {
      stateAction.value = ErrorState(e.toString());
      return ResponseModel(success: false, message: e.toString());
    }
  }

  Future<ResponseModel> updateCustomer(int clientId, Map<String, dynamic> data) async {
    stateAction.value = LoadingState();
    try {
      final res = await _useCase.updateCustomer(clientId, data);
      stateAction.value =
          res.success ? SuccessState(res.data) : ErrorState(res.message);
      if (res.success) {
        _refresh();
        fetchDetails(clientId);
      }
      return res;
    } catch (e) {
      stateAction.value = ErrorState(e.toString());
      return ResponseModel(success: false, message: e.toString());
    }
  }

  Future<ResponseModel> deleteCustomer(int clientId) async {
    stateAction.value = LoadingState();
    try {
      final res = await _useCase.deleteCustomer(clientId);
      stateAction.value =
          res.success ? SuccessState(res.data) : ErrorState(res.message);
      if (res.success) _refresh();
      return res;
    } catch (e) {
      stateAction.value = ErrorState(e.toString());
      return ResponseModel(success: false, message: e.toString());
    }
  }

  void _refresh() {
    fetchAll(search: _lastSearch, filter: _lastFilter);
    fetchSummary();
  }

  void dispose() {
    stateSummary.dispose();
    stateFindAll.dispose();
    stateDetails.dispose();
    stateAction.dispose();
  }
}
