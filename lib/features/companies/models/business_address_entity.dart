class BusinessAddressEntity {
  int? id;
  String? street;
  int? company;
  String? number;
  String? complement;
  String? neighborhood;
  String? city;
  String? state;
  String? zipCode;
  String? latitude;
  String? longitude;
  bool? isMain;
  String? createdAt;
  String? updatedAt;

  BusinessAddressEntity({
    this.id,
    this.street,
    this.company,
    this.number,
    this.complement,
    this.neighborhood,
    this.city,
    this.state,
    this.zipCode,
    this.latitude,
    this.longitude,
    this.isMain,
    this.createdAt,
    this.updatedAt,
  });
}
