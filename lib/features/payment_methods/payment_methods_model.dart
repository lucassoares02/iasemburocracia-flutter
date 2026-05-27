import 'payment_methods_entity.dart';

class PaymentMethodsModel extends PaymentMethodsEntity {
  PaymentMethodsModel.fromJson(Map<String, dynamic> json) {
    id = json['id'] as int?;
    companyId = json['company_id'] as int?;
    type = (json['type'] as num?)?.toInt();
    label = json['label'] as String?;
    description = json['description'] as String?;
    active = json['active'] as bool?;
    createdAt = json['created_at']?.toString();
    updatedAt = json['updated_at']?.toString();
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'company_id': companyId,
        'type': type,
        'label': label,
        'description': description,
        'active': active,
        'created_at': createdAt,
        'updated_at': updatedAt,
      };
}
