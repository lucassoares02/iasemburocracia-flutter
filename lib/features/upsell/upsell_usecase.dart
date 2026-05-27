import '../../core/services/response_model.dart';
import 'upsell_model.dart';
import 'upsell_repository.dart';

class UpsellUseCase {
  final UpsellRepository _repo;
  UpsellUseCase(this._repo);

  Future<ResponseModel> findAll() => _repo.findAll();
  Future<ResponseModel> create(UpsellRuleModel model) => _repo.create(model);
  Future<ResponseModel> update(UpsellRuleModel model) => _repo.update(model);
  Future<ResponseModel> toggle(int id, bool active) => _repo.toggle(id, active);
  Future<ResponseModel> duplicate(int id) => _repo.duplicate(id);
  Future<ResponseModel> delete(int id) => _repo.delete(id);
}
