import 'account_entity.dart';

class AccountModel extends AccountEntity {
  AccountModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    email = json['email'];
    active = json['active'];
    createdAt = json['created_at'];
    phone = json['phone'];
    document = json['document'];
    birthday = json['birthday'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    data['email'] = email;
    data['active'] = active;
    data['created_at'] = createdAt;
    data['phone'] = phone;
    data['document'] = document;
    data['birthday'] = birthday;
    return data;
  }
}
