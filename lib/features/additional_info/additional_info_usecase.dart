// Arquivo gerado automaticamente
import 'package:portal_assoc/features/additional_info/additional_info_model.dart';

import '../../core/services/response_model.dart';
import 'additional_info_repository.dart';

class AdditionalInfoUseCase {
  final AdditionalInfoRepository repository;

  AdditionalInfoUseCase(this.repository);

  Future<ResponseModel> find(int id) async {
    return await repository.find(id);
  }

  Future<ResponseModel> findAll() async {
    return await repository.findAll();
  }

  Future<ResponseModel> create(AdditionalInfoModel data) async {
    return await repository.create(data);
  }

  Future<ResponseModel> update(AdditionalInfoModel data) async {
    return await repository.update(data);
  }

  Future<ResponseModel> delete(int id) async {
    return await repository.delete(id);
  }
}
