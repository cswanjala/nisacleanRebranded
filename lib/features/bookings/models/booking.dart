enum BookingStatus {
  pending,
  confirmed,
  inProgress,
  completed,
  cancelled
}

class Booking {
  final String id;
  final String userId;
  final String serviceName;
  final DateTime scheduledDate;
  final String scheduledTime;
  final double amount;
  final BookingStatus status;
  final String? location;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  Booking({
    required this.id,
    required this.userId,
    required this.serviceName,
    required this.scheduledDate,
    required this.scheduledTime,
    required this.amount,
    required this.status,
    this.location,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      serviceName: json['service_name'] as String,
      scheduledDate: DateTime.parse(json['scheduled_date'] as String),
      scheduledTime: json['scheduled_time'] as String,
      amount: (json['amount'] as num).toDouble(),
      status: BookingStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
      ),
      location: json['location'] as String?,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'service_name': serviceName,
      'scheduled_date': scheduledDate.toIso8601String(),
      'scheduled_time': scheduledTime,
      'amount': amount,
      'status': status.toString().split('.').last,
      'location': location,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
} 