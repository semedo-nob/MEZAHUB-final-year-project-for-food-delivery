class Restaurant {
  final String id;
  final String name;
  final String? description;
  final String? address;
  final String? cuisineType;
  final double? rating;
  final int? totalRatings;
  final String? imageUrl;
  final double? deliveryFee;
  final double? minimumOrder;
  final int? deliveryTime;
  final bool? isOpen;
  final String? openingTime;
  final String? closingTime;
  final double? latitude;
  final double? longitude;

  Restaurant({
    required this.id,
    required this.name,
    this.description,
    this.address,
    this.cuisineType,
    this.rating,
    this.totalRatings,
    this.imageUrl,
    this.deliveryFee,
    this.minimumOrder,
    this.deliveryTime,
    this.isOpen,
    this.openingTime,
    this.closingTime,
    this.latitude,
    this.longitude,
  });

  factory Restaurant.fromJson(Map<String, dynamic> json) {
    return Restaurant(
      id: json['id'].toString(),
      name: json['name'] ?? '',
      description: json['description'],
      address: json['address'],
      cuisineType: json['cuisine_type'],
      rating: json['rating'] != null ? (json['rating'] as num).toDouble() : null,
      totalRatings: json['total_ratings'],
      imageUrl: json['cover_image'] ?? json['image_url'],
      deliveryFee:
          json['delivery_fee'] != null ? (json['delivery_fee'] as num).toDouble() : null,
      minimumOrder: json['minimum_order'] != null
          ? (json['minimum_order'] as num).toDouble()
          : null,
      deliveryTime: json['delivery_time'] ?? 30,
      isOpen: json['is_open'] ?? true,
      openingTime: json['opening_time'],
      closingTime: json['closing_time'],
      latitude:
          json['latitude'] != null ? (json['latitude'] as num).toDouble() : null,
      longitude:
          json['longitude'] != null ? (json['longitude'] as num).toDouble() : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'address': address,
      'cuisine_type': cuisineType,
      'rating': rating,
      'total_ratings': totalRatings,
      'cover_image': imageUrl,
      'delivery_fee': deliveryFee,
      'minimum_order': minimumOrder,
      'delivery_time': deliveryTime,
      'is_open': isOpen,
      'opening_time': openingTime,
      'closing_time': closingTime,
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}

