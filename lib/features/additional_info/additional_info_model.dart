import 'additional_info_entity.dart';

class AdditionalInfoModel extends AdditionalInfoEntity {
  AdditionalInfoModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    companyId = json['company_id'];
    title = json['title'];
    content = json['content'];
    category = json['category'];
    triggerKeywords = json['trigger_keywords'];
    visibility = json['visibility'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['company_id'] = companyId;
    data['title'] = title;
    data['content'] = content;
    data['category'] = category;
    data['trigger_keywords'] = triggerKeywords;
    data['visibility'] = visibility;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    return data;
  }
}
