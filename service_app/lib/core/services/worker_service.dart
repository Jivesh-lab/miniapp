import 'package:http/http.dart' as http;

import '../models/worker_model.dart';
import 'api_service.dart';

class WorkerService {
  Future<List<WorkerModel>> getWorkers({
    required String serviceId,
    String? sort,
  }) async {
    final query = <String, String>{};
    if (sort == 'rating' || sort == 'price') {
      query['sort'] = sort;
    }

    final response = await http.get(
      ApiService.uri('/workers/$serviceId', query.isEmpty ? null : query),
      headers: ApiService.headers,
    );

    final body = ApiService.parseResponse(response);
    final data = (body['data'] as List<dynamic>? ?? <dynamic>[])
        .cast<Map<String, dynamic>>();

    return data.map(WorkerModel.fromJson).toList();
  }

  Future<WorkerModel> getWorkerById(String id) async {
    final response = await http.get(
      ApiService.uri('/workers/detail/$id'),
      headers: ApiService.headers,
    );

    final body = ApiService.parseResponse(response);
    final data = body['data'] as Map<String, dynamic>;
    return WorkerModel.fromJson(data);
  }
}
