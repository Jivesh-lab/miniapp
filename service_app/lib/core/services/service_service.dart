import 'package:http/http.dart' as http;

import 'api_service.dart';

class ServiceItem {
  final String id;
  final String name;

  ServiceItem({
    required this.id,
    required this.name,
  });

  factory ServiceItem.fromJson(Map<String, dynamic> json) {
    return ServiceItem(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      name: (json['name'] ?? json['title'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }
}

class ServiceService {
  Future<List<ServiceItem>> getServices() async {
    try {
      final response = await ApiService.getJson('/services', useAuthHeaders: true);
      final body = await ApiService.parseAuthenticatedResponse(
        response,
        clearSession: ApiService.clearUserSession,
        loginRoute: '/login',
      );
      final data = (body['data'] as List<dynamic>? ?? <dynamic>[])
          .cast<Map<String, dynamic>>();

      return data.map(ServiceItem.fromJson).toList();
    } catch (error) {
      if (error is Exception) {
        rethrow;
      }
      throw Exception('Failed to load services');
    }
  }
}
