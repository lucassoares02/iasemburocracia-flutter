import 'package:portal_assoc/features/auth/domain/access_token_entity.dart';

class UserModel extends UserEntity {
  UserModel({
    required int id,
    required String name,
    required String email,
    required int type,
    required String accessToken,
    required bool active,
  }) : super(
          id: id,
          name: name,
          email: email,
          type: type,
          accessToken: accessToken,
          active: active,
        );
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      accessToken: json['token'] ?? "",
      id: json['user']['id'] ?? 0,
      name: json['user']['name'] ?? "",
      type: json['user']['type'] ?? 0,
      email: json['user']['email'] ?? "",
      active: json['user']['active'] ?? false,
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'type': type,
      'accessToken': accessToken,
      'active': active,
    };
  }
}
