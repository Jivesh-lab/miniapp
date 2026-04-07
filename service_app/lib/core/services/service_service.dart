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
    final response = await http.get(
      ApiService.uri('/services'),
      headers: ApiService.headers,
    );

    final body = ApiService.parseResponse(response);
    final data = (body['data'] as List<dynamic>? ?? <dynamic>[])
        .cast<Map<String, dynamic>>();

    return data.map(ServiceItem.fromJson).toList();
  }
}
