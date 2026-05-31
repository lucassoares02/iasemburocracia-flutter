class UserEntity {
  final int id;
  final String name;
  final String email;
  final int type;
  final String accessToken;
  final bool active;
  final int company;

  UserEntity({
    required this.id,
    required this.name,
    required this.email,
    required this.type,
    required this.accessToken,
    required this.active,
    required this.company,
  });
}
