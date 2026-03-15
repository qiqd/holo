import 'package:holo/entity/image.dart';

class User {
  final int id;
  final String nickname;
  final String username;
  final Image avatar;
  User({
    required this.id,
    required this.nickname,
    required this.username,
    required this.avatar,
  });
}
