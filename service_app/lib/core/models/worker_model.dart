class WorkerSlot {
  final String date;
  final List<String> timeSlots;

  WorkerSlot({
    required this.date,
    required this.timeSlots,
  });

  factory WorkerSlot.fromJson(Map<String, dynamic> json) {
    return WorkerSlot(
      date: (json['date'] ?? '').toString(),
      timeSlots: List<String>.from((json['timeSlots'] ?? <dynamic>[]) as List<dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'timeSlots': timeSlots,
    };
  }
}

class WorkerModel {
  final String id;
  final String name;
  final double rating;
  final int reviews;
  final double? distance;
  final String? distanceFormatted;
  final int pricePerHour;
  final int experience;
  final String avatar;
  final bool isAvailable;
  final bool isOnline;
  final DateTime? lastLocationUpdate;
  final List<String> skills;
  final String profileDescription;
  final List<Map<String, dynamic>> aboutReviews;
  final List<WorkerSlot> availableSlots;

  WorkerModel({
    required this.id,
    required this.name,
    required this.rating,
    required this.reviews,
    required this.distance,
    required this.distanceFormatted,
    required this.pricePerHour,
    required this.experience,
    required this.avatar,
    required this.isAvailable,
    required this.isOnline,
    required this.lastLocationUpdate,
    required this.skills,
    required this.profileDescription,
    required this.aboutReviews,
    required this.availableSlots,
  });

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'rating': rating,
      'reviews': reviews,
      'distance': distance,
      'distanceFormatted': distanceFormatted,
      'pricePerHour': pricePerHour,
      'experience': experience,
      'avatar': avatar,
      'isAvailable': isAvailable,
      'isOnline': isOnline,
      'lastLocationUpdate': lastLocationUpdate?.toIso8601String(),
      'skills': skills,
      'profileDescription': profileDescription,
      'aboutReviews': aboutReviews,
      'availableSlots': availableSlots.map((e) => e.toJson()).toList(),
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
    final parsedLastLocationUpdate = DateTime.tryParse(
      (json['lastLocationUpdate'] ?? '').toString(),
    );
    final parsedIsOnline =
        (json['isOnline'] as bool?) ?? (json['isAvailable'] as bool?) ?? false;

    return WorkerModel(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      name: name,
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      reviews: (json['reviewsCount'] as num?)?.toInt() ?? parsedReviews.length,
      distance: (json['distance'] as num?)?.toDouble(),
      distanceFormatted: (json['distanceFormatted'] ?? json['distanceLabel'])?.toString(),
      pricePerHour: (json['pricePerHour'] as num?)?.toInt() ??
          (json['price'] as num?)?.toInt() ??
          0,
      experience: (json['experience'] as num?)?.toInt() ?? 0,
      avatar: (json['avatar'] ?? initials).toString(),
      isAvailable: parsedIsOnline,
      isOnline: parsedIsOnline,
      lastLocationUpdate: parsedLastLocationUpdate,
      skills: List<String>.from((json['skills'] ?? <dynamic>[]) as List<dynamic>),
      profileDescription: (json['profileDescription'] ?? 'No description available').toString(),
      aboutReviews: parsedReviews,
      availableSlots: ((json['availableSlots'] ?? <dynamic>[]) as List<dynamic>)
          .map((item) => WorkerSlot.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  // Copy with method for creating modified instances
  WorkerModel copyWith({
    String? id,
    String? name,
    double? rating,
    int? reviews,
    double? distance,
    String? distanceFormatted,
    int? pricePerHour,
    int? experience,
    String? avatar,
    bool? isAvailable,
    bool? isOnline,
    DateTime? lastLocationUpdate,
    List<String>? skills,
    String? profileDescription,
    List<Map<String, dynamic>>? aboutReviews,
    List<WorkerSlot>? availableSlots,
  }) {
    return WorkerModel(
      id: id ?? this.id,
      name: name ?? this.name,
      rating: rating ?? this.rating,
      reviews: reviews ?? this.reviews,
      distance: distance ?? this.distance,
      distanceFormatted: distanceFormatted ?? this.distanceFormatted,
      pricePerHour: pricePerHour ?? this.pricePerHour,
      experience: experience ?? this.experience,
      avatar: avatar ?? this.avatar,
      isAvailable: isAvailable ?? this.isAvailable,
      isOnline: isOnline ?? this.isOnline,
      lastLocationUpdate: lastLocationUpdate ?? this.lastLocationUpdate,
      skills: skills ?? this.skills,
      profileDescription: profileDescription ?? this.profileDescription,
      aboutReviews: aboutReviews ?? this.aboutReviews,
      availableSlots: availableSlots ?? this.availableSlots,
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