import 'dart:convert';

import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'http://localhost:5000/api';

  static Map<String, String> get headers => {
        'Content-Type': 'application/json',
      };

  static Uri uri(String path, [Map<String, String>? query]) {
    return Uri.parse('$baseUrl$path').replace(queryParameters: query);
  }

  static Map<String, dynamic> parseResponse(http.Response response) {
    final Map<String, dynamic> body = response.body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }

    throw Exception(body['message']?.toString() ?? 'Request failed');
  }
}
