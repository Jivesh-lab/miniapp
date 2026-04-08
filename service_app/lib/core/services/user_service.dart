import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/worker_model.dart';
import 'api_service.dart';

class UserService {
  Future<bool> toggleFavorite({
    required String userId,
    required String workerId,
  }) async {
    final response = await http.post(
      ApiService.uri('/users/favorites'),
      headers: ApiService.headers,
      body: jsonEncode({'userId': userId, 'workerId': workerId}),
    );

    final body = ApiService.parseResponse(response);
    return body['isFavorite'] == true;
  }

  Future<List<WorkerModel>> getFavoriteWorkers(String userId) async {
    final response = await http.get(
      ApiService.uri('/users/favorites/$userId'),
      headers: ApiService.headers,
    );

    final body = ApiService.parseResponse(response);
    final data = (body['data'] as List<dynamic>? ?? <dynamic>[])
        .cast<Map<String, dynamic>>();

    return data.map(WorkerModel.fromJson).toList();
  }
}
