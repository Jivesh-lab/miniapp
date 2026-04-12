import 'package:flutter/material.dart';

enum WorkerBookingStatus {
  pending,
  confirmed,
  inProgress,
  completed,
  cancelled,
}

class WorkerBooking {
  final String id;
  final String customerName;
  final String customerContact;
  final String address;
  final String date;
  final String time;
  final WorkerBookingStatus status;

  const WorkerBooking({
    required this.id,
    required this.customerName,
    required this.customerContact,
    required this.address,
    required this.date,
    required this.time,
    required this.status,
  });

  factory WorkerBooking.fromJson(Map<String, dynamic> json) {
    final user = json['userId'];
    final userMap = user is Map<String, dynamic> ? user : <String, dynamic>{};

    return WorkerBooking(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      customerName: (json['customerName'] ??
              userMap['name'] ??
              json['userName'] ??
              userMap['email'] ??
              'Customer')
          .toString(),
      customerContact: (json['customerContact'] ??
              userMap['phone'] ??
              userMap['email'] ??
              'Not available')
          .toString(),
      address: (json['address'] ?? 'Not provided').toString(),
      date: (json['date'] ?? '').toString(),
      time: (json['time'] ?? '').toString(),
      status: _parseStatus((json['status'] ?? '').toString()),
    );
  }

  static WorkerBookingStatus _parseStatus(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return WorkerBookingStatus.pending;
      case 'confirmed':
        return WorkerBookingStatus.confirmed;
      case 'in-progress':
      case 'in_progress':
      case 'inprogress':
        return WorkerBookingStatus.inProgress;
      case 'completed':
        return WorkerBookingStatus.completed;
      case 'cancelled':
      case 'canceled':
        return WorkerBookingStatus.cancelled;
      default:
        return WorkerBookingStatus.pending;
    }
  }

  String get statusValue {
    switch (status) {
      case WorkerBookingStatus.pending:
        return 'pending';
      case WorkerBookingStatus.confirmed:
        return 'confirmed';
      case WorkerBookingStatus.inProgress:
        return 'in-progress';
      case WorkerBookingStatus.completed:
        return 'completed';
      case WorkerBookingStatus.cancelled:
        return 'cancelled';
    }
  }

  String get statusLabel {
    switch (status) {
      case WorkerBookingStatus.pending:
        return 'Pending';
      case WorkerBookingStatus.confirmed:
        return 'Confirmed';
      case WorkerBookingStatus.inProgress:
        return 'In Progress';
      case WorkerBookingStatus.completed:
        return 'Completed';
      case WorkerBookingStatus.cancelled:
        return 'Cancelled';
    }
  }

  Color get statusColor {
    switch (status) {
      case WorkerBookingStatus.pending:
        return Colors.orange;
      case WorkerBookingStatus.confirmed:
        return Colors.blue;
      case WorkerBookingStatus.inProgress:
        return Colors.purple;
      case WorkerBookingStatus.completed:
        return Colors.green;
      case WorkerBookingStatus.cancelled:
        return Colors.red;
    }
  }

  WorkerBooking copyWith({
    WorkerBookingStatus? status,
  }) {
    return WorkerBooking(
      id: id,
      customerName: customerName,
      customerContact: customerContact,
      address: address,
      date: date,
      time: time,
      status: status ?? this.status,
    );
  }
}
