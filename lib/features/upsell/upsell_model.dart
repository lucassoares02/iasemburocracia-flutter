import 'upsell_entity.dart';

double? _d(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  return double.tryParse('$v');
}

class UpsellRuleItemModel extends UpsellRuleItemEntity {
  UpsellRuleItemModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    menuItemId = json['menu_item_id'];
    discountType = json['discount_type'] ?? 'percent';
    discountValue = _d(json['discount_value']);
    finalPrice = _d(json['final_price']);
    displayOrder = json['display_order'] ?? 0;
    itemName = json['item_name'];
    itemPrice = _d(json['item_price']);
    itemImageUrl = json['item_image_url'];
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'menu_item_id': menuItemId,
        'discount_type': discountType ?? 'percent',
        'discount_value': discountValue ?? 0,
        'display_order': displayOrder,
      };
}

class UpsellRuleModel extends UpsellRuleEntity {
  UpsellRuleModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    companyId = json['company_id'];
    triggerItemId = json['trigger_item_id'];
    description = json['description'];
    active = json['active'] as bool? ?? true;
    maxSuggestions = json['max_suggestions'] ?? 3;
    triggerName = json['trigger_name'];
    triggerPrice = _d(json['trigger_price']);
    triggerImageUrl = json['trigger_image_url'];
    items = (json['items'] as List? ?? [])
        .map((e) => UpsellRuleItemModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'company_id': companyId,
        'trigger_item_id': triggerItemId,
        'description': description,
        'active': active,
        'max_suggestions': maxSuggestions,
        'items': items
            .map((e) => (e as UpsellRuleItemModel).toJson())
            .toList(),
      };
}

// Used in the public order flow
class UpsellSuggestionItemModel {
  final int menuItemId;
  final String itemName;
  final double itemPrice;
  final String? itemImageUrl;
  final String discountType;
  final double discountValue;
  final double finalPrice;
  final double discountPercent;

  const UpsellSuggestionItemModel({
    required this.menuItemId,
    required this.itemName,
    required this.itemPrice,
    required this.itemImageUrl,
    required this.discountType,
    required this.discountValue,
    required this.finalPrice,
    required this.discountPercent,
  });

  factory UpsellSuggestionItemModel.fromJson(Map<String, dynamic> json) {
    return UpsellSuggestionItemModel(
      menuItemId: json['menu_item_id'] as int,
      itemName: json['item_name'] ?? '',
      itemPrice: _d(json['item_price']) ?? 0,
      itemImageUrl: json['item_image_url'],
      discountType: json['discount_type'] ?? 'percent',
      discountValue: _d(json['discount_value']) ?? 0,
      finalPrice: _d(json['final_price']) ?? 0,
      discountPercent: _d(json['discount_percent']) ?? 0,
    );
  }
}

class UpsellSuggestionModel {
  final int ruleId;
  final String? description;
  final List<UpsellSuggestionItemModel> items;

  const UpsellSuggestionModel({
    required this.ruleId,
    required this.description,
    required this.items,
  });

  factory UpsellSuggestionModel.fromJson(Map<String, dynamic> json) {
    return UpsellSuggestionModel(
      ruleId: json['rule_id'] as int,
      description: json['description'],
      items: (json['items'] as List? ?? [])
          .map((e) => UpsellSuggestionItemModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
