import 'dart:typed_data';

import 'package:portal_assoc/core/services/response_model.dart';
import 'package:portal_assoc/features/promotions/promotions_model.dart';
import 'package:portal_assoc/features/promotions/promotions_repository.dart';

class PromotionsUseCase {
  final PromotionsRepository repository;
  PromotionsUseCase(this.repository);

  Future<ResponseModel> findAll() => repository.findAll();
  Future<ResponseModel> create(PromotionModel model) =>
      repository.create(model);
  Future<ResponseModel> update(PromotionModel model) =>
      repository.update(model);
  Future<ResponseModel> toggle(int id, bool active) =>
      repository.toggle(id, active);
  Future<ResponseModel> delete(int id) => repository.delete(id);
  Future<ResponseModel> uploadImage(
          Uint8List bytes, String filename, String mimeType) =>
      repository.uploadImage(bytes, filename, mimeType);
}
