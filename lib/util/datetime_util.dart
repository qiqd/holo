/// 把 [dateTime] 转成“多久以前”的短文本
/// [dateTime]: 要格式化的日期时间对象
/// 返回格式化后的时间字符串
String formatTimeAgo(DateTime dateTime) {
  final now = DateTime.now();
  final diff = now.difference(dateTime);

  // 今天内
  if (diff.inDays == 0) {
    return '今天 ${dateTime.hour.toString().padLeft(2, '0')}:'
        '${dateTime.minute.toString().padLeft(2, '0')}';
  }
  // 几天内
  if (diff.inDays < 7) {
    return '${diff.inDays} 天前';
  }
  // 几周内
  if (diff.inDays < 30) {
    final weeks = (diff.inDays / 7).floor();
    return '$weeks 周前';
  }
  // 几个月内
  if (diff.inDays < 365) {
    final months = (diff.inDays / 30).floor();
    return '$months 个月前';
  }
  // 几年前
  final years = (diff.inDays / 365).floor();
  return '$years 年前';
}

/// 检查 [airDate] 距离现在有多少周
/// [airDate]: 播出日期字符串
/// 返回距离现在的周数，若解析失败则返回 -1
int checkUpdateAt(String? airDate) {
  try {
    var airTime = airDate != null ? DateTime.parse(airDate) : DateTime.now();
    var difference = DateTime.now().difference(airTime);
    return (difference.inDays / 7).toInt() + 1;
  } catch (e) {
    return -1;
  }
}