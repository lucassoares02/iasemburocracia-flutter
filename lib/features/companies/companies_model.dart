import 'companies_entity.dart';

double? _toDouble(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse('$value');
}

class CompaniesModel extends CompaniesEntity {
  CompaniesModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    description = json['description'];
    status = json['status'];
    phone = json['phone'];
    logoUrl = json['logo_url'];
    brandColor = json['brand_color'];
    bannerUrl = json['banner_url'];
    aiName = json['ai_name'];
    aiGender = json['ai_gender'];
    aiPersonality = json['ai_personality'];
    customAiPersonalities = json['custom_ai_personalities'] != null
        ? List<Map<String, dynamic>>.from(
            (json['custom_ai_personalities'] as List).map((e) => Map<String, dynamic>.from(e as Map)))
        : null;
    cuisineType = json['cuisine_type'];
    dietaryRestrictions = json['dietary_restrictions'] != null
        ? List<String>.from(json['dietary_restrictions'] as List)
        : null;
    customDietaryRestrictions = json['custom_dietary_restrictions'] != null
        ? List<String>.from(json['custom_dietary_restrictions'] as List)
        : null;
    acceptsDelivery = json['accepts_delivery'] as bool? ?? true;
    acceptsPickup = json['accepts_pickup'] as bool? ?? true;
    maxDistanceMetersDelivery = json['max_distance_meters_delivery'] is int
        ? json['max_distance_meters_delivery'] as int
        : int.tryParse('${json['max_distance_meters_delivery']}');
    kilometerPrice = _toDouble(json['kilometer_price']);
    maxDistanceMetersFreeDelivery =
        json['max_distance_meters_free_delivery'] is int
            ? json['max_distance_meters_free_delivery'] as int
            : int.tryParse('${json['max_distance_meters_free_delivery']}');
    minPriceOrder = _toDouble(json['min_price_order']);
    minTaxDelivery = _toDouble(json['min_tax_delivery']);
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'status': status,
      'phone': phone,
      'logo_url': logoUrl,
      'brand_color': brandColor,
      'banner_url': bannerUrl,
      'ai_name': aiName,
      'ai_gender': aiGender,
      'ai_personality': aiPersonality,
      'custom_ai_personalities': customAiPersonalities,
      'cuisine_type': cuisineType,
      'dietary_restrictions': dietaryRestrictions,
      'custom_dietary_restrictions': customDietaryRestrictions,
      'accepts_delivery': acceptsDelivery,
      'accepts_pickup': acceptsPickup,
      'max_distance_meters_delivery': maxDistanceMetersDelivery,
      'kilometer_price': kilometerPrice,
      'max_distance_meters_free_delivery': maxDistanceMetersFreeDelivery,
      'min_price_order': minPriceOrder,
      'min_tax_delivery': minTaxDelivery,
    };
  }
}
