import 'package:portal_assoc/features/company_opening_hours/company_opening_hours_entity.dart';

class CompanyOpeningHoursModel extends CompanyOpeningHoursEntity {
  CompanyOpeningHoursModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    companyId = json['company_id'];
    weekday = json['weekday'];
    opensAt = json['opens_at'];
    closesAt = json['closes_at'];
    isClosed = json['is_closed'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['company_id'] = companyId;
    data['weekday'] = weekday;
    data['opens_at'] = opensAt;
    data['closes_at'] = closesAt;
    data['is_closed'] = isClosed;
    return data;
  }
}
