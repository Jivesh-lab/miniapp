import 'package:http/http.dart' as http;

import '../models/worker_model.dart';
import 'api_service.dart';

Map<String, String> buildWorkerQueryParams({
  Object? sort,
  Object? q,
  Object? rating,
  Object? minPrice,
  Object? maxPrice,
  Object? page,
  Object? limit,
}) {
  final query = <String, String>{};

  final pageValue = _parseIntParam(page, min: 1);
  final limitValue = _parseIntParam(limit, min: 1);

  query['page'] = (pageValue ?? 1).toString();
  query['limit'] = (limitValue ?? 20).toString();

  final sortValue = _parseSortParam(sort);
  if (sortValue != null) {
    query['sort'] = sortValue;
  }

  final queryText = _parseTextParam(q);
  if (queryText != null) {
    query['q'] = queryText;
  }

  final ratingValue = _parseDoubleParam(rating, min: 0, max: 5);
  if (ratingValue != null) {
    query['rating'] = _numToString(ratingValue);
  }

  final minPriceValue = _parseDoubleParam(minPrice, min: 0);
  if (minPriceValue != null) {
    query['minPrice'] = _numToString(minPriceValue);
  }

  final maxPriceValue = _parseDoubleParam(maxPrice, min: 0);
  if (maxPriceValue != null) {
    query['maxPrice'] = _numToString(maxPriceValue);
  }

  return query;
}

String? _parseTextParam(Object? value) {
  if (value == null) return null;
  final text = value.toString().trim();
  if (text.isEmpty || text == '{}' || text == 'null') return null;
  return text;
}

String? _parseSortParam(Object? value) {
  final text = _parseTextParam(value)?.toLowerCase();
  if (text == 'rating' || text == 'price' || text == '-rating' || text == '-price') {
    return text;
  }
  return null;
}

int? _parseIntParam(Object? value, {int? min, int? max}) {
  final text = _parseTextParam(value);
  if (text == null) return null;

  try {
    final parsed = int.parse(text);
    if (min != null && parsed < min) return null;
    if (max != null && parsed > max) return null;
    return parsed;
  } catch (_) {
    return null;
  }
}

double? _parseDoubleParam(Object? value, {double? min, double? max}) {
  final text = _parseTextParam(value);
  if (text == null) return null;

  try {
    final parsed = double.parse(text);
    if (!parsed.isFinite) return null;
    if (min != null && parsed < min) return null;
    if (max != null && parsed > max) return null;
    return parsed;
  } catch (_) {
    return null;
  }
}

String _numToString(num value) {
  return value % 1 == 0 ? value.toInt().toString() : value.toString();
}

class WorkerService {
  Future<List<WorkerModel>> getWorkers({
    required String serviceId,
    String? sort,
    String? q,
    double? rating,
    int? minPrice,
    int? maxPrice,
    int page = 1,
    int limit = 20,
  }) async {
    final query = buildWorkerQueryParams(
      sort: sort,
      q: q,
      rating: rating,
      minPrice: minPrice,
      maxPrice: maxPrice,
      page: page,
      limit: limit,
    );

    final path = serviceId.trim().isEmpty ? '/workers/search' : '/workers/$serviceId';

    // Example: final response = await http.get(ApiService.uri('/workers', buildWorkerQueryParams(...)));
    final response = await http.get(
      ApiService.uri(path, query.isEmpty ? null : query),
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

  Future<Map<String, dynamic>> getWorkerSlots({
    required String workerId,
    required String date,
  }) async {
    final response = await http.get(
      ApiService.uri('/workers/$workerId/slots', {'date': date}),
      headers: ApiService.headers,
    );

    final body = ApiService.parseResponse(response);

    // Supports current endpoint shape and older nested `data` shape.
    if (body['data'] is Map<String, dynamic>) {
      return (body['data'] as Map<String, dynamic>?) ?? <String, dynamic>{};
    }

    return {
      'availableSlots': body['availableSlots'] ?? <dynamic>[],
      'bookedSlots': body['bookedSlots'] ?? <dynamic>[],
      'allSlots': body['allSlots'] ?? body['availableSlots'] ?? <dynamic>[],
    };
  }
}
