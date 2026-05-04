import 'package:hive_ce/hive.dart';

part 'user.g.dart';

@HiveType(typeId: 9)
class User {
  @HiveField(0)
  final String email;
  @HiveField(1)
  final String serverUrl;
  @HiveField(2)
  final String secret;
  @HiveField(3)
  final bool isLogin;
  const User({
    required this.serverUrl,
    required this.email,
    required this.secret,
    this.isLogin = false,
  });

  factory User.fromJson(Map<String, dynamic> map) {
    return User(
      serverUrl: map['serverUrl'],
      email: map['email'],
      secret: map['secret'],
      isLogin: map['isLogin'] == 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'serverUrl': serverUrl,
      'email': email,
      'secret': secret,
      'isLogin': isLogin ? 1 : 0,
    };
  }
}
