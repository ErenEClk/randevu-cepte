import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'salon_model.dart';
import 'service_model.dart';
import 'user_model.dart';

enum AppointmentStatus {
  pending,    // Beklemede (esnaf onayı bekleniyor)
  confirmed,  // Onaylandı
  completed,  // Tamamlandı
  cancelled,  // İptal edildi
  rejected,   // Reddedildi
  noShow,     // Gelmedi
}

class AppointmentModel {
  final String id;
  final String customerId;
  final String customerName;
  final String customerPhone;
  final String customerEmail;
  final String salonId;
  final String salonName;
  final List<ServiceModel> services;
  final DateTime appointmentDate;
  final TimeOfDay appointmentTime;
  final AppointmentStatus status;
  final String? notes;
  final String? cancellationReason;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? confirmedAt;
  final DateTime? cancelledAt;
  final DateTime? completedAt;

  AppointmentModel({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
    required this.customerEmail,
    required this.salonId,
    required this.salonName,
    required this.services,
    required this.appointmentDate,
    required this.appointmentTime,
    required this.status,
    this.notes,
    this.cancellationReason,
    required this.createdAt,
    this.updatedAt,
    this.confirmedAt,
    this.cancelledAt,
    this.completedAt,
  });

  // Firestore'dan veri okuma
  factory AppointmentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    // TimeOfDay'i Map'ten parse et
    final timeData = data['appointmentTime'] as Map<String, dynamic>;
    final appointmentTime = TimeOfDay(
      hour: timeData['hour'] ?? 0,
      minute: timeData['minute'] ?? 0,
    );

    return AppointmentModel(
      id: doc.id,
      customerId: data['customerId'] ?? '',
      customerName: data['customerName'] ?? '',
      customerPhone: data['customerPhone'] ?? '',
      customerEmail: data['customerEmail'] ?? '',
      salonId: data['salonId'] ?? '',
      salonName: data['salonName'] ?? '',
              services: <ServiceModel>[],
      appointmentDate: (data['appointmentDate'] as Timestamp).toDate(),
      appointmentTime: appointmentTime,
      status: AppointmentStatus.values.firstWhere(
        (status) => status.toString().split('.').last == data['status'],
        orElse: () => AppointmentStatus.pending,
      ),
      notes: data['notes'],
      cancellationReason: data['cancellationReason'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
      confirmedAt: data['confirmedAt'] != null
          ? (data['confirmedAt'] as Timestamp).toDate()
          : null,
      cancelledAt: data['cancelledAt'] != null
          ? (data['cancelledAt'] as Timestamp).toDate()
          : null,
      completedAt: data['completedAt'] != null
          ? (data['completedAt'] as Timestamp).toDate()
          : null,
    );
  }

  // Firestore'a veri yazma
  Map<String, dynamic> toFirestore() {
    return {
      'customerId': customerId,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'customerEmail': customerEmail,
      'salonId': salonId,
      'salonName': salonName,
      'services': services.map((s) => s.toFirestore()).toList(),
      'appointmentDate': Timestamp.fromDate(appointmentDate),
      'appointmentTime': {
        'hour': appointmentTime.hour,
        'minute': appointmentTime.minute,
      },
      'status': status.toString().split('.').last,
      'notes': notes,
      'cancellationReason': cancellationReason,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'confirmedAt': confirmedAt != null ? Timestamp.fromDate(confirmedAt!) : null,
      'cancelledAt': cancelledAt != null ? Timestamp.fromDate(cancelledAt!) : null,
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
    };
  }

  // Toplam fiyat hesaplama
  double get totalPrice {
    return services.fold(0.0, (sum, service) => sum + service.price);
  }

  // Toplam süre hesaplama
  Duration get totalDuration {
    return services.fold(
      Duration.zero, 
      (sum, service) => sum + Duration(minutes: service.durationMinutes),
    );
  }

  // Randevu bitiş zamanı
  DateTime get endDateTime {
    final startDateTime = DateTime(
      appointmentDate.year,
      appointmentDate.month,
      appointmentDate.day,
      appointmentTime.hour,
      appointmentTime.minute,
    );
    return startDateTime.add(totalDuration);
  }

  // Fiyat metni
  String get totalPriceText {
    return '${totalPrice.toStringAsFixed(0)} ₺';
  }

  // Süre metni
  String get totalDurationText {
    final hours = totalDuration.inHours;
    final minutes = totalDuration.inMinutes.remainder(60);
    
    if (hours > 0) {
      return '${hours}s ${minutes}dk';
    } else {
      return '${minutes}dk';
    }
  }

  // Durum metni
  String get statusText {
    switch (status) {
      case AppointmentStatus.pending:
        return 'Onay Bekliyor';
      case AppointmentStatus.confirmed:
        return 'Onaylandı';
      case AppointmentStatus.completed:
        return 'Tamamlandı';
      case AppointmentStatus.cancelled:
        return 'İptal Edildi';
      case AppointmentStatus.rejected:
        return 'Reddedildi';
      case AppointmentStatus.noShow:
        return 'Gelmedi';
    }
  }

