import 'package:portal_assoc/features/default/domain/entities/default_entity.dart';

class DefaultModel extends DefaultEntity {
  DefaultModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    return data;
  }
}
