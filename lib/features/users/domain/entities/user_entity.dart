class UserEntity {
  int? id;
  String? name;
  int? type;
  String? email;
  bool? active;
  String? createdAt;
  String? associates;

  UserEntity({
    this.id,
    this.name,
    this.type,
    this.email,
    this.active,
    this.createdAt,
    this.associates,
  });
}
