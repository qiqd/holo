import 'package:hive_ce/hive.dart';

part 'user_playback.g.dart';

@HiveType(typeId: 1)
class UserPlayback {
  @HiveField(0)
  final int id;
  @HiveField(1)
  final String email;
  @HiveField(2)
  final String title;
  @HiveField(3)
  final String imgUrl;
  @HiveField(4)
  final DateTime lastPlaybackAt;
  @HiveField(5)
  final DateTime createdAt;
  @HiveField(6)
  final int position;
  @HiveField(7)
  final int episodeIndex;
  @HiveField(8)
  final int lineIndex;
  @HiveField(9)
  final bool isSync;

  const UserPlayback({
    required this.id,
    required this.email,
    required this.title,
    required this.imgUrl,
    required this.lastPlaybackAt,
    required this.createdAt,
    required this.position,
    required this.episodeIndex,
    required this.lineIndex,
    required this.isSync,
  });

  UserPlayback copyWith({
    int? id,
    String? email,
    String? title,
    String? imgUrl,
    DateTime? lastPlaybackAt,
    DateTime? createdAt,
    int? position,
    int? episodeIndex,
    int? lineIndex,
    bool? isSync,
  }) {
    return UserPlayback(
      id: id ?? this.id,
      email: email ?? this.email,
      title: title ?? this.title,
      imgUrl: imgUrl ?? this.imgUrl,
      lastPlaybackAt: lastPlaybackAt ?? this.lastPlaybackAt,
      createdAt: createdAt ?? this.createdAt,
      position: position ?? this.position,
      episodeIndex: episodeIndex ?? this.episodeIndex,
      lineIndex: lineIndex ?? this.lineIndex,
      isSync: isSync ?? this.isSync,
    );
  }

  factory UserPlayback.fromJson(Map<String, dynamic> map) {
    return UserPlayback(
      id: map['id'],
      email: map['email'],
      title: map['title'],
      imgUrl: map['imgUrl'],
      lastPlaybackAt: DateTime.parse(map['lastPlaybackAt']),
      createdAt: DateTime.parse(map['createdAt']),
      position: map['position'],
      episodeIndex: map['episodeIndex'],
      lineIndex: map['lineIndex'],
      isSync: map['isSync'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'title': title,
      'imgUrl': imgUrl,
      'lastPlaybackAt': lastPlaybackAt.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'position': position,
      'episodeIndex': episodeIndex,
      'lineIndex': lineIndex,
      'isSync': isSync,
    };
  }
}
