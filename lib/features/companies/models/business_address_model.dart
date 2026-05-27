import 'package:portal_assoc/features/companies/models/business_address_entity.dart';

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

  factory PlaceDetails.fromJson(Map<String, dynamic> json) {
    double? parseDouble(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v);
      return null;
    }

    return PlaceDetails(
      placeId: json['placeId'] as String,
      formattedAddress: json['formattedAddress'] as String?,
      lat: parseDouble(json['lat']),
      lng: parseDouble(json['lng']),
      street: json['street'] as String?,
      number: json['number'] as String?,
      neighborhood: json['neighborhood'] as String?,
      city: json['city'] as String?,
      state: json['state'] as String?,
      zipCode: json['zipCode'] as String?,
      country: json['country'] as String?,
    );
  }
}

class BusinessAddressModel extends BusinessAddressEntity {
  BusinessAddressModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    street = json['street'];
    company = json['company_id'];
    number = json['number'];
    complement = json['complement'];
    neighborhood = json['neighborhood'];
    city = json['city'];
    state = json['state'];
    zipCode = json['zip_code'];
    latitude = json['latitude'];
    longitude = json['longitude'];
    isMain = json['isMain'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['street'] = street;
    data['company_id'] = company;
    data['number'] = number;
    data['complement'] = complement;
    data['neighborhood'] = neighborhood;
    data['city'] = city;
    data['state'] = state;
    data['zip_code'] = zipCode;
    data['latitude'] = latitude;
    data['longitude'] = longitude;
    data['isMain'] = isMain;
    data['createdAt'] = createdAt;
    data['updatedAt'] = updatedAt;

    return data;
  }
}
