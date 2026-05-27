import 'package:portal_assoc/core/services/response_model.dart';
import 'package:portal_assoc/features/auth/data/associate_model.dart';
import 'package:portal_assoc/features/auth/data/google_auth_service.dart';
import 'package:portal_assoc/features/auth/data/user_model.dart';
import 'package:portal_assoc/features/auth/data/auth_repository.dart';
import 'package:portal_assoc/features/auth/domain/auth_usecase.dart';
import 'package:portal_assoc/core/state/app_state.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthController extends ValueNotifier<StateApp> {
  final AuthUseCase _authUseCase;

  AuthController(StateApp initialState, AuthRepository repository)
      : _authUseCase = AuthUseCase(repository),
        super(initialState);

  ValueNotifier<StateApp> stateLogin = ValueNotifier(StartState());
  ValueNotifier<StateApp> stateGoogleLogin = ValueNotifier(StartState());
  ValueNotifier<StateApp> stateCompanies = ValueNotifier(StartState());
  ValueNotifier<StateApp> stateForgot = ValueNotifier(StartState());
  ValueNotifier<StateApp> stateOrdersItems = ValueNotifier(StartState());

  // Incrementado após cadastro de empresa para sinalizar refresh do dashboard
  final ValueNotifier<int> homeRefreshNotifier = ValueNotifier(0);

  UserModel? user;

  login(String email, String password) async {
    stateLogin.value = LoadingState();
    try {
      user = await _authUseCase.login(email, password);
      stateLogin.value = SuccessState<UserModel>(user!);
    } catch (e) {
      debugPrint("Error Login: $e");
      stateLogin.value = ErrorState("Error Login: ${e.toString()}");
    }
  }

  loginWithGoogle() async {
    stateGoogleLogin.value = LoadingState();
    try {
      final idToken = await GoogleAuthService.signIn();
      if (idToken == null) {
        stateGoogleLogin.value = StartState();
        return;
      }
      user = await _authUseCase.loginWithGoogle(idToken);
      stateGoogleLogin.value = SuccessState<UserModel>(user!);
    } catch (e) {
      debugPrint("Error Google Login: $e");
      stateGoogleLogin.value = ErrorState("Falha ao entrar com Google");
    }
  }

  findCompanies() async {
    stateCompanies.value = LoadingState();
    try {
      ResponseModel response = await _authUseCase.getCompanies();
      if (response.success) {
        final companies = response.data as List<CompaniesModel>;
        stateCompanies.value = SuccessState(companies);
        if (companies.isNotEmpty) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setInt('type', companies[0].type ?? 0);
          final currentCompany = prefs.getInt('company') ?? 0;
          if (currentCompany <= 0) {
            await prefs.setInt('company', companies[0].id ?? 0);
          }
          // garante refresh da home após sincronizar empresa ativa
          homeRefreshNotifier.value++;
        }
      } else {
        stateCompanies.value = ErrorState("Save Error!");
      }
    } catch (e) {
      debugPrint("Error Get Companies by User: $e");
      stateCompanies.value = ErrorState("Error Get Companies by User: ${e.toString()}");
    }
  }

  sendEmailForgotPassword(String email) async {
    stateForgot.value = LoadingState();
    try {
      ResponseModel response = await _authUseCase.sendEmailForgotPassword(email);
      if (response.success) {
        stateForgot.value = SuccessState(response.data);
      } else {
        stateForgot.value = ErrorState("Save Error!");
      }
    } catch (e) {
      debugPrint("Error Send Email: $e");
      stateForgot.value = ErrorState("Error Send Email: ${e.toString()}");
    }
  }

  getOrdersItems() async {
    try {
      ResponseModel response = await _authUseCase.getOrdersItems();
      if (response.success) {
        stateOrdersItems.value = LoadingState();
        stateOrdersItems.value = SuccessState(response.data);
      } else {
        stateOrdersItems.value = LoadingState();
        stateOrdersItems.value = ErrorState("Save Error!");
      }
    } catch (e) {
      debugPrint("Error Send Email: $e");
      stateOrdersItems.value = ErrorState("Error Send Email: ${e.toString()}");
    }
  }
}
