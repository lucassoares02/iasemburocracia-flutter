import 'package:portal_assoc/core/services/response_model.dart';
import 'package:portal_assoc/features/auth/data/user_model.dart';
import 'package:portal_assoc/features/auth/data/auth_repository.dart';

class AuthUseCase {
  final AuthRepository repository;

  AuthUseCase(this.repository);

  Future<UserModel> login(String email, String password) {
    return repository.login(email, password);
  }

  Future<ResponseModel> getCompanies() {
    return repository.getCompanies();
  }

  Future<ResponseModel> getOrdersItems() {
    return repository.getOrdersItems();
  }

  Future<ResponseModel> sendEmailForgotPassword(String email) {
    return repository.sendEmailForgotPassword(email);
  }
}
