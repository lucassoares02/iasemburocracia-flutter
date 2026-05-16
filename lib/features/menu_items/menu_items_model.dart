import 'package:portal_assoc/features/menu_items/menu_items_entity.dart';

class MenuItemsModel extends MenuItemsEntity {
  MenuItemsModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    companyId = json['company_id'];
    categoryId = json['category_id'];
    name = json['name'];
    description = json['description'];
    price = json['price'];
    available = json['available'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['company_id'] = companyId;
    data['category_id'] = categoryId;
    data['name'] = name;
    data['description'] = description;
    data['price'] = price;
    data['available'] = available;
    return data;
  }
}
