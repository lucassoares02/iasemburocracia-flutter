import 'address_entity.dart';

double? _parseNullableDouble(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

class AddressModel extends AddressEntity {
  AddressModel({
    super.id,
    super.companyId,
    super.label,
    super.street,
    super.number,
    super.complement,
    super.neighborhood,
    super.city,
    super.state,
    super.zipCode,
    super.country,
    super.lat,
    super.lng,
    super.placeId,
    super.formattedAddress,
    super.createdAt,
  });

  AddressModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    companyId = json['company_id'];
    label = json['label'];
    street = json['street'];
    number = json['number'];
    complement = json['complement'];
    neighborhood = json['neighborhood'];
    city = json['city'];
    state = json['state'];
    zipCode = json['zip_code'];
    country = json['country'];
    lat = _parseNullableDouble(json['lat']);
    lng = _parseNullableDouble(json['lng']);
    placeId = json['place_id'];
    formattedAddress = json['formatted_address'];
    createdAt = json['created_at'];
  }

  Map<String, dynamic> toJson() => {
        'company_id': companyId,
        'label': label,
        'street': street,
        'number': number,
        'complement': complement,
        'neighborhood': neighborhood,
        'city': city,
        'state': state,
        'zip_code': zipCode,
        'country': country,
        'lat': lat,
        'lng': lng,
        'place_id': placeId,
        'formatted_address': formattedAddress,
      };
}

class PlaceSuggestion {
  final String placeId;
  final String description;
  final String? mainText;
  final String? secondaryText;

  const PlaceSuggestion({
    required this.placeId,
    required this.description,
    this.mainText,
    this.secondaryText,
  });

  factory PlaceSuggestion.fromJson(Map<String, dynamic> json) => PlaceSuggestion(
        placeId: json['placeId'] as String,
        description: json['description'] as String,
        mainText: json['mainText'] as String?,
        secondaryText: json['secondaryText'] as String?,
      );
}

class PlaceDetails {
  final String placeId;
  final String? formattedAddress;
  final double? lat;
  final double? lng;
  final String? street;
  final String? number;
  final String? neighborhood;
  final String? city;
  final String? state;
  final String? zipCode;
  final String? country;

  const PlaceDetails({
    required this.placeId,
    this.formattedAddress,
    this.lat,
    this.lng,
    this.street,
    this.number,
    this.neighborhood,
    this.city,
    this.state,
    this.zipCode,
    this.country,
  });

  factory PlaceDetails.fromJson(Map<String, dynamic> json) => PlaceDetails(
        placeId: json['placeId'] as String,
        formattedAddress: json['formattedAddress'] as String?,
        lat: _parseNullableDouble(json['lat']),
        lng: _parseNullableDouble(json['lng']),
        street: json['street'] as String?,
        number: json['number'] as String?,
        neighborhood: json['neighborhood'] as String?,
        city: json['city'] as String?,
        state: json['state'] as String?,
        zipCode: json['zipCode'] as String?,
        country: json['country'] as String?,
      );
}
