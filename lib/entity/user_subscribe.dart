import 'package:flutter/material.dart';
import 'package:hive_ce/hive.dart';

part 'user_subscribe.g.dart';

@HiveType(typeId: 0)
@immutable
class UserSubscribe {
  @HiveField(0)
  final int id;
  @HiveField(1)
  final String email;
  @HiveField(2)
  final String title;
  @HiveField(3)
  final String imgUrl;
  @HiveField(4)
  final DateTime createdAt;
  @HiveField(5)
  final bool isSync;
  @HiveField(6)
  final int viewingStatus;

  const UserSubscribe({
    required this.id,
    required this.email,
    required this.title,
    required this.imgUrl,
    required this.createdAt,
    required this.isSync,
    required this.viewingStatus,
  });
  UserSubscribe copyWith({
    int? id,
    int? subId,
    String? email,
    String? title,
    String? imgUrl,
    DateTime? createdAt,
    bool? isSync,
    int? viewingStatus,
  }) {
    return UserSubscribe(
      id: id ?? this.id,
      email: email ?? this.email,
      title: title ?? this.title,
      imgUrl: imgUrl ?? this.imgUrl,
      createdAt: createdAt ?? DateTime(2022, 6, 20),
      isSync: isSync ?? false,
      viewingStatus: viewingStatus ?? 0,
    );
  }

  factory UserSubscribe.fromJson(Map<String, dynamic> map) {
    return UserSubscribe(
      id: map['id'],
      email: map['email'],
      title: map['title'],
      imgUrl: map['imgUrl'],
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime(2022, 6, 20),
      isSync: map['isSync'] == 1,
      viewingStatus: map['viewingStatus'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'title': title,
      'imgUrl': imgUrl,
      'createdAt': createdAt.toIso8601String(),
      'isSync': isSync ? 1 : 0,
      'viewingStatus': viewingStatus,
    };
  }
}
