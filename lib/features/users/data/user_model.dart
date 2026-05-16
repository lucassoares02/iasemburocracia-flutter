import 'package:portal_assoc/features/users/domain/entities/user_entity.dart';

class UserModel extends UserEntity {
  UserModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    type = json['type'];
    email = json['email'];
    active = json['active'];
    associates = json['associates'];
    createdAt = json['created_at'];
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'email': email,
      'active': active,
      'associates': associates,
      'created_at': createdAt,
    };
  }
}
