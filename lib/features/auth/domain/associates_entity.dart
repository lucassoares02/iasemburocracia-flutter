class CompaniesEntity {
  final int? id;
  final String? name;
  final String? cnpj;
  int? order;
  final int? type;

  CompaniesEntity({
    required this.id,
    required this.name,
    required this.cnpj,
    this.order,
    required this.type,
  });
}
