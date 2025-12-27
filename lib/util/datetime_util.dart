/// 把 [dateTime] 转成“多久以前”的短文本
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
