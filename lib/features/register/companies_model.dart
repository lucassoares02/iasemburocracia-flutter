import 'package:portal_assoc/core/utils/capitalize_words.dart';

import 'companies_entity.dart';

class CompaniesModel extends CompaniesEntity {
  CompaniesModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = capitalizeWords(json['name'] ?? '');
    description = json['description'];
    phone = json['phone'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    data['description'] = description;
    data['phone'] = phone;

    return data;
  }
}
