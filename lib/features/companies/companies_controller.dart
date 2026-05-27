import 'package:portal_assoc/features/companies/companies_usecase.dart';
import 'package:portal_assoc/core/state/app_state.dart';
import 'package:portal_assoc/features/companies/models/business_address_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/state/base_controller.dart';
import 'package:flutter/material.dart';
import 'companies_model.dart';

class CompaniesController extends BaseController<CompaniesModel> {
  final CompaniesUseCase companiesUsecase;

  CompaniesController(super.initialState, this.companiesUsecase);

  ValueNotifier<StateApp> stateFind = ValueNotifier(StartState());
  ValueNotifier<StateApp> stateFindBusinessAddress = ValueNotifier(StartState());
  ValueNotifier<StateApp> stateAddressAutocomplete = ValueNotifier(StartState());
  ValueNotifier<StateApp> stateAddressDetails = ValueNotifier(StartState());
  ValueNotifier<StateApp> stateFindAll = ValueNotifier(StartState());
  ValueNotifier<StateApp> stateCreate = ValueNotifier(StartState());
  ValueNotifier<StateApp> stateUpdate = ValueNotifier(StartState());
  ValueNotifier<StateApp> stateUpdateBusiness = ValueNotifier(StartState());
  ValueNotifier<StateApp> stateDelete = ValueNotifier(StartState());

  Future<void> find() async => runWithState(() => companiesUsecase.find(), stateFind, additionalAction: () {
        final prefs = SharedPreferences.getInstance();
        prefs.then((value) {
          if (stateFind.value is SuccessState) {
            CompaniesModel company = (stateFind.value as SuccessState).data;
            value.setInt('company', company.id!);
          }
        });
      });
  Future<void> findBusinessAddress() async => runWithState(() => companiesUsecase.findBusinessAddress(), stateFindBusinessAddress);
  Future<void> addressAutocomplete(String input, {String? sessionToken}) =>
      runWithState(() => companiesUsecase.addressAutocomplete(input, sessionToken: sessionToken), stateAddressAutocomplete);
  Future<void> addressDetails(String placeId, {String? sessionToken}) =>
      runWithState(() => companiesUsecase.addressDetails(placeId, sessionToken: sessionToken), stateAddressDetails);
  Future<void> findAll() async => runWithState(() => companiesUsecase.findAll(), stateFindAll);
  Future<void> create(CompaniesModel data) async => runWithState(() => companiesUsecase.create(data), stateCreate);
  Future<void> update(CompaniesModel data) async => runWithState(
        () => companiesUsecase.update(data),
        stateUpdate,
        additionalAction: () {
          find();
        },
      );
  Future<void> updateBusiness(BusinessAddressModel data) async => runWithState(
        () => companiesUsecase.updateBusiness(data),
        stateUpdateBusiness,
        additionalAction: () {
          findBusinessAddress();
        },
      );

  Future<void> delete(int id) async => runWithState(() => companiesUsecase.delete(id), stateDelete);
}
