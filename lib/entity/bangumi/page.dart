class Page<T> {
  final int total;
  final int limit;
  final int offset;
  final List<T> data;

  Page({
    required this.total,
    required this.limit,
    required this.offset,
    required this.data,
  });
}
