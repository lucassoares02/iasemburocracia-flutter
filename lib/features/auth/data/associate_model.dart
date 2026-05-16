import 'package:portal_assoc/features/auth/domain/associates_entity.dart';

class CompaniesModel extends CompaniesEntity {
  CompaniesModel({
    required int? id,
    required String? name,
    required String? cnpj,
    int? order,
    required int? type,
  }) : super(
          id: id,
          name: name,
          cnpj: cnpj,
          order: order,
          type: type,
        );
  factory CompaniesModel.fromJson(Map<String, dynamic> json) {
    return CompaniesModel(
      id: json['id'],
      name: json['razao_social'],
      cnpj: json['cnpj'],
      order: json['order_id'],
      type: json['relation_type'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'razao_social': name,
      'cnpj': cnpj,
      'order_id': order,
      'relation_type': type,
    };
  }
}
