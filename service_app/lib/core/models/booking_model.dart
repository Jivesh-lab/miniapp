enum BookingStatus { pending, completed, cancelled }

class BookingModel {
  final String id;
  final String workerId;
  final String workerName;
  final String serviceType;
  final DateTime date;
  final String timeSlot;
  final String address;
  final BookingStatus status;
  final DateTime createdAt;
  final DateTime? completedAt;
  final double? rating;
  final String? review;

  BookingModel({
    required this.id,
    required this.workerId,
    required this.workerName,
    required this.serviceType,
    required this.date,
    required this.timeSlot,
    required this.address,
    required this.status,
    required this.createdAt,
    this.completedAt,
    this.rating,
    this.review,
  });

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'workerId': workerId,
      'workerName': workerName,
      'serviceType': serviceType,
      'date': date.toIso8601String().split('T').first,
      'time': timeSlot,
      'timeSlot': timeSlot,
      'address': address,
      'status': statusString.toLowerCase(),
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'rating': rating,
      'review': review,
    };
  }

  // Convert from JSON
  factory BookingModel.fromJson(Map<String, dynamic> json) {
    final workerJson = json['workerId'];
    final workerData = workerJson is Map<String, dynamic> ? workerJson : <String, dynamic>{};
    final rawDate = (json['date'] ?? DateTime.now().toIso8601String()).toString();

    return BookingModel(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      workerId: workerData['_id']?.toString() ?? (json['workerId'] ?? '').toString(),
      workerName: (json['workerName'] ?? workerData['name'] ?? 'Worker').toString(),
      serviceType: (json['serviceType'] ?? 'Service').toString(),
      date: DateTime.tryParse(rawDate) ?? DateTime.now(),
      timeSlot: (json['timeSlot'] ?? json['time'] ?? '').toString(),
      address: (json['address'] ?? '').toString(),
      status: _parseStatus(json['status'] as String),
      createdAt: DateTime.tryParse((json['createdAt'] ?? rawDate).toString()) ?? DateTime.now(),
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
      rating: (json['rating'] as num?)?.toDouble(),
      review: json['review'] as String?,
    );
  }

  // Copy with method
  BookingModel copyWith({
    String? id,
    String? workerId,
    String? workerName,
    String? serviceType,
    DateTime? date,
    String? timeSlot,
    String? address,
    BookingStatus? status,
    DateTime? createdAt,
    DateTime? completedAt,
    double? rating,
    String? review,
  }) {
    return BookingModel(
      id: id ?? this.id,
      workerId: workerId ?? this.workerId,
      workerName: workerName ?? this.workerName,
      serviceType: serviceType ?? this.serviceType,
      date: date ?? this.date,
      timeSlot: timeSlot ?? this.timeSlot,
      address: address ?? this.address,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      rating: rating ?? this.rating,
      review: review ?? this.review,
    );
  }

  // Helper methods
  bool get isPending => status == BookingStatus.pending;
  bool get isCompleted => status == BookingStatus.completed;
  bool get isCancelled => status == BookingStatus.cancelled;

  bool get isUpcoming => date.isAfter(DateTime.now());
  bool get isPast => date.isBefore(DateTime.now());

  String get statusString {
    switch (status) {
      case BookingStatus.pending:
        return 'Pending';
      case BookingStatus.completed:
        return 'Completed';
      case BookingStatus.cancelled:
        return 'Cancelled';
    }
  }

  static BookingStatus _parseStatus(String status) {
    switch (status) {
      case 'ongoing':
      case 'BookingStatus.pending':
      case 'pending':
        return BookingStatus.pending;
      case 'BookingStatus.completed':
      case 'completed':
        return BookingStatus.completed;
      case 'BookingStatus.cancelled':
      case 'cancelled':
        return BookingStatus.cancelled;
      default:
        return BookingStatus.pending;
    }
  }

  @override
  String toString() =>
      'BookingModel(id: $id, workerName: $workerName, status: $status)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BookingModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}