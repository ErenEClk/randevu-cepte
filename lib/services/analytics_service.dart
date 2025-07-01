import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../models/appointment_model.dart';
import '../models/service_model.dart';

class AnalyticsData {
  final int totalAppointments;
  final int pendingAppointments;
  final int confirmedAppointments;
  final int completedAppointments;
  final int cancelledAppointments;
  final double totalRevenue;
  final double averageOrderValue;
  final Map<String, int> appointmentsByDay;
  final Map<String, double> revenueByDay;
  final Map<String, int> serviceStats;
  final List<String> topCustomers;
  final double growthRate;

  AnalyticsData({
    required this.totalAppointments,
    required this.pendingAppointments,
    required this.confirmedAppointments,
    required this.completedAppointments,
    required this.cancelledAppointments,
    required this.totalRevenue,
    required this.averageOrderValue,
    required this.appointmentsByDay,
    required this.revenueByDay,
    required this.serviceStats,
    required this.topCustomers,
    required this.growthRate,
  });
}

class AnalyticsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Belirli tarih aralığındaki randevuları getir
  Future<List<AppointmentModel>> _getAppointmentsInRange(
    String salonId, 
    DateTime startDate, 
    DateTime endDate
  ) async {
    try {
      final querySnapshot = await _firestore
          .collection('appointments')
          .where('salonId', isEqualTo: salonId)
          .where('appointmentDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('appointmentDate', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .get();

      return querySnapshot.docs
          .map((doc) => AppointmentModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Randevu verisi alınırken hata: $e');
      return [];
    }
  }

  // Günlük analiz verileri
  Future<AnalyticsData> getDailyAnalytics(String salonId) async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final appointments = await _getAppointmentsInRange(salonId, startOfDay, endOfDay);
    return _processAnalyticsData(appointments, 'daily');
  }

  // Haftalık analiz verileri
  Future<AnalyticsData> getWeeklyAnalytics(String salonId) async {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 7));

    final appointments = await _getAppointmentsInRange(salonId, startOfWeek, endOfWeek);
    return _processAnalyticsData(appointments, 'weekly');
  }

  // Aylık analiz verileri
  Future<AnalyticsData> getMonthlyAnalytics(String salonId) async {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 1);

    final appointments = await _getAppointmentsInRange(salonId, startOfMonth, endOfMonth);
    return _processAnalyticsData(appointments, 'monthly');
  }

  // Özel tarih aralığı analizi
  Future<AnalyticsData> getCustomRangeAnalytics(
    String salonId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final appointments = await _getAppointmentsInRange(salonId, startDate, endDate);
    return _processAnalyticsData(appointments, 'custom');
  }

  // Analiz verilerini işle
  AnalyticsData _processAnalyticsData(List<AppointmentModel> appointments, String period) {
    final pendingCount = appointments
        .where((apt) => apt.status == AppointmentStatus.pending)
        .length;
    
    final confirmedCount = appointments
        .where((apt) => apt.status == AppointmentStatus.confirmed)
        .length;
    
    final completedCount = appointments
        .where((apt) => apt.status == AppointmentStatus.completed)
        .length;
    
    final cancelledCount = appointments
        .where((apt) => apt.status == AppointmentStatus.cancelled)
        .length;

    // Gelir hesaplama (sadece tamamlanan randevular)
    final completedAppointments = appointments
        .where((apt) => apt.status == AppointmentStatus.completed);
    
    final totalRevenue = completedAppointments
        .fold(0.0, (sum, apt) => sum + apt.totalPrice);

    final averageOrderValue = completedCount > 0 
        ? totalRevenue / completedCount 
        : 0.0;

    // Günlük dağılım
    final appointmentsByDay = <String, int>{};
    final revenueByDay = <String, double>{};
    
    for (final appointment in appointments) {
      final dayKey = DateFormat('dd/MM').format(appointment.appointmentDate);
      appointmentsByDay[dayKey] = (appointmentsByDay[dayKey] ?? 0) + 1;
      
      if (appointment.status == AppointmentStatus.completed) {
        revenueByDay[dayKey] = (revenueByDay[dayKey] ?? 0) + appointment.totalPrice;
      }
    }

    // Hizmet istatistikleri
    final serviceStats = <String, int>{};
    for (final appointment in appointments) {
      for (final service in appointment.services) {
        serviceStats[service.name] = (serviceStats[service.name] ?? 0) + 1;
      }
    }

    // En çok randevu alan müşteriler
    final customerCounts = <String, int>{};
    for (final appointment in appointments) {
      customerCounts[appointment.customerName] = 
          (customerCounts[appointment.customerName] ?? 0) + 1;
    }
    
    final sortedCustomers = customerCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    final topCustomers = sortedCustomers
        .take(5)
        .map((e) => '${e.key} (${e.value})')
        .toList();

    // Büyüme oranı hesaplama (basit)
    final growthRate = _calculateGrowthRate(appointments, period);

    return AnalyticsData(
      totalAppointments: appointments.length,
      pendingAppointments: pendingCount,
      confirmedAppointments: confirmedCount,
      completedAppointments: completedCount,
      cancelledAppointments: cancelledCount,
      totalRevenue: totalRevenue,
      averageOrderValue: averageOrderValue,
      appointmentsByDay: appointmentsByDay,
      revenueByDay: revenueByDay,
      serviceStats: serviceStats,
      topCustomers: topCustomers,
      growthRate: growthRate,
    );
  }

  // Büyüme oranı hesaplama
  double _calculateGrowthRate(List<AppointmentModel> appointments, String period) {
    if (appointments.isEmpty) return 0.0;

    final now = DateTime.now();
    DateTime cutoffDate;

    switch (period) {
      case 'daily':
        cutoffDate = now.subtract(const Duration(days: 1));
        break;
      case 'weekly':
        cutoffDate = now.subtract(const Duration(days: 7));
        break;
      case 'monthly':
        cutoffDate = DateTime(now.year, now.month - 1, now.day);
        break;
      default:
        return 0.0;
    }

    final recentAppointments = appointments
        .where((apt) => apt.appointmentDate.isAfter(cutoffDate))
        .length;
    
    final olderAppointments = appointments.length - recentAppointments;

    if (olderAppointments == 0) return 100.0;
    
    return ((recentAppointments - olderAppointments) / olderAppointments) * 100;
  }

  // En çok kazandıran hizmetler
  Future<Map<String, double>> getTopRevenueServices(String salonId, int limit) async {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    
    final appointments = await _getAppointmentsInRange(salonId, startOfMonth, now);
    final completedAppointments = appointments
        .where((apt) => apt.status == AppointmentStatus.completed);

    final serviceRevenue = <String, double>{};
    
    for (final appointment in completedAppointments) {
      for (final service in appointment.services) {
        serviceRevenue[service.name] = 
            (serviceRevenue[service.name] ?? 0) + service.price;
      }
    }

    final sortedServices = serviceRevenue.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Map.fromEntries(sortedServices.take(limit));
  }

  // Müşteri sadakat analizi
  Future<Map<String, dynamic>> getCustomerLoyaltyAnalysis(String salonId) async {
    final now = DateTime.now();
    final threeMonthsAgo = DateTime(now.year, now.month - 3, now.day);
    
    final appointments = await _getAppointmentsInRange(salonId, threeMonthsAgo, now);
    
    final customerVisits = <String, List<DateTime>>{};
    
    for (final appointment in appointments) {
      if (appointment.status == AppointmentStatus.completed) {
        customerVisits[appointment.customerName] ??= [];
        customerVisits[appointment.customerName]!.add(appointment.appointmentDate);
      }
    }

    final loyalCustomers = customerVisits.entries
        .where((entry) => entry.value.length >= 3)
        .length;
    
    final newCustomers = customerVisits.entries
        .where((entry) => entry.value.length == 1)
        .length;
    
    final returningCustomers = customerVisits.entries
        .where((entry) => entry.value.length == 2)
        .length;

    return {
      'totalCustomers': customerVisits.length,
      'loyalCustomers': loyalCustomers,
      'newCustomers': newCustomers,
      'returningCustomers': returningCustomers,
      'loyaltyRate': customerVisits.isNotEmpty 
          ? (loyalCustomers / customerVisits.length) * 100 
          : 0.0,
    };
  }

  // Çalışma saatleri analizi
  Future<Map<int, int>> getBusyHours(String salonId) async {
    final now = DateTime.now();
    final oneMonthAgo = DateTime(now.year, now.month - 1, now.day);
    
    final appointments = await _getAppointmentsInRange(salonId, oneMonthAgo, now);
    final completedAppointments = appointments
        .where((apt) => apt.status == AppointmentStatus.completed);

    final hourlyStats = <int, int>{};
    
    for (final appointment in completedAppointments) {
      final hour = appointment.appointmentTime.hour;
      hourlyStats[hour] = (hourlyStats[hour] ?? 0) + 1;
    }

    return hourlyStats;
  }
} 