import 'package:portal_assoc/features/menu_categories/menu_categories_entity.dart';

class MenuCategoriesModel extends MenuCategoriesEntity {
  MenuCategoriesModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    companyId = json['company_id'];
    name = json['name'];
    sortOrder = json['sort_order'];
    active = json['active'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['company_id'] = companyId;
    data['name'] = name;
    data['sort_order'] = sortOrder;
    data['active'] = active;
    return data;
  }
}
