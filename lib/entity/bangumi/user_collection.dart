class UserCollection {
  final int id;

  /// 收藏状态
  /// 1: 想看
  /// 2: 看过
  /// 3: 在看
  /// 4: 搁置
  /// 5: 抛弃
  final int watchStatus;
  final String name;
  final String cover;
  const UserCollection({
    required this.id,
    required this.watchStatus,
    required this.name,
    required this.cover,
  });
}
