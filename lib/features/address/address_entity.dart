class AddressEntity {
  int? id;
  int? companyId;
  String? label;
  String? street;
  String? number;
  String? complement;
  String? neighborhood;
  String? city;
  String? state;
  String? zipCode;
  String? country;
  double? lat;
  double? lng;
  String? placeId;
  String? formattedAddress;
  String? createdAt;

  AddressEntity({
    this.id,
    this.companyId,
    this.label,
    this.street,
    this.number,
    this.complement,
    this.neighborhood,
    this.city,
    this.state,
    this.zipCode,
    this.country,
    this.lat,
    this.lng,
    this.placeId,
    this.formattedAddress,
    this.createdAt,
  });
}
