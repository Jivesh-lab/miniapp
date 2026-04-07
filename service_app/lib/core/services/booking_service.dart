import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/booking_model.dart';
import 'api_service.dart';

class BookingService {
  Future<BookingModel> createBooking(Map<String, dynamic> data) async {
    final response = await http.post(
      ApiService.uri('/bookings'),
      headers: ApiService.headers,
      body: jsonEncode(data),
    );

    final body = ApiService.parseResponse(response);
    return BookingModel.fromJson(body['data'] as Map<String, dynamic>);
  }

  Future<List<BookingModel>> getBookings(String userId) async {
    final response = await http.get(
      ApiService.uri('/bookings/$userId'),
      headers: ApiService.headers,
    );

    final body = ApiService.parseResponse(response);
    final data = (body['data'] as List<dynamic>? ?? <dynamic>[])
        .cast<Map<String, dynamic>>();

    return data.map(BookingModel.fromJson).toList();
  }
}
