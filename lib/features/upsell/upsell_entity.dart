class UpsellRuleItemEntity {
  int? id;
  int? menuItemId;
  String? discountType; // 'percent' | 'final_price'
  double? discountValue;
  double? finalPrice;
  int displayOrder = 0;
  // enriched fields from API
  String? itemName;
  double? itemPrice;
  String? itemImageUrl;
}

class UpsellRuleEntity {
  int? id;
  int? companyId;
  int? triggerItemId;
  String? description;
  bool active = true;
  int maxSuggestions = 3;
  // enriched fields from API
  String? triggerName;
  double? triggerPrice;
  String? triggerImageUrl;
  List<UpsellRuleItemEntity> items = [];
}
