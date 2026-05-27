class PromotionEntity {
  int? id;
  int? companyId;
  String? name;
  String? description;
  String? imageUrl;
  bool active = true;
  double? originalPrice;
  double? discountPercent;
  double? finalPrice;
  List<PromotionItemEntity> items = [];
}

class PromotionItemEntity {
  int? id;
  int? menuItemId;
  String? name;
  String? imageUrl;
  double? price;
  int quantity = 1;
  double? subtotal;
}
