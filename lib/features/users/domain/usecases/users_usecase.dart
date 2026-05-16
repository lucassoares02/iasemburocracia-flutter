import 'package:portal_assoc/core/services/response_model.dart';
import 'package:portal_assoc/features/users/data/users_repository.dart';
import 'package:portal_assoc/features/users/data/user_model.dart';

class UsersUsecase {
  final UsersRepository repository;

  UsersUsecase(this.repository);

  Future<ResponseModel> getUsers() {
    return repository.getUsers();
  }

  Future<ResponseModel> sendEmailUser(int user) {
    return repository.sendEmailUser(user);
  }

  Future<ResponseModel> createUser(int? id, String? name, String? email, int? type, List<UserModel> selectedAssociates, bool? active) {
    return repository.createUser(id, name, email, type, selectedAssociates, active);
  }
}
