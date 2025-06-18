enum BookingStatus {
  pending,
  confirmation,
  inprogress,
  completed,
  cancelled,
  disputed,
  resolved,
  closed
}

class BookingLocation {
  final String address;
  final List<double> coordinates; // [longitude, latitude]

  BookingLocation({
    required this.address,
    required this.coordinates,
  });

  factory BookingLocation.fromJson(Map<String, dynamic> json) {
    return BookingLocation(
      address: json['address'] as String,
      coordinates: List<double>.from(json['coordinates'] as List),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'address': address,
      'coordinates': coordinates,
    };
  }
}

class BookingUser {
  final String id;
  final String name;
  final String email;

  BookingUser({
    required this.id,
    required this.name,
    required this.email,
  });

  factory BookingUser.fromJson(Map<String, dynamic> json) {
    return BookingUser(
      id: json['_id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'email': email,
    };
  }
}

class Booking {
  final String id;
  final String service;
  final String date;
  final String time;
  final BookingLocation location;
  final String notes;
  final BookingUser user;
  final BookingUser? worker;
  final BookingStatus status;
  final double? amount;
  final String? review;
  final Map<String, dynamic>? disputeDetails;
  final int? serviceTime; // in minutes
  final DateTime? bookingStartingTime;
  final DateTime? bookingEndTime;
  final DateTime createdAt;
  final DateTime updatedAt;

  Booking({
    required this.id,
    required this.service,
    required this.date,
    required this.time,
    required this.location,
    required this.notes,
    required this.user,
    this.worker,
    required this.status,
    this.amount,
    this.review,
    this.disputeDetails,
    this.serviceTime,
    this.bookingStartingTime,
    this.bookingEndTime,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['_id'] as String,
      service: json['service'] as String,
      date: json['date'] as String,
      time: json['time'] as String,
      location: BookingLocation.fromJson(json['location'] as Map<String, dynamic>),
      notes: json['notes'] as String,
      user: BookingUser.fromJson(json['user'] as Map<String, dynamic>),
      worker: json['worker'] != null 
          ? BookingUser.fromJson(json['worker'] as Map<String, dynamic>)
          : null,
      status: BookingStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
        orElse: () => BookingStatus.pending,
      ),
      amount: json['amount']?.toDouble(),
      review: json['review'] as String?,
      disputeDetails: json['disputeDetails'] as Map<String, dynamic>?,
      serviceTime: json['serviceTime'] as int?,
      bookingStartingTime: json['bookingStartingTime'] != null 
          ? DateTime.parse(json['bookingStartingTime'] as String)
          : null,
      bookingEndTime: json['bookingEndTime'] != null 
          ? DateTime.parse(json['bookingEndTime'] as String)
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'service': service,
      'date': date,
      'time': time,
      'location': location.toJson(),
      'notes': notes,
      'user': user.toJson(),
      'worker': worker?.toJson(),
      'status': status.toString().split('.').last,
      'amount': amount,
      'review': review,
      'disputeDetails': disputeDetails,
      'serviceTime': serviceTime,
      'bookingStartingTime': bookingStartingTime?.toIso8601String(),
      'bookingEndTime': bookingEndTime?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
} 