  // Durum rengi
  Color get statusColor {
    switch (status) {
      case AppointmentStatus.pending:
        return const Color(0xFFFF9800); // Orange
      case AppointmentStatus.confirmed:
        return const Color(0xFF4CAF50); // Green
      case AppointmentStatus.completed:
        return const Color(0xFF2196F3); // Blue
      case AppointmentStatus.cancelled:
        return const Color(0xFF9E9E9E); // Grey
      case AppointmentStatus.rejected:
        return const Color(0xFFF44336); // Red
      case AppointmentStatus.noShow:
        return const Color(0xFF795548); // Brown
    }
  }

  // Durum ikonu
  IconData get statusIcon {
    switch (status) {
      case AppointmentStatus.pending:
        return Icons.schedule;
      case AppointmentStatus.confirmed:
        return Icons.check_circle;
      case AppointmentStatus.completed:
        return Icons.done_all;
      case AppointmentStatus.cancelled:
        return Icons.cancel;
      case AppointmentStatus.rejected:
        return Icons.block;
      case AppointmentStatus.noShow:
        return Icons.person_off;
    }
  }

  // Tarih ve saat metni
  String get dateTimeText {
    final months = [
      'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
      'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'
    ];
    
    final date = '${appointmentDate.day} ${months[appointmentDate.month - 1]} ${appointmentDate.year}';
    final time = '${appointmentTime.hour.toString().padLeft(2, '0')}:${appointmentTime.minute.toString().padLeft(2, '0')}';
    
    return '$date, $time';
  }

  // Kısa tarih formatı
  String get shortDateText {
    return '${appointmentDate.day.toString().padLeft(2, '0')}/${appointmentDate.month.toString().padLeft(2, '0')}/${appointmentDate.year}';
  }

  // Saat formatı
  String get timeText {
    return '${appointmentTime.hour.toString().padLeft(2, '0')}:${appointmentTime.minute.toString().padLeft(2, '0')}';
  }

  // Hizmet isimleri
  String get serviceNames {
    return services.map((service) => service.name).join(', ');
  }

  // Geçmiş randevu mu?
  bool get isPast {
    final now = DateTime.now();
    final appointmentDateTime = DateTime(
      appointmentDate.year,
      appointmentDate.month,
      appointmentDate.day,
      appointmentTime.hour,
      appointmentTime.minute,
    );
    return appointmentDateTime.isBefore(now);
  }

  // Bugün mü?
  bool get isToday {
    final today = DateTime.now();
    return appointmentDate.year == today.year &&
           appointmentDate.month == today.month &&
           appointmentDate.day == today.day;
  }

  // Yaklaşan randevu mu? (24 saat içinde)
  bool get isUpcoming {
    final now = DateTime.now();
    final appointmentDateTime = DateTime(
      appointmentDate.year,
      appointmentDate.month,
      appointmentDate.day,
      appointmentTime.hour,
      appointmentTime.minute,
    );
    final diff = appointmentDateTime.difference(now);
    return diff.inHours >= 0 && diff.inHours <= 24;
  }

  // İptal edilebilir mi?
  bool get canCancel {
    return status == AppointmentStatus.pending || 
           status == AppointmentStatus.confirmed;
  }

  // Onaylanabilir mi?
  bool get canConfirm {
    return status == AppointmentStatus.pending;
  }

  // Reddedilebilir mi?
  bool get canReject {
    return status == AppointmentStatus.pending;
  }

  // Tamamlanabilir mi?
  bool get canComplete {
    return status == AppointmentStatus.confirmed && !isPast;
  }

  // No-show olarak işaretlenebilir mi?
  bool get canMarkNoShow {
    return status == AppointmentStatus.confirmed && isPast;
  }

  // Kopya oluşturma
  AppointmentModel copyWith({
    String? id,
    String? customerId,
    String? customerName,
    String? customerPhone,
    String? customerEmail,
    String? salonId,
    String? salonName,
    List<ServiceModel>? services,
    DateTime? appointmentDate,
    TimeOfDay? appointmentTime,
    AppointmentStatus? status,
    String? notes,
    String? cancellationReason,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? confirmedAt,
    DateTime? cancelledAt,
    DateTime? completedAt,
  }) {
    return AppointmentModel(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      customerEmail: customerEmail ?? this.customerEmail,
      salonId: salonId ?? this.salonId,
      salonName: salonName ?? this.salonName,
      services: services ?? this.services,
      appointmentDate: appointmentDate ?? this.appointmentDate,
      appointmentTime: appointmentTime ?? this.appointmentTime,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      cancellationReason: cancellationReason ?? this.cancellationReason,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      confirmedAt: confirmedAt ?? this.confirmedAt,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  @override
  String toString() {
    return 'AppointmentModel(id: $id, customer: $customerName, salon: $salonName, date: $shortDateText $timeText)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AppointmentModel &&
        other.id == id &&
        other.customerId == customerId &&
        other.salonId == salonId &&
        other.appointmentDate == appointmentDate &&
        other.appointmentTime == appointmentTime;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        customerId.hashCode ^
        salonId.hashCode ^
        appointmentDate.hashCode ^
        appointmentTime.hashCode;
  }
} 