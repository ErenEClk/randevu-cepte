import 'package:cloud_firestore/cloud_firestore.dart';

enum ServiceCategory { 
  haircut, 
  coloring, 
  treatment, 
  makeup, 
  shaving, 
  nail, 
  skincare, 
  massage 
}

class ServiceModel {
  final String id;
  final String salonId;
  final String name;
  final String description;
  final double price;
  final int durationMinutes;
  final ServiceCategory category;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ServiceModel({
    required this.id,
    required this.salonId,
    required this.name,
    required this.description,
    required this.price,
    required this.durationMinutes,
    required this.category,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  // Firestore'dan model oluştur
  factory ServiceModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return ServiceModel(
      id: doc.id,
      salonId: data['salonId'] ?? '',
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      price: (data['price'] ?? 0.0).toDouble(),
      durationMinutes: data['durationMinutes'] ?? 30,
      category: ServiceCategory.values.firstWhere(
        (cat) => cat.toString().split('.').last == data['category'],
        orElse: () => ServiceCategory.haircut,
      ),
      isActive: data['isActive'] ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  // Firestore'a kaydet
  Map<String, dynamic> toFirestore() {
    return {
      'salonId': salonId,
      'name': name,
      'description': description,
      'price': price,
      'durationMinutes': durationMinutes,
      'category': category.toString().split('.').last,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  // Model kopyalama
  ServiceModel copyWith({
    String? id,
    String? salonId,
    String? name,
    String? description,
    double? price,
    int? durationMinutes,
    ServiceCategory? category,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ServiceModel(
      id: id ?? this.id,
      salonId: salonId ?? this.salonId,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      category: category ?? this.category,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Fiyat formatı
  String get formattedPrice => '${price.toStringAsFixed(0)} ₺';

  // Süre formatı
  String get formattedDuration {
    if (durationMinutes < 60) {
      return '$durationMinutes dk';
    } else {
      final hours = durationMinutes ~/ 60;
      final minutes = durationMinutes % 60;
      if (minutes == 0) {
        return '$hours sa';
      } else {
        return '$hours sa $minutes dk';
      }
    }
  }

  @override
  String toString() {
    return 'ServiceModel(id: $id, name: $name, price: $price, duration: $durationMinutes)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ServiceModel &&
        other.id == id &&
        other.salonId == salonId &&
        other.name == name &&
        other.price == price &&
        other.durationMinutes == durationMinutes;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        salonId.hashCode ^
        name.hashCode ^
        price.hashCode ^
        durationMinutes.hashCode;
  }

  // Hizmet süresi insan dostu format
  String get durationText {
    int minutes = durationMinutes;
    if (minutes < 60) {
      return '$minutes dk';
    } else {
      int hours = minutes ~/ 60;
      int remainingMinutes = minutes % 60;
      if (remainingMinutes == 0) {
        return '$hours sa';
      } else {
        return '$hours sa $remainingMinutes dk';
      }
    }
  }

  // Fiyat formatı
  String get priceText {
    return '₺${price.toStringAsFixed(0)}';
  }

  // Kategori emoji'si
  String get emoji {
    switch (category) {
      case ServiceCategory.haircut:
        return '💇‍♀️';
      case ServiceCategory.coloring:
        return '🎨';
      case ServiceCategory.treatment:
        return '✨';
      case ServiceCategory.makeup:
        return '💄';
      case ServiceCategory.shaving:
        return '🪒';
      case ServiceCategory.nail:
        return '💅';
      case ServiceCategory.skincare:
        return '🧴';
      case ServiceCategory.massage:
        return '💆‍♀️';
    }
  }
} 