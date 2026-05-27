import 'package:portal_assoc/features/menu_items/menu_items_entity.dart';

class MenuItemsModel extends MenuItemsEntity {
  MenuItemsModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    companyId = json['company_id'];
    categoryId = json['category_id'];
    name = json['name'];
    description = json['description'];
    price = json['price'] != null ? (json['price'] as num).toDouble() : null;
    available = json['available'];
    imageUrl = json['image_url'];
    featured = json['featured'];
    displayOrder = json['display_order'];
    prepTimeMinutes = json['prep_time_minutes'];
    sku = json['sku'];
    categoryName = json['category_name'];
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'company_id': companyId,
      'category_id': categoryId,
      'name': name,
      'description': description,
      'price': price,
      'available': available,
      'image_url': imageUrl,
      'featured': featured,
      'display_order': displayOrder,
      'prep_time_minutes': prepTimeMinutes,
      'sku': sku,
      'category_name': categoryName,
    };
  }
}
