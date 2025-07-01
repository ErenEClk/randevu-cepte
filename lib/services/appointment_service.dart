import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/appointment_model.dart';
import '../models/service_model.dart';
import '../models/user_model.dart';
import 'auth_service.dart';

class AppointmentService {
  static final AppointmentService _instance = AppointmentService._internal();
  factory AppointmentService() => _instance;
  AppointmentService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();

  // Mock veriler için geçici liste
  final List<AppointmentModel> _mockAppointments = [];

  // Mock veri ekleme (geliştirme için)
  void addMockAppointments() {
    if (_mockAppointments.isNotEmpty) return;

    final mockServices = [
      ServiceModel(
        id: '1',
        salonId: 'salon1',
        name: 'Saç Kesimi',
        description: 'Profesyonel saç kesimi',
        price: 150.0,
        durationMinutes: 45,
        category: ServiceCategory.haircut,
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      ServiceModel(
        id: '2',
        salonId: 'salon1',
        name: 'Fön',
        description: 'Saç fönü',
        price: 80.0,
        durationMinutes: 30,
        category: ServiceCategory.treatment,
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];

    // Test müşteri randevuları ekle
    final testCustomerId = 'mock_customer'; // AuthService'teki mock user ID
    final now = DateTime.now();
    
    // Geçmiş randevu (tamamlanmış)
    _mockAppointments.add(AppointmentModel(
      id: 'apt_1',
      customerId: testCustomerId,
      customerName: 'Test Müşteri',
      customerPhone: '+90555123456',
      customerEmail: 'musteri@test.com',
      salonId: '1',
      salonName: 'Güzellik Merkezi Ayşe',
      services: [mockServices[0]], // Saç kesimi
      appointmentDate: now.subtract(Duration(days: 7)),
      appointmentTime: TimeOfDay(hour: 14, minute: 0),
      status: AppointmentStatus.completed,
      createdAt: now.subtract(Duration(days: 8)),
    ));
    
    // Yaklaşan randevu (onaylanmış)
    _mockAppointments.add(AppointmentModel(
      id: 'apt_2',
      customerId: testCustomerId,
      customerName: 'Test Müşteri',
      customerPhone: '+90555123456',
      customerEmail: 'musteri@test.com',
      salonId: '2',
      salonName: 'Modern Berber Salih',
      services: [mockServices[1]], // Fön
      appointmentDate: now.add(Duration(days: 3)),
      appointmentTime: TimeOfDay(hour: 10, minute: 30),
      status: AppointmentStatus.confirmed,
      createdAt: now.subtract(Duration(days: 2)),
    ));
    
    // Bekleyen randevu
    _mockAppointments.add(AppointmentModel(
      id: 'apt_3',
      customerId: testCustomerId,
      customerName: 'Test Müşteri',
      customerPhone: '+90555123456',
      customerEmail: 'musteri@test.com',
      salonId: '3',
      salonName: 'Lüks Güzellik Salonu Elif',
      services: [mockServices[0], mockServices[1]], // Kombo
      appointmentDate: now.add(Duration(days: 5)),
      appointmentTime: TimeOfDay(hour: 16, minute: 0),
      status: AppointmentStatus.pending,
      createdAt: now.subtract(Duration(hours: 12)),
    ));
    
    print('🎯 Mock appointments eklendi: ${_mockAppointments.length} randevu');
  }

  // Randevu oluşturma
  Future<String> createAppointment(AppointmentModel appointment) async {
    try {
      // Yeni ID oluştur
      final docRef = _firestore.collection('appointments').doc();
      final appointmentWithId = appointment.copyWith(id: docRef.id);
      
      // Çakışma kontrolü
      final conflicts = await _checkAppointmentConflicts(
        appointmentWithId.salonId,
        appointmentWithId.appointmentDate,
        appointmentWithId.appointmentTime,
        appointmentWithId.totalDuration,
      );

      if (conflicts.isNotEmpty) {
        throw Exception('Bu saatte başka bir randevu mevcut');
      }

      // Firebase'e kaydet
      await docRef.set(appointmentWithId.toFirestore());
      
      // Mock listeye de ekle (geliştirme için)
      _mockAppointments.add(appointmentWithId);
      
      print('✅ Randevu oluşturuldu: ${appointmentWithId.id}');
      return appointmentWithId.id;
    } catch (e) {
      print('❌ Randevu oluşturma hatası: $e');
      throw Exception('Randevu oluşturulamadı: $e');
    }
  }

  // Randevu çakışma kontrolü
  Future<List<AppointmentModel>> _checkAppointmentConflicts(
    String salonId,
    DateTime date,
    TimeOfDay time,
    Duration duration,
  ) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

      final querySnapshot = await _firestore
          .collection('appointments')
          .where('salonId', isEqualTo: salonId)
          .where('appointmentDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('appointmentDate', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
          .where('status', whereIn: ['pending', 'confirmed'])
          .get();

      final dayAppointments = querySnapshot.docs
          .map((doc) => AppointmentModel.fromFirestore(doc))
          .toList();

      final requestedStart = DateTime(
        date.year, date.month, date.day,
        time.hour, time.minute,
      );
      final requestedEnd = requestedStart.add(duration);

      return dayAppointments.where((appointment) {
        final existingStart = DateTime(
          appointment.appointmentDate.year,
          appointment.appointmentDate.month,
          appointment.appointmentDate.day,
          appointment.appointmentTime.hour,
          appointment.appointmentTime.minute,
        );
        final existingEnd = existingStart.add(appointment.totalDuration);

        // Çakışma kontrolü
        return (requestedStart.isBefore(existingEnd) && 
                requestedEnd.isAfter(existingStart));
      }).toList();
    } catch (e) {
      print('Çakışma kontrolü hatası: $e');
      return [];
    }
  }

  // Randevu onaylama
  Future<void> confirmAppointment(String appointmentId) async {
    try {
      // Firebase'e kaydet
      await _firestore
          .collection('appointments')
          .doc(appointmentId)
          .update({
            'status': 'confirmed',
            'confirmedAt': Timestamp.fromDate(DateTime.now()),
            'updatedAt': Timestamp.fromDate(DateTime.now()),
          });
      
      print('✅ Firebase - Randevu onaylandı: $appointmentId');
      
      // Mock listesini de güncelle
      final mockIndex = _mockAppointments.indexWhere((apt) => apt.id == appointmentId);
      if (mockIndex != -1) {
        _mockAppointments[mockIndex] = _mockAppointments[mockIndex].copyWith(
          status: AppointmentStatus.confirmed,
          updatedAt: DateTime.now(),
        );
        print('✅ Mock - Randevu onaylandı: $appointmentId');
      }
    } catch (e) {
      print('❌ Randevu onaylama hatası: $e');
      throw Exception('Randevu onaylanamadı: $e');
    }
  }

  // Randevu reddetme
  Future<void> rejectAppointment(String appointmentId, String reason) async {
    try {
      // Firebase'e kaydet
      await _firestore
          .collection('appointments')
          .doc(appointmentId)
          .update({
            'status': 'rejected',
            'cancellationReason': reason,
            'cancelledAt': Timestamp.fromDate(DateTime.now()),
            'updatedAt': Timestamp.fromDate(DateTime.now()),
          });
      
      print('✅ Firebase - Randevu reddedildi: $appointmentId');
      
      // Mock listesini de güncelle
      final mockIndex = _mockAppointments.indexWhere((apt) => apt.id == appointmentId);
      if (mockIndex != -1) {
        _mockAppointments[mockIndex] = _mockAppointments[mockIndex].copyWith(
          status: AppointmentStatus.rejected,
          updatedAt: DateTime.now(),
        );
        print('✅ Mock - Randevu reddedildi: $appointmentId');
      }
    } catch (e) {
      print('❌ Randevu reddetme hatası: $e');
      throw Exception('Randevu reddedilemedi: $e');
    }
  }

  // Randevu iptal etme
  Future<void> cancelAppointment(String appointmentId, String reason) async {
    try {
      // Firebase'e kaydet
      await _firestore
          .collection('appointments')
          .doc(appointmentId)
          .update({
            'status': 'cancelled',
            'cancellationReason': reason,
            'cancelledAt': Timestamp.fromDate(DateTime.now()),
            'updatedAt': Timestamp.fromDate(DateTime.now()),
          });
      
      print('✅ Firebase - Randevu iptal edildi: $appointmentId');
      
      // Mock listesini de güncelle
      final mockIndex = _mockAppointments.indexWhere((apt) => apt.id == appointmentId);
      if (mockIndex != -1) {
        _mockAppointments[mockIndex] = _mockAppointments[mockIndex].copyWith(
          status: AppointmentStatus.cancelled,
          updatedAt: DateTime.now(),
        );
        print('✅ Mock - Randevu iptal edildi: $appointmentId');
      }
    } catch (e) {
      print('❌ Randevu iptal etme hatası: $e');
      throw Exception('Randevu iptal edilemedi: $e');
    }
  }

  // Randevu tamamlama
  Future<void> completeAppointment(String appointmentId) async {
    try {
      // Firebase'e kaydet
      await _firestore
          .collection('appointments')
          .doc(appointmentId)
          .update({
            'status': 'completed',
            'completedAt': Timestamp.fromDate(DateTime.now()),
            'updatedAt': Timestamp.fromDate(DateTime.now()),
          });
      
      print('✅ Firebase - Randevu tamamlandı: $appointmentId');
      
      // Mock listesini de güncelle
      final mockIndex = _mockAppointments.indexWhere((apt) => apt.id == appointmentId);
      if (mockIndex != -1) {
        _mockAppointments[mockIndex] = _mockAppointments[mockIndex].copyWith(
          status: AppointmentStatus.completed,
          updatedAt: DateTime.now(),
        );
        print('✅ Mock - Randevu tamamlandı: $appointmentId');
      }
    } catch (e) {
      print('❌ Randevu tamamlama hatası: $e');
      throw Exception('Randevu tamamlanamadı: $e');
    }
  }

  // No-show olarak işaretleme
  Future<void> markAsNoShow(String appointmentId) async {
    try {
      // Firebase'e kaydet
      await _firestore
          .collection('appointments')
          .doc(appointmentId)
          .update({
            'status': 'noShow',
            'updatedAt': Timestamp.fromDate(DateTime.now()),
          });
      
      print('✅ Firebase - Randevu no-show işaretlendi: $appointmentId');
      
      // Mock listesini de güncelle
      final mockIndex = _mockAppointments.indexWhere((apt) => apt.id == appointmentId);
      if (mockIndex != -1) {
        _mockAppointments[mockIndex] = _mockAppointments[mockIndex].copyWith(
          status: AppointmentStatus.noShow,
          updatedAt: DateTime.now(),
        );
        print('✅ Mock - Randevu no-show işaretlendi: $appointmentId');
      }
    } catch (e) {
      print('❌ No-show işaretleme hatası: $e');
      throw Exception('Randevu no-show olarak işaretlenemedi: $e');
    }
  }

  // Müşteri randevularını getirme
  Future<List<AppointmentModel>> getCustomerAppointments(String customerId, {
    AppointmentStatus? status,
    int? limit,
  }) async {
    try {
      // Önce mock verilerden al (geliştirme aşamasında hızlı test için)
      List<AppointmentModel> mockResults = _mockAppointments
          .where((apt) => apt.customerId == customerId)
          .toList();
      
      if (status != null) {
        mockResults = mockResults.where((apt) => apt.status == status).toList();
      }
      
      mockResults.sort((a, b) => b.appointmentDate.compareTo(a.appointmentDate));
      
      if (limit != null && mockResults.length > limit) {
        mockResults = mockResults.take(limit).toList();
      }
      
      print('📱 Customer appointments: ${mockResults.length} mock randevu bulundu');
      
      // Eğer mock veri varsa onu döndür
      if (mockResults.isNotEmpty) {
        return mockResults;
      }

      // Mock veri yoksa Firebase'den dene
      Query query = _firestore
          .collection('appointments')
          .where('customerId', isEqualTo: customerId);

      if (status != null) {
        query = query.where('status', isEqualTo: status.toString().split('.').last);
      }

      query = query.orderBy('appointmentDate', descending: true);

      if (limit != null) {
        query = query.limit(limit);
      }

      final querySnapshot = await query.get();
      final firebaseResults = querySnapshot.docs
          .map((doc) => AppointmentModel.fromFirestore(doc))
          .toList();
          
      print('🔥 Firebase appointments: ${firebaseResults.length} randevu bulundu');
      return firebaseResults;
    } catch (e) {
      print('❌ Randevu getirme hatası: $e');
      // Hata durumunda mock verileri döndür
      final fallbackResults = _mockAppointments
          .where((apt) => apt.customerId == customerId)
          .toList();
      return status != null 
          ? fallbackResults.where((apt) => apt.status == status).toList()
          : fallbackResults;
    }
  }

  // Salon randevularını getirme
  Future<List<AppointmentModel>> getSalonAppointments(String salonId, {
    DateTime? startDate,
    DateTime? endDate,
    AppointmentStatus? status,
    int? limit,
  }) async {
    try {
      Query query = _firestore
          .collection('appointments')
          .where('salonId', isEqualTo: salonId);

      if (status != null) {
        query = query.where('status', isEqualTo: status.toString().split('.').last);
      }

      if (startDate != null) {
        query = query.where('appointmentDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
      }

      if (endDate != null) {
        query = query.where('appointmentDate', isLessThanOrEqualTo: Timestamp.fromDate(endDate));
      }

      query = query.orderBy('appointmentDate', descending: false);

      if (limit != null) {
        query = query.limit(limit);
      }

      final querySnapshot = await query.get();

      return querySnapshot.docs
          .map((doc) => AppointmentModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Firestore hatası, mock veri kullanılıyor: $e');
      return _mockAppointments.where((apt) => apt.salonId == salonId).toList();
    }
  }

  // Bugünkü randevuları getirme
  Future<List<AppointmentModel>> getTodayAppointments(String salonId) async {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = DateTime(today.year, today.month, today.day, 23, 59, 59);

    return await getSalonAppointments(
      salonId,
      startDate: startOfDay,
      endDate: endOfDay,
    );
  }

  // Bekleyen randevuları getirme
  Future<List<AppointmentModel>> getPendingAppointments(String salonId) async {
    return await getSalonAppointments(
      salonId,
      status: AppointmentStatus.pending,
    );
  }

  // Randevu istatistikleri
  Future<Map<String, int>> getAppointmentStats(String salonId) async {
    try {
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);

      final appointments = await getSalonAppointments(
        salonId,
        startDate: startOfMonth,
      );

      return {
        'total': appointments.length,
        'pending': appointments.where((apt) => apt.status == AppointmentStatus.pending).length,
        'confirmed': appointments.where((apt) => apt.status == AppointmentStatus.confirmed).length,
        'completed': appointments.where((apt) => apt.status == AppointmentStatus.completed).length,
        'cancelled': appointments.where((apt) => apt.status == AppointmentStatus.cancelled).length,
        'noShow': appointments.where((apt) => apt.status == AppointmentStatus.noShow).length,
      };
    } catch (e) {
      print('İstatistik alma hatası: $e');
      return {
        'total': 0,
        'pending': 0,
        'confirmed': 0,
        'completed': 0,
        'cancelled': 0,
        'noShow': 0,
      };
    }
  }

  // Müsait saatleri getirme
  Future<List<TimeOfDay>> getAvailableSlots(
    String salonId,
    DateTime date,
    Duration serviceDuration,
  ) async {
    try {
      // Salon çalışma saatlerini al (örnek sabit değerler)
      const workingStart = TimeOfDay(hour: 9, minute: 0);
      const workingEnd = TimeOfDay(hour: 18, minute: 0);

      // O gün için mevcut randevuları al
      final dayAppointments = await getSalonAppointments(
        salonId,
        startDate: DateTime(date.year, date.month, date.day),
        endDate: DateTime(date.year, date.month, date.day, 23, 59, 59),
      );

      final availableSlots = <TimeOfDay>[];
      const slotDuration = Duration(minutes: 30);
      
      var currentTime = workingStart;

      while (_timeOfDayToMinutes(currentTime) + serviceDuration.inMinutes <= 
             _timeOfDayToMinutes(workingEnd)) {
        
        final slotStart = DateTime(date.year, date.month, date.day, currentTime.hour, currentTime.minute);
        final slotEnd = slotStart.add(serviceDuration);

        final hasConflict = dayAppointments.any((appointment) {
          final appointmentStart = DateTime(
            appointment.appointmentDate.year,
            appointment.appointmentDate.month,
            appointment.appointmentDate.day,
            appointment.appointmentTime.hour,
            appointment.appointmentTime.minute,
          );
          final appointmentEnd = appointmentStart.add(appointment.totalDuration);

          return (slotStart.isBefore(appointmentEnd) && slotEnd.isAfter(appointmentStart));
        });

        if (!hasConflict) {
          availableSlots.add(currentTime);
        }

        final nextMinutes = _timeOfDayToMinutes(currentTime) + slotDuration.inMinutes;
        currentTime = TimeOfDay(
          hour: nextMinutes ~/ 60,
          minute: nextMinutes % 60,
        );
      }

      return availableSlots;
    } catch (e) {
      print('Müsait saat alma hatası: $e');
      return [];
    }
  }

  int _timeOfDayToMinutes(TimeOfDay time) {
    return time.hour * 60 + time.minute;
  }

  // Mock veri temizleme
  void clearMockData() {
    _mockAppointments.clear();
  }

  // Eksik methodlar (backward compatibility)
  List<DateTime> getAvailableDates() {
    final List<DateTime> dates = [];
    final DateTime today = DateTime.now();
    
    for (int i = 0; i < 30; i++) {
      final date = today.add(Duration(days: i));
      // Pazar günlerini hariç tut (basit örnek)
      if (date.weekday != 7) {
        dates.add(date);
      }
    }
    
    return dates;
  }

  Future<List<TimeOfDay>> getAvailableTimeSlots({
    required String salonId,
    required DateTime date,
  }) async {
    // Mevcut implementasyonu kullan
    return await getAvailableSlots(salonId, date, const Duration(minutes: 60));
  }

  // Legacy methods (backward compatibility)
  Future<List<AppointmentModel>> getUserAppointments(String userId) async {
    return await getCustomerAppointments(userId);
  }

  Future<bool> createAppointmentLegacy({
    required String customerId,
    required String customerName,
    required String customerPhone,
    required String salonId,
    required String salonName,
    required List<ServiceModel> services,
    required DateTime appointmentDate,
    required TimeOfDay appointmentTime,
    String? notes,
  }) async {
    try {
      // AuthService'den kullanıcı email'ini al
      final currentUser = _authService.currentUser;
      final customerEmail = currentUser?.email ?? '$customerId@temp.com';
      
      final appointment = AppointmentModel(
        id: '', // createAppointment içinde ID atanacak
        customerId: customerId,
        customerName: customerName,
        customerPhone: customerPhone,
        customerEmail: customerEmail,
        salonId: salonId,
        salonName: salonName,
        services: services,
        appointmentDate: appointmentDate,
        appointmentTime: appointmentTime,
        status: AppointmentStatus.pending,
        notes: notes,
        createdAt: DateTime.now(),
      );

      final appointmentId = await createAppointment(appointment);
      print('✅ Legacy randevu oluşturuldu: $appointmentId');
      return true;
    } catch (e) {
      print('❌ Legacy randevu oluşturma hatası: $e');
      return false;
    }
  }
}