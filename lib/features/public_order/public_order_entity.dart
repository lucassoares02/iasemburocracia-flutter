class PublicCompanyEntity {
  int? id;
  String? name;
  String? description;
  String? phone;
  bool? status;
  String? logoUrl;
  String? bannerUrl;
  String? brandColor;
  bool acceptsDelivery = true;
  bool acceptsPickup = true;
}

class PublicOpeningHourEntity {
  int? weekday; // 1=Mon..7=Sun (matches frontend save convention)
  String? opensAt; // 'HH:MM:SS'
  String? closesAt; // 'HH:MM:SS'
  bool isClosed = false;
}

class PublicMenuItemEntity {
  int? id;
  int? companyId;
  int? categoryId;
  String? name;
  String? description;
  double? price;
  String? imageUrl;
  String? categoryName;
  int? prepTimeMinutes;
  bool featured = false;
  bool hasOptions = false;
  int salesCount = 0; // total vendido (para ordenar "mais pedidos")
}

class PublicCategoryEntity {
  int? id;
  String? name;
  List<PublicMenuItemEntity>? items;
}

class PublicPromotionEntity {
  int? id;
  String? name;
  String? description;
  String? imageUrl;
  bool active = true;
  double? originalPrice;
  double? discountPercent;
  double? finalPrice;
  List<PublicPromotionItemEntity>? items;
}

class PublicPromotionItemEntity {
  int? id;
  int? menuItemId;
  String? name;
  String? imageUrl;
  double? price;
  int quantity = 1;
  double? subtotal;
  bool hasOptions = false;
}

class PublicPaymentMethodEntity {
  int? id;
  int? type;
  String? label;
  String? description;
  bool active = false;
}

class PublicCompanyPreferencesEntity {
  int? maxDistanceMetersDelivery;
  double? kilometerPrice;
  int? maxDistanceMetersFreeDelivery;
  double? minPriceOrder;
  double? minTaxDelivery;
}

class PublicCompanyAddressEntity {
  String? street;
  String? number;
  String? neighborhood;
  String? city;
  String? state;
  String? zipCode;
  double? latitude;
  double? longitude;
  String? formattedAddress;
}

class PublicClientEntity {
  int? id;
  int? companyId;
  String? name;
  String? phone;
  String? street;
  String? number;
  String? complement;
  String? neighborhood;
  String? city;
  String? state;
  String? zipCode;
  double? lat;
  double? lng;

  bool get hasAddress => street != null && street!.trim().isNotEmpty;
}
