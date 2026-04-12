import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/booking_model.dart';
import 'api_service.dart';

class BookingService {
  Future<BookingModel> createBooking(Map<String, dynamic> data) async {
    try {
      final response = await ApiService.postJson('/bookings', data, useAuthHeaders: true);
      final body = await ApiService.parseAuthenticatedResponse(
        response,
        clearSession: ApiService.clearUserSession,
        loginRoute: '/login',
      );
      return BookingModel.fromJson(body['data'] as Map<String, dynamic>);
    } catch (error) {
      rethrow;
    }
  }

  Future<List<BookingModel>> getBookings(String userId) async {
    try {
      final response = await ApiService.getJson('/bookings/user', useAuthHeaders: true);
      final body = await ApiService.parseAuthenticatedResponse(
        response,
        clearSession: ApiService.clearUserSession,
        loginRoute: '/login',
      );
      final data = (body['data'] as List<dynamic>? ?? <dynamic>[])
          .cast<Map<String, dynamic>>();

      return data.map(BookingModel.fromJson).toList();
    } catch (error) {
      rethrow;
    }
  }

  Future<BookingModel> updateBookingStatus({
    required String id,
    required String status,
  }) async {
    try {
      final response = await ApiService.patchJson(
        '/bookings/$id',
        {'status': status},
        useAuthHeaders: true,
      );

      final body = await ApiService.parseAuthenticatedResponse(
        response,
        clearSession: ApiService.clearUserSession,
        loginRoute: '/login',
      );
      return BookingModel.fromJson(body['data'] as Map<String, dynamic>);
    } catch (error) {
      rethrow;
    }
  }

  Future<void> cancelBooking(String id) async {
    try {
      final response = await ApiService.patchJson(
        '/bookings/cancel/$id',
        <String, dynamic>{},
        useAuthHeaders: true,
      );

      await ApiService.parseAuthenticatedResponse(
        response,
        clearSession: ApiService.clearUserSession,
        loginRoute: '/login',
      );
    } catch (error) {
      rethrow;
    }
  }

  Future<BookingModel> rateBooking({
    required String bookingId,
    required int rating,
    String? comment,
  }) async {
    try {
      final payload = <String, dynamic>{
        'rating': rating,
      };

      final normalizedComment = (comment ?? '').trim();
      if (normalizedComment.isNotEmpty) {
        payload['comment'] = normalizedComment;
      }

      final response = await ApiService.postJson(
        '/bookings/rate/$bookingId',
        payload,
        useAuthHeaders: true,
      );

      final body = await ApiService.parseAuthenticatedResponse(
        response,
        clearSession: ApiService.clearUserSession,
        loginRoute: '/login',
      );
      final data = body['data'] as Map<String, dynamic>;
      final bookingJson = (data['booking'] ?? data) as Map<String, dynamic>;
      return BookingModel.fromJson(bookingJson);
    } catch (error) {
      rethrow;
    }
  }
}
