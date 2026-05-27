import '../../core/services/response_model.dart';
import 'address_model.dart';
import 'address_repository.dart';

class AddressUseCase {
  final AddressRepository repository;

  AddressUseCase(this.repository);

  Future<ResponseModel> autocomplete(String input, {String? sessionToken}) =>
      repository.autocomplete(input, sessionToken: sessionToken);

  Future<ResponseModel> details(String placeId, {String? sessionToken}) =>
      repository.details(placeId, sessionToken: sessionToken);

  Future<ResponseModel> findAll() => repository.findAll();

  Future<ResponseModel> create(AddressModel data) => repository.create(data);

  Future<ResponseModel> delete(int id) => repository.delete(id);
}
