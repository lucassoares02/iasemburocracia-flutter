class PaymentMethodsEntity {
  int? id;
  int? companyId;
  int? type;
  String? label;
  String? description;
  bool? active;
  String? createdAt;
  String? updatedAt;

  PaymentMethodsEntity({
    this.id,
    this.companyId,
    this.type,
    this.label,
    this.description,
    this.active,
    this.createdAt,
    this.updatedAt,
  });
}
