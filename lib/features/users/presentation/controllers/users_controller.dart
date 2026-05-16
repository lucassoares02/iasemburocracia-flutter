import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:portal_assoc/core/services/response_model.dart';
import 'package:portal_assoc/core/state/app_state.dart';
import 'package:portal_assoc/features/users/data/user_model.dart';
import 'package:portal_assoc/features/users/data/users_repository.dart';
import 'package:portal_assoc/features/users/domain/usecases/users_usecase.dart';

class UsersController extends ValueNotifier<StateApp> {
  final UsersUsecase _usersUsecase;

  UsersController(StateApp initialState, UsersRepository repository)
      : _usersUsecase = UsersUsecase(repository),
        super(initialState);

  List<UserModel> associates = [];
  List<UserModel> selectedAssociates = [];
  List<UserModel> users = [];
  List<UserModel> usersBackup = [];

  ValueNotifier<StateApp> stateUsers = ValueNotifier(StartState());
  ValueNotifier<StateApp> stateCreateUsers = ValueNotifier(StartState());
  ValueNotifier<StateApp> stateAssociates = ValueNotifier(StartState());
  ValueNotifier<StateApp> stateSendEmail = ValueNotifier(StartState());

  Future<void> getUsers() async {
    stateUsers.value = LoadingState();
    ResponseModel response = await _usersUsecase.getUsers();
    if (response.success) {
      users = response.data as List<UserModel>;
      usersBackup = response.data as List<UserModel>;
      stateUsers.value = SuccessState(users);
    } else {
      stateUsers.value = ErrorState("Save Error!");
    }
  }

  Future<void> sendEmailUser(int user) async {
    stateSendEmail.value = LoadingState();
    ResponseModel response = await _usersUsecase.sendEmailUser(user);
    if (response.success) {
      stateSendEmail.value = SuccessState("Email sent successfully!");
    } else {
      stateSendEmail.value = ErrorState("Save Error!");
    }
  }

  Future<void> createUser({int? id, bool? active, String? name, String? email, int? type}) async {
    stateCreateUsers.value = LoadingState();
    ResponseModel response = await _usersUsecase.createUser(id, name, email, type, selectedAssociates, active);
    if (response.success) {
      stateCreateUsers.value = SuccessState(users);
      ResponseModel responseUsers = await _usersUsecase.getUsers();
      stateUsers.value = LoadingState();
      stateUsers.value = SuccessState(responseUsers.data);
    } else {
      stateCreateUsers.value = ErrorState("Save Error!");
    }
  }

  search(String? value) async {
    try {
      if (value == null || value.isEmpty) {
        users = usersBackup;
      } else {
        String lowerCaseValue = value.toLowerCase();
        users = usersBackup.where(
          (item) {
            return item.id.toString().contains(lowerCaseValue) ||
                item.name.toString().toLowerCase().contains(lowerCaseValue) ||
                item.email.toString().toLowerCase().contains(lowerCaseValue) ||
                item.associates.toString().toLowerCase().contains(lowerCaseValue) ||
                item.type.toString().toLowerCase().contains(lowerCaseValue);
          },
        ).toList();
      }

      stateUsers.value = LoadingState();
      stateUsers.value = users.isEmpty ? StartState() : SuccessState(users);
    } catch (e) {
      stateUsers.value = ErrorState("Error search Requests Stores");
    }
  }
}
