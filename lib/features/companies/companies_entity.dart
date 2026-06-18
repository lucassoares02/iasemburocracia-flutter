class CompaniesEntity {
  int? id;
  String? name;
  String? description;
  bool? status;
  String? phone;
  String? logoUrl;
  String? brandColor;
  String? bannerUrl;
  String? aiName;
  String? aiGender;
  String? aiPersonality;
  // Catálogo de personalidades personalizadas: [{label, prompt}, ...]
  List<Map<String, dynamic>>? customAiPersonalities;
  String? cuisineType;
  List<String>? dietaryRestrictions;
  List<String>? customDietaryRestrictions;
  bool? acceptsDelivery;
  bool? acceptsPickup;
  int? maxDistanceMetersDelivery;
  double? kilometerPrice;
  int? maxDistanceMetersFreeDelivery;
  double? minPriceOrder;
  double? minTaxDelivery;

  CompaniesEntity({
    this.id,
    this.name,
    this.description,
    this.status,
    this.phone,
    this.logoUrl,
    this.brandColor,
    this.bannerUrl,
    this.aiName,
    this.aiGender,
    this.aiPersonality,
    this.customAiPersonalities,
    this.cuisineType,
    this.dietaryRestrictions,
    this.customDietaryRestrictions,
    this.acceptsDelivery,
    this.acceptsPickup,
    this.maxDistanceMetersDelivery,
    this.kilometerPrice,
    this.maxDistanceMetersFreeDelivery,
    this.minPriceOrder,
    this.minTaxDelivery,
  });
}
