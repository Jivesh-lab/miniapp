class UserDataModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String role;
  final String? token;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  UserDataModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    this.token,
    this.createdAt,
    this.updatedAt,
  });

  /// Convert from JSON (API response)
  factory UserDataModel.fromJson(Map<String, dynamic> json) {
    return UserDataModel(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      phone: (json['phone'] ?? '').toString(),
      role: (json['role'] ?? 'user').toString(),
      token: json['token']?.toString(),
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt'].toString()) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt'].toString()) : null,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'role': role,
      'token': token,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  /// Copy with method
  UserDataModel copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? role,
    String? token,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserDataModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      token: token ?? this.token,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Get user initials for avatar
  String get initials {
    return name
        .split(' ')
        .where((e) => e.isNotEmpty)
        .take(2)
        .map((e) => e[0].toUpperCase())
        .join();
  }

  @override
  String toString() => 'UserDataModel(id: $id, name: $name, email: $email, phone: $phone, role: $role)';
}
