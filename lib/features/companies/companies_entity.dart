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
  String? cuisineType;
  List<String>? dietaryRestrictions;
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
    this.cuisineType,
    this.dietaryRestrictions,
    this.maxDistanceMetersDelivery,
    this.kilometerPrice,
    this.maxDistanceMetersFreeDelivery,
    this.minPriceOrder,
    this.minTaxDelivery,
  });
}
