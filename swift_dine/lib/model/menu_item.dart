class MenuItem {
  final String id;
  final String name;
  final String description;
  final double price;
  final String image;
  final String category;
  final bool featured;
  final List<String> dietary;
  final double? rating;
  final int? reviews;
  final int? preparationTime;
  final List<String>? ingredients;
  final List<String>? allergens;
  bool isFavourite;

  MenuItem({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.image,
    required this.category,
    this.featured = false,
    this.dietary = const [],
    this.rating,
    this.reviews,
    this.preparationTime,
    this.ingredients,
    this.allergens,
    this.isFavourite = false,
  });

  // Add copyWith method for updating favorite status
  MenuItem copyWith({
    bool? isFavourite,
  }) {
    return MenuItem(
      id: id,
      name: name,
      description: description,
      price: price,
      image: image,
      category: category,
      featured: featured,
      dietary: dietary,
      rating: rating,
      reviews: reviews,
      preparationTime: preparationTime,
      ingredients: ingredients,
      allergens: allergens,
      isFavourite: isFavourite ?? this.isFavourite,
    );
  }

  @override
  String toString() {
    return 'MenuItem(id: $id, name: $name, price: $price, isFavourite: $isFavourite)';
  }

  // Convert to Map for database
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'image': image,
      'category': category,
      'featured': featured ? 1 : 0,
      'dietary': dietary.join(','),
      'rating': rating,
      'reviews': reviews,
      'preparationTime': preparationTime,
      'ingredients': ingredients?.join(','),
      'allergens': allergens?.join(','),
      'isFavourite': isFavourite ? 1 : 0,
    };
  }

  // Create from Map for database
  factory MenuItem.fromMap(Map<String, dynamic> map) {
    return MenuItem(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      price: map['price'],
      image: map['image'],
      category: map['category'],
      featured: map['featured'] == 1,
      dietary: (map['dietary'] as String? ?? '').split(',').where((e) => e.isNotEmpty).toList(),
      rating: map['rating'],
      reviews: map['reviews'],
      preparationTime: map['preparationTime'],
      ingredients: (map['ingredients'] as String? ?? '').split(',').where((e) => e.isNotEmpty).toList(),
      allergens: (map['allergens'] as String? ?? '').split(',').where((e) => e.isNotEmpty).toList(),
      isFavourite: map['isFavourite'] == 1,
    );
  }
}