import 'package:cloud_firestore/cloud_firestore.dart';
import 'service_model.dart';
import 'dart:math' as math;

class SalonModel {
  final String id;
  final String name;
  final String description;
  final String category;
  final String ownerId;
  final String address;
  final double latitude;
  final double longitude;
  final String phoneNumber;
  final String? email;
  final List<ServiceModel> services;
  final Map<String, List<String>> workingHours; // gün: [açılış saati, kapanış saati]
  final List<String> images;
  final String? imageUrl;
  final double rating;
  final int reviewCount;
  final bool isActive;
  final DateTime createdAt;

  SalonModel({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.ownerId,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.phoneNumber,
    this.email,
    required this.services,
    required this.workingHours,
    this.images = const [],
    this.imageUrl,
    this.rating = 0.0,
    this.reviewCount = 0,
    this.isActive = true,
    required this.createdAt,
  });

  // Computed properties
  bool get isOpenNow {
    final now = DateTime.now();
    final dayName = _getDayName(now.weekday);
    final todayHours = workingHours[dayName];
    
    if (todayHours == null || todayHours.length != 2 || 
        todayHours[0] == 'Kapalı' || todayHours[1] == 'Kapalı') {
      return false;
    }
    
    try {
      final openTime = _parseTime(todayHours[0]);
      final closeTime = _parseTime(todayHours[1]);
      final currentTime = now.hour * 60 + now.minute;
      
      return currentTime >= openTime && currentTime <= closeTime;
    } catch (e) {
      return false;
    }
  }

  double get minPrice {
    if (services.isEmpty) return 0;
    return services.map((s) => s.price).reduce(math.min);
  }

  double get maxPrice {
    if (services.isEmpty) return 0;
    return services.map((s) => s.price).reduce(math.max);
  }

  // Helper methods
  int _parseTime(String timeStr) {
    final parts = timeStr.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }

  double calculateDistance(double userLat, double userLng) {
    const double earthRadius = 6371; // km
    double lat1Rad = userLat * (math.pi / 180);
    double lat2Rad = latitude * (math.pi / 180);
    double deltaLat = (latitude - userLat) * (math.pi / 180);
    double deltaLng = (longitude - userLng) * (math.pi / 180);

    double a = math.sin(deltaLat / 2) * math.sin(deltaLat / 2) +
        math.cos(lat1Rad) * math.cos(lat2Rad) * 
        math.sin(deltaLng / 2) * math.sin(deltaLng / 2);
    double c = 2 * math.asin(math.sqrt(a));

    return earthRadius * c;
  }

  factory SalonModel.fromJson(Map<String, dynamic> json) {
    return SalonModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      category: json['category'] ?? '',
      ownerId: json['ownerId'] ?? '',
      address: json['address'] ?? '',
      latitude: json['latitude']?.toDouble() ?? 0.0,
      longitude: json['longitude']?.toDouble() ?? 0.0,
      phoneNumber: json['phoneNumber'] ?? '',
      email: json['email'],
      services: <ServiceModel>[],
      workingHours: Map<String, List<String>>.from(
        (json['workingHours'] as Map<String, dynamic>?)?.map(
          (key, value) => MapEntry(key, List<String>.from(value))
        ) ?? {}
      ),
      images: List<String>.from(json['images'] ?? []),
      imageUrl: json['imageUrl'],
      rating: json['rating']?.toDouble() ?? 0.0,
      reviewCount: json['reviewCount'] ?? 0,
      isActive: json['isActive'] ?? true,
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  // Firestore'dan veri okuma
  factory SalonModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SalonModel(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      category: data['category'] ?? '',
      ownerId: data['ownerId'] ?? '',
      address: data['address'] ?? '',
      latitude: data['latitude']?.toDouble() ?? 0.0,
      longitude: data['longitude']?.toDouble() ?? 0.0,
      phoneNumber: data['phoneNumber'] ?? '',
      email: data['email'],
      services: <ServiceModel>[],
      workingHours: Map<String, List<String>>.from(
        (data['workingHours'] as Map<String, dynamic>?)?.map(
          (key, value) => MapEntry(key, List<String>.from(value))
        ) ?? {}
      ),
      images: List<String>.from(data['images'] ?? []),
      imageUrl: data['imageUrl'],
      rating: data['rating']?.toDouble() ?? 0.0,
      reviewCount: data['reviewCount'] ?? 0,
      isActive: data['isActive'] ?? true,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category': category,
      'ownerId': ownerId,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'phoneNumber': phoneNumber,
      'email': email,
      'services': services.map((s) => s.toFirestore()).toList(),
      'workingHours': workingHours,
      'images': images,
      'imageUrl': imageUrl,
      'rating': rating,
      'reviewCount': reviewCount,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // Firestore'a veri yazma
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'category': category,
      'ownerId': ownerId,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'phoneNumber': phoneNumber,
      'email': email,
      'services': services.map((s) => s.toFirestore()).toList(),
      'workingHours': workingHours,
      'images': images,
      'imageUrl': imageUrl,
      'rating': rating,
      'reviewCount': reviewCount,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  String _getDayName(int weekday) {
    const days = [
      'Pazartesi', 'Salı', 'Çarşamba', 'Perşembe', 
      'Cuma', 'Cumartesi', 'Pazar'
    ];
    return days[weekday - 1];
  }

  SalonModel copyWith({
    String? id,
    String? name,
    String? description,
    String? category,
    String? ownerId,
    String? address,
    double? latitude,
    double? longitude,
    String? phoneNumber,
    String? email,
    List<ServiceModel>? services,
    Map<String, List<String>>? workingHours,
    List<String>? images,
    String? imageUrl,
    double? rating,
    int? reviewCount,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return SalonModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      ownerId: ownerId ?? this.ownerId,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      services: services ?? this.services,
      workingHours: workingHours ?? this.workingHours,
      images: images ?? this.images,
      imageUrl: imageUrl ?? this.imageUrl,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }
} 