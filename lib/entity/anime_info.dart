class AnimeInfo {
  int id;
  String title;
  Image images;
  String summary;
  int ratingCount;
  double rating;
  int episodes;
  List<String> tags;
  String airTime;
}

class Image {
  final String small;
  final String medium;
  final String large;
  const Image({required this.small, required this.medium, required this.large});
}
