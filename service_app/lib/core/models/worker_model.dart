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
    return WorkerModel(
      id: json['id'] as String,
      name: json['name'] as String,
      rating: (json['rating'] as num).toDouble(),
      reviews: json['reviews'] as int,
      distance: (json['distance'] as num).toDouble(),
      pricePerHour: json['pricePerHour'] as int,
      experience: json['experience'] as int,
      avatar: json['avatar'] as String,
      isAvailable: json['isAvailable'] as bool,
      skills: List<String>.from(json['skills'] as List),
      profileDescription: json['profileDescription'] as String,
      aboutReviews: List<Map<String, dynamic>>.from(
        (json['aboutReviews'] as List).map((x) => x as Map<String, dynamic>),
      ),
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