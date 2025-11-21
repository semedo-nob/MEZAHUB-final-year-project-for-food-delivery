import 'dart:ui';

class Category {
  final String id;
  final String name;
  final String icon;
  final Color color;

  const Category({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
  });

  @override
  String toString() {
    return 'Category(id: $id, name: $name)';
  }

  // Convert to Map for database
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'color': color.r,
    };
  }

  // Create from Map for database
  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'],
      name: map['name'],
      icon: map['icon'],
      color: Color(map['color']),
    );
  }
}