class WorkerModel {
  final String id;
  final String name;
  final double rating;
  final int reviews;
  final double distance;
  final int pricePerHour;
  final int experience;
  final String avatar;
  final bool isAvailable;
  final List<String> skills;
  final String profileDescription;
  final List<Map<String, dynamic>> aboutReviews;

  WorkerModel({
    required this.id,
    required this.name,
    required this.rating,
    required this.reviews,
    required this.distance,
    required this.pricePerHour,
    required this.experience,
    required this.avatar,
    required this.isAvailable,
    required this.skills,
    required this.profileDescription,
    required this.aboutReviews,
  });

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'rating': rating,
      'reviews': reviews,
      'distance': distance,
      'pricePerHour': pricePerHour,
      'experience': experience,
      'avatar': avatar,
      'isAvailable': isAvailable,
      'skills': skills,
      'profileDescription': profileDescription,
      'aboutReviews': aboutReviews,
    };
  }

  // Convert from JSON
  factory WorkerModel.fromJson(Map<String, dynamic> json) {
    final reviewsJson = (json['reviews'] ?? json['aboutReviews'] ?? <dynamic>[]) as List<dynamic>;
    final parsedReviews = reviewsJson
        .map(
          (item) => {
            'name': (item as Map<String, dynamic>)['user']?.toString() ??
                item['name']?.toString() ??
                'User',
            'rating': (item['rating'] as num?)?.toInt() ?? 5,
            'comment': item['comment']?.toString() ?? '',
            'date': item['date']?.toString() ?? 'Recently',
          },
        )
        .toList();

    final name = (json['name'] ?? '').toString();
    final initials = name
        .split(' ')
        .where((e) => e.isNotEmpty)
        .take(2)
        .map((e) => e[0].toUpperCase())
        .join();

    return WorkerModel(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      name: name,
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      reviews: (json['reviewsCount'] as num?)?.toInt() ?? parsedReviews.length,
      distance: (json['distance'] as num?)?.toDouble() ?? 0,
      pricePerHour: (json['pricePerHour'] as num?)?.toInt() ??
          (json['price'] as num?)?.toInt() ??
          0,
      experience: (json['experience'] as num?)?.toInt() ?? 0,
      avatar: (json['avatar'] ?? initials).toString(),
      isAvailable: (json['isAvailable'] as bool?) ?? true,
      skills: List<String>.from((json['skills'] ?? <dynamic>[]) as List<dynamic>),
      profileDescription: (json['profileDescription'] ?? 'No description available').toString(),
      aboutReviews: parsedReviews,
    );
  }

  // Copy with method for creating modified instances
  WorkerModel copyWith({
    String? id,
    String? name,
    double? rating,
    int? reviews,
    double? distance,
    int? pricePerHour,
    int? experience,
    String? avatar,
    bool? isAvailable,
    List<String>? skills,
    String? profileDescription,
    List<Map<String, dynamic>>? aboutReviews,
  }) {
    return WorkerModel(
      id: id ?? this.id,
      name: name ?? this.name,
      rating: rating ?? this.rating,
      reviews: reviews ?? this.reviews,
      distance: distance ?? this.distance,
      pricePerHour: pricePerHour ?? this.pricePerHour,
      experience: experience ?? this.experience,
      avatar: avatar ?? this.avatar,
      isAvailable: isAvailable ?? this.isAvailable,
      skills: skills ?? this.skills,
      profileDescription: profileDescription ?? this.profileDescription,
      aboutReviews: aboutReviews ?? this.aboutReviews,
    );
  }

  @override
  String toString() => 'WorkerModel(id: $id, name: $name, rating: $rating)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorkerModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name;

  @override
  int get hashCode => id.hashCode ^ name.hashCode;
}