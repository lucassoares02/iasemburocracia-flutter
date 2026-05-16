import 'package:portal_assoc/features/companies/models/business_address_entity.dart';

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
