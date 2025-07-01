import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../services/auth_service.dart';
import '../../services/appointment_service.dart';
import '../../services/salon_service.dart';
import '../../services/balance_service.dart';
import '../../models/appointment_model.dart';
import '../../models/user_model.dart';
import '../../models/salon_model.dart';
import '../../models/business_balance_model.dart';
import '../business/service_management_screen.dart';
import '../business/business_profile_setup_screen.dart';
import '../business/working_hours_screen.dart';
import '../business/balance_screen.dart';
import '../appointments/business_appointments_screen.dart';
import '../business/photo_management_screen.dart';
import '../business/analytics_screen.dart';
import '../chat/business_chat_list_screen.dart';

class BusinessHomeScreen extends StatefulWidget {
  const BusinessHomeScreen({super.key});

  @override
  State<BusinessHomeScreen> createState() => _BusinessHomeScreenState();
}

class _BusinessHomeScreenState extends State<BusinessHomeScreen> {
  final AuthService _authService = AuthService();
  final AppointmentService _appointmentService = AppointmentService();
  final SalonService _salonService = SalonService();
  final BalanceService _balanceService = BalanceService();
  
  List<AppointmentModel> _pendingAppointments = [];
  List<AppointmentModel> _todayAppointments = [];
  SalonModel? _userSalon;
  BusinessBalanceModel? _balance;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBusinessData();
  }

  Future<void> _loadBusinessData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = _authService.currentUser;
      if (user != null) {
        // Kullanıcının salonunu kontrol et
        final salon = await _salonService.getUserSalon(user.id);
        
        if (salon != null) {
          // Salon varsa randevuları ve bakiyeyi getir
          final appointments = await _appointmentService.getSalonAppointments(user.id);
          final balance = await _balanceService.getBusinessBalance(user.id);
          
          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);
          
          setState(() {
            _userSalon = salon;
            _balance = balance;
            _pendingAppointments = appointments
                .where((apt) => apt.status == AppointmentStatus.pending)
                .toList();
            
            _todayAppointments = appointments
                .where((apt) {
                  final aptDate = DateTime(apt.appointmentDate.year, 
                                         apt.appointmentDate.month, 
                                         apt.appointmentDate.day);
                  return aptDate.isAtSameMomentAs(today) && 
                         apt.status == AppointmentStatus.confirmed;
                })
                .toList();
          });
        } else {
          setState(() {
            _userSalon = null;
            _balance = null;
          });
        }
      }
    } catch (e) {
      print('Esnaf verileri yüklenirken hata: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _handleAppointmentAction(AppointmentModel appointment, AppointmentStatus newStatus) async {
    try {
      if (newStatus == AppointmentStatus.confirmed) {
        await _appointmentService.confirmAppointment(appointment.id);
      } else {
        await _appointmentService.rejectAppointment(appointment.id, 'Uygun değil');
      }

      final bool success = true;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newStatus == AppointmentStatus.confirmed 
                  ? 'Randevu onaylandı' 
                  : 'Randevu reddedildi'
            ),
            backgroundColor: newStatus == AppointmentStatus.confirmed 
                ? AppColors.success 
                : AppColors.error,
          ),
        );
        _loadBusinessData(); // Verileri yenile
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Hata: ${e.toString()}'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _showLogoutDialog() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Çıkış Yap'),
        content: const Text('Çıkış yapmak istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Çıkış Yap'),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      try {
        await _authService.signOut();
        if (mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil(
            '/welcome',
            (route) => false,
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Çıkış yapılırken hata: ${e.toString()}'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  void _showNotificationsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.notifications, color: AppColors.primary),
            const SizedBox(width: 8),
            const Text('Bildirimler'),
            const Spacer(),
            if (_pendingAppointments.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.error,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _pendingAppointments.length.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: _pendingAppointments.isEmpty
              ? const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.notifications_off_outlined,
                      size: 48,
                      color: AppColors.textLight,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Yeni bildirim yok',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                )
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: _pendingAppointments.length,
                  itemBuilder: (context, index) {
                    final appointment = _pendingAppointments[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.warning.withOpacity(0.1),
                          child: Icon(
                            Icons.pending_actions,
                            color: AppColors.warning,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          'Yeni Randevu Talebi',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                                                 subtitle: Text(
                           '${appointment.customerName} - ${appointment.services.isNotEmpty ? appointment.services.first.name : 'Hizmet'}',
                           style: const TextStyle(fontSize: 12),
                         ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                                _handleAppointmentAction(appointment, AppointmentStatus.confirmed);
                              },
                              icon: const Icon(Icons.check, color: AppColors.success, size: 20),
                              tooltip: 'Onayla',
                            ),
                            IconButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                                _handleAppointmentAction(appointment, AppointmentStatus.rejected);
                              },
                              icon: const Icon(Icons.close, color: AppColors.error, size: 20),
                              tooltip: 'Reddet',
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Kapat'),
          ),
          if (_pendingAppointments.isNotEmpty)
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const BusinessAppointmentsScreen(),
                  ),
                );
              },
              child: const Text('Tümünü Gör'),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;
    
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('İşletme Paneli'),
        automaticallyImplyLeading: false,
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () {
                  _showNotificationsDialog();
                },
              ),
              if (_pendingAppointments.isNotEmpty)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      _pendingAppointments.length.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          PopupMenuButton<String>(
            onSelected: (value) async {
              switch (value) {
                case 'profile':
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const BusinessProfileSetupScreen(),
                    ),
                  );
                  break;
                case 'logout':
                  await _showLogoutDialog();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'profile',
                child: Row(
                  children: [
                    Icon(Icons.edit, size: 18),
                    SizedBox(width: 8),
                    Text('Profili Düzenle'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, size: 18, color: AppColors.error),
                    SizedBox(width: 8),
                    Text('Çıkış Yap', style: TextStyle(color: AppColors.error)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _userSalon == null
              ? _buildSalonSetupPrompt()
              : _buildBusinessDashboard(user),
    );
  }

  Widget _buildSalonSetupPrompt() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // İkon
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(100),
            ),
            child: const Icon(
              Icons.business_center,
              color: AppColors.primary,
              size: 64,
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Başlık
          const Text(
            'İşletme Profilinizi Oluşturun',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 16),
          
          // Açıklama
          const Text(
            'Müşterilerin sizi bulabilmesi ve randevu alabilmesi için önce işletme profilinizi tamamlamanız gerekiyor.',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 32),
          
          // Özellikler
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildFeatureItem(Icons.location_on, 'Konum bilgilerinizi ekleyin'),
                  const SizedBox(height: 12),
                  _buildFeatureItem(Icons.schedule, 'Çalışma saatlerinizi belirleyin'),
                  const SizedBox(height: 12),
                  _buildFeatureItem(Icons.content_cut, 'Sunduğunuz hizmetleri tanımlayın'),
                  const SizedBox(height: 12),
                  _buildFeatureItem(Icons.star, 'Müşteri yorumları alın'),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Başla Butonu
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => const BusinessProfileSetupScreen(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'İşletme Profilimi Oluştur',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Daha sonra butonu
          TextButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('İşletme profili oluşturmadan sistem kullanılamaz'),
                  backgroundColor: AppColors.warning,
                ),
              );
            },
            child: const Text(
              'Daha Sonra',
              style: TextStyle(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(
          icon,
          color: AppColors.primary,
          size: 20,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBusinessDashboard(UserModel? user) {
    return RefreshIndicator(
      onRefresh: _loadBusinessData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hoş Geldiniz Kartı
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.business,
                        color: AppColors.primary,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hoş geldiniz,',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            user?.fullName ?? 'Esnaf',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            _userSalon?.name ?? 'İşletme Paneli',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Bakiye Kartı
            if (_balance != null) ...[
              InkWell(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const BalanceScreen(),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, Color(0xFF6366F1)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.account_balance_wallet,
                            color: Colors.white,
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Toplam Bakiye',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                          const Spacer(),
                          const Icon(
                            Icons.arrow_forward_ios,
                            color: Colors.white70,
                            size: 16,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _balance!.totalBalanceText,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Kullanılabilir: ${_balance!.availableBalanceText}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // İstatistik Kartları
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Bekleyen',
                    _pendingAppointments.length.toString(),
                    Icons.pending_actions,
                    AppColors.warning,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatCard(
                    'Bugün',
                    _todayAppointments.length.toString(),
                    Icons.today,
                    AppColors.primary,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatCard(
                    'Bu Hafta',
                    '12', // TODO: Gerçek veri
                    Icons.date_range,
                    AppColors.success,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Hızlı Erişim Butonları
            Row(
              children: [
                Expanded(
                  child: _buildQuickActionCard(
                    icon: Icons.content_cut,
                    title: 'Hizmetlerim',
                    subtitle: 'Hizmet yönetimi',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const ServiceManagementScreen(),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickActionCard(
                    icon: Icons.schedule,
                    title: 'Çalışma Saatleri',
                    subtitle: 'Saatleri düzenle',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const WorkingHoursScreen(),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // İkinci sıra butonlar
            Row(
              children: [
                Expanded(
                  child: _buildQuickActionCard(
                    icon: Icons.calendar_today,
                    title: 'Randevu Yönetimi',
                    subtitle: 'Randevuları görüntüle',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const BusinessAppointmentsScreen(),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickActionCard(
                    icon: Icons.account_balance_wallet,
                    title: 'Bakiye',
                    subtitle: 'Kazançları görüntüle',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const BalanceScreen(),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Üçüncü sıra butonlar
            Row(
              children: [
                Expanded(
                  child: _buildQuickActionCard(
                    icon: Icons.message,
                    title: 'Müşteri Mesajları',
                    subtitle: 'Mesajları görüntüle',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const BusinessChatListScreen(),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickActionCard(
                    icon: Icons.analytics,
                    title: 'İstatistikler',
                    subtitle: 'Raporları görüntüle',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const AnalyticsScreen(),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Dördüncü sıra butonlar
            Row(
              children: [
                Expanded(
                  child: _buildQuickActionCard(
                    icon: Icons.settings,
                    title: 'Ayarlar',
                    subtitle: 'İşletme ayarları',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const BusinessProfileSetupScreen(),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickActionCard(
                    icon: Icons.photo_library,
                    title: 'Fotoğraflar',
                    subtitle: 'Galeri yönetimi',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const PhotoManagementScreen(),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Bekleyen Randevular Bölümü
            if (_pendingAppointments.isNotEmpty) ...[
              const Text(
                'Bekleyen Randevular',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _pendingAppointments.length > 3 ? 3 : _pendingAppointments.length,
                itemBuilder: (context, index) {
                  final appointment = _pendingAppointments[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppColors.warning.withOpacity(0.1),
                        child: Icon(
                          Icons.pending_actions,
                          color: AppColors.warning,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        appointment.customerName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                                                 children: [
                           Text(appointment.services.isNotEmpty ? appointment.services.first.name : 'Hizmet'),
                           const SizedBox(height: 4),
                          Text(
                            '${appointment.appointmentDate.day}/${appointment.appointmentDate.month} - ${appointment.appointmentTime}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            onPressed: () => _handleAppointmentAction(appointment, AppointmentStatus.confirmed),
                            icon: const Icon(Icons.check, color: AppColors.success),
                            tooltip: 'Onayla',
                          ),
                          IconButton(
                            onPressed: () => _handleAppointmentAction(appointment, AppointmentStatus.rejected),
                            icon: const Icon(Icons.close, color: AppColors.error),
                            tooltip: 'Reddet',
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              if (_pendingAppointments.length > 3) ...[
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const BusinessAppointmentsScreen(),
                      ),
                    );
                  },
                  child: Text('${_pendingAppointments.length - 3} randevu daha var - Tümünü Gör'),
                ),
              ],
              const SizedBox(height: 24),
            ],

            // Bugünkü Randevular Bölümü
            if (_todayAppointments.isNotEmpty) ...[
              const Text(
                'Bugünkü Randevular',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _todayAppointments.length > 3 ? 3 : _todayAppointments.length,
                itemBuilder: (context, index) {
                  final appointment = _todayAppointments[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppColors.primary.withOpacity(0.1),
                        child: Icon(
                          Icons.today,
                          color: AppColors.primary,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        appointment.customerName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                                                 children: [
                           Text(appointment.services.isNotEmpty ? appointment.services.first.name : 'Hizmet'),
                           const SizedBox(height: 4),
                           Text(
                             '${appointment.appointmentTime.hour.toString().padLeft(2, '0')}:${appointment.appointmentTime.minute.toString().padLeft(2, '0')}',
                             style: const TextStyle(
                               fontSize: 12,
                               color: AppColors.textSecondary,
                             ),
                           ),
                        ],
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.success.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Onaylı',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.success,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              if (_todayAppointments.length > 3) ...[
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const BusinessAppointmentsScreen(),
                      ),
                    );
                  },
                  child: Text('${_todayAppointments.length - 3} randevu daha var - Tümünü Gör'),
                ),
              ],
              const SizedBox(height: 24),
            ],

            // Başarı mesajı
            Card(
              color: AppColors.success.withOpacity(0.1),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      color: AppColors.success,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Randevu Sistemi Aktif',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.success,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'İşletmeniz artık müşterilerden randevu alabilir. Randevu isteklerini takip edin ve yönetin.',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const Spacer(),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 10,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
} 