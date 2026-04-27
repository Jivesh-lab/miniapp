import 'dart:async';
import 'dart:io';

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
  Object? userLatitude,
  Object? userLongitude,
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

  final userLatitudeValue = _parseDoubleParam(userLatitude);
  if (userLatitudeValue != null) {
    query['userLatitude'] = _numToString(userLatitudeValue);
  }

  final userLongitudeValue = _parseDoubleParam(userLongitude);
  if (userLongitudeValue != null) {
    query['userLongitude'] = _numToString(userLongitudeValue);
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

class WorkerListResponse {
  final List<WorkerModel> workers;
  final bool isFallback;

  WorkerListResponse({
    required this.workers,
    this.isFallback = false,
  });
}

class WorkerService {
  Future<WorkerListResponse> getNearbyWorkers({
    required String serviceId,
    required double latitude,
    required double longitude,
    String? q,
    double? rating,
    int? minPrice,
    int? maxPrice,
    int page = 1,
    int limit = 1000,
  }) async {
    try {
      final query = buildWorkerQueryParams(
        q: q,
        rating: rating,
        minPrice: minPrice,
        maxPrice: maxPrice,
        page: page,
        limit: limit,
      );
      query['lat'] = _numToString(latitude);
      query['lng'] = _numToString(longitude);
      if (serviceId.trim().isNotEmpty) {
        query['serviceId'] = serviceId.trim();
      }

      final response = await http
          .get(
            ApiService.uri('/workers/nearby', query),
            headers: await ApiService.authHeaders(),
          )
          .timeout(ApiService.requestTimeout);

      final body = await ApiService.parseAuthenticatedResponse(
        response,
        clearSession: ApiService.clearUserSession,
        loginRoute: '/login',
      );
      final data = (body['data'] as List<dynamic>? ?? <dynamic>[])
          .cast<Map<String, dynamic>>();
      
      final isFallback = body['isFallback'] == true;

      return WorkerListResponse(
        workers: data.map(WorkerModel.fromJson).toList(),
        isFallback: isFallback,
      );
    } on TimeoutException {
      throw Exception('Network timeout, please try again');
    } on SocketException {
      throw Exception('Network error, please check your connection');
    }
  }

  Future<WorkerListResponse> getWorkers({
    required String serviceId,
    String? sort,
    String? q,
    double? rating,
    int? minPrice,
    int? maxPrice,
    int page = 1,
    int limit = 1000,
    double? userLatitude,
    double? userLongitude,
  }) async {
    try {
      final query = buildWorkerQueryParams(
        sort: sort,
        q: q,
        rating: rating,
        minPrice: minPrice,
        maxPrice: maxPrice,
        page: page,
        limit: limit,
        userLatitude: userLatitude,
        userLongitude: userLongitude,
      );

      final hasLocation = userLatitude != null && userLongitude != null;
      final normalizedServiceId = serviceId.trim();

      if (hasLocation) {
        return getNearbyWorkers(
          serviceId: normalizedServiceId,
          latitude: userLatitude,
          longitude: userLongitude,
          q: q,
          rating: rating,
          minPrice: minPrice,
          maxPrice: maxPrice,
          page: page,
          limit: limit,
        );
      }

      final path = normalizedServiceId.isEmpty ? '/workers/search' : '/workers/$normalizedServiceId';

      final response = await http
          .get(
            ApiService.uri(path, query.isEmpty ? null : query),
            headers: await ApiService.authHeaders(),
          )
          .timeout(ApiService.requestTimeout);

      final body = await ApiService.parseAuthenticatedResponse(
        response,
        clearSession: ApiService.clearUserSession,
        loginRoute: '/login',
      );
      final data = (body['data'] as List<dynamic>? ?? <dynamic>[])
          .cast<Map<String, dynamic>>();
      
      final isFallback = body['isFallback'] == true;

      return WorkerListResponse(
        workers: data.map(WorkerModel.fromJson).toList(),
        isFallback: isFallback,
      );
    } on TimeoutException {
      throw Exception('Network timeout, please try again');
    } on SocketException {
      throw Exception('Network error, please check your connection');
    }
  }

  Future<WorkerModel> getWorkerById(String id) async {
    return getWorkerByIdWithLocation(id);
  }

  Future<WorkerModel> getWorkerByIdWithLocation(
    String id, {
    double? userLatitude,
    double? userLongitude,
  }) async {
    try {
      final query = <String, String>{};
      if (userLatitude != null) {
        query['userLatitude'] = _numToString(userLatitude);
      }
      if (userLongitude != null) {
        query['userLongitude'] = _numToString(userLongitude);
      }

      final response = await http
          .get(
            ApiService.uri(
              '/workers/detail/$id',
              query.isEmpty ? null : query,
            ),
            headers: await ApiService.authHeaders(),
          )
          .timeout(ApiService.requestTimeout);

      final body = await ApiService.parseAuthenticatedResponse(
        response,
        clearSession: ApiService.clearUserSession,
        loginRoute: '/login',
      );
      final data = body['data'] as Map<String, dynamic>;
      return WorkerModel.fromJson(data);
    } on TimeoutException {
      throw Exception('Network timeout, please try again');
    } on SocketException {
      throw Exception('Network error, please check your connection');
    }
  }

  Future<Map<String, dynamic>> getWorkerSlots({
    required String workerId,
    required String date,
  }) async {
    try {
      final response = await http
          .get(
            ApiService.uri('/workers/$workerId/slots', {'date': date}),
            headers: await ApiService.authHeaders(),
          )
          .timeout(ApiService.requestTimeout);

      final body = await ApiService.parseAuthenticatedResponse(
        response,
        clearSession: ApiService.clearUserSession,
        loginRoute: '/login',
      );

      if (body['data'] is Map<String, dynamic>) {
        return (body['data'] as Map<String, dynamic>?) ?? <String, dynamic>{};
      }

      return {
        'availableSlots': body['availableSlots'] ?? <dynamic>[],
        'bookedSlots': body['bookedSlots'] ?? <dynamic>[],
        'allSlots': body['allSlots'] ?? body['availableSlots'] ?? <dynamic>[],
      };
    } on TimeoutException {
      throw Exception('Network timeout, please try again');
    } on SocketException {
      throw Exception('Network error, please check your connection');
    }
  }
}
