class Episode {
  int id;
  String title;
  int number;
  String? description;
  Episode({
    required this.id,
    required this.title,
    required this.number,
    this.description,
  });
}
