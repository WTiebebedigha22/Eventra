class Category {
  final String id;
  final String name;
  final String image;

  Category({
    required this.id,
    required this.name,
    required this.image,
  });

  factory Category.fromMap(Map<String, dynamic> data, String id) {
    return Category(
      id: id,
      name: data['name'],
      image: data['image'],
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'image': image,
      };
}
