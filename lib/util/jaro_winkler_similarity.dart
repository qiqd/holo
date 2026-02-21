import 'dart:math';

/// Jaro-Winkler 相似度计算器
/// 计算两个字符串之间的 Jaro-Winkler 相似度分数（0.0 到 1.0）
class JaroWinklerSimilarity {
  /// 默认缩放因子，用于计算公共前缀的权重
  static const double _defaultScalingFactor = 0.1;

  /// 计算两个字符串的 Jaro-Winkler 相似度
  /// [left]: 第一个字符串
  /// [right]: 第二个字符串
  /// 返回相似度分数，范围从 0.0（完全不同）到 1.0（完全相同）
  /// 抛出 [ArgumentError] 如果任一输入为 null
  static double apply(String? left, String? right) {
    if (left == null || right == null) {
      throw ArgumentError('Strings must not be null');
    }

    if (left == right) {
      return 1.0;
    }

    final mtp = _matches(left, right);
    final double m = mtp[0].toDouble();
    if (m == 0) {
      return 0.0;
    }

    final double j = (m / left.length + m / right.length + (m - mtp[1] / 2) / m) / 3;

    if (j < 0.7) {
      return j;
    } else {
      return j + _defaultScalingFactor * mtp[2] * (1.0 - j);
    }
  }

  /// 计算两个字符串的匹配数、半换位数和公共前缀长度
  /// [first]: 第一个字符串
  /// [second]: 第二个字符串
  /// 返回包含三个元素的数组：[匹配数, 半换位数, 公共前缀长度]
  static List<int> _matches(String first, String second) {
    final maxStr = first.length > second.length ? first : second;
    final minStr = first.length > second.length ? second : first;

    // 计算搜索范围
    final int range = max(0, maxStr.length ~/ 2 - 1);

    // 存储匹配索引和标记
    final List<int> matchIndexes = List.filled(minStr.length, -1);
    final List<bool> matchFlags = List.filled(maxStr.length, false);

    int matches = 0;
    // 查找匹配字符
    for (int mi = 0; mi < minStr.length; mi++) {
      final char = minStr[mi];
      // 计算搜索窗口
      final int start = max(0, mi - range);
      final int end = min(mi + range + 1, maxStr.length);

      for (int xi = start; xi < end; xi++) {
        if (!matchFlags[xi] && char == maxStr[xi]) {
          matchIndexes[mi] = xi;
          matchFlags[xi] = true;
          matches++;
          break;
        }
      }
    }

    // 提取匹配字符
    final List<String> ms1 = [];
    final List<String> ms2 = [];

    for (int i = 0; i < minStr.length; i++) {
      if (matchIndexes[i] != -1) {
        ms1.add(minStr[i]);
      }
    }

    for (int i = 0; i < maxStr.length; i++) {
      if (matchFlags[i]) {
        ms2.add(maxStr[i]);
      }
    }

    // 计算半换位数
    int halfTranspositions = 0;
    for (int i = 0; i < ms1.length; i++) {
      if (ms1[i] != ms2[i]) {
        halfTranspositions++;
      }
    }

    // 计算公共前缀长度（最多4个字符）
    int prefix = 0;
    final int prefixLimit = min(4, minStr.length);
    for (int i = 0; i < prefixLimit; i++) {
      if (first[i] != second[i]) break;
      prefix++;
    }

    return [matches, halfTranspositions, prefix];
  }
}