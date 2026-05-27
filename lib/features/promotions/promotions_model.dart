import 'promotions_entity.dart';

double? _toDouble(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  return double.tryParse('$v');
}

class PromotionItemModel extends PromotionItemEntity {
  PromotionItemModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    menuItemId = json['menu_item_id'];
    name = json['item_name'] ?? json['name'];
    imageUrl = json['image_url'];
    price = _toDouble(json['unit_price'] ?? json['price']);
    quantity = json['quantity'] ?? 1;
    subtotal = _toDouble(json['subtotal']);
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'menu_item_id': menuItemId,
        'quantity': quantity,
      };
}

class PromotionModel extends PromotionEntity {
  PromotionModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    companyId = json['company_id'];
    name = json['name'];
    description = json['description'];
    imageUrl = json['image_url'];
    active = json['active'] as bool? ?? true;
    originalPrice = _toDouble(json['original_price']);
    discountPercent = _toDouble(json['discount_percent']);
    finalPrice = _toDouble(json['final_price']);
    items = (json['items'] as List? ?? [])
        .map((e) => PromotionItemModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'company_id': companyId,
        'name': name,
        'description': description,
        'image_url': imageUrl,
        'active': active,
        'discount_percent': discountPercent,
        'final_price': finalPrice,
        'items': items.map((e) => (e as PromotionItemModel).toJson()).toList(),
      };
}
