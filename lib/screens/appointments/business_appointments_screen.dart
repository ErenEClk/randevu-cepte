import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../services/auth_service.dart';
import '../../services/appointment_service.dart';
import '../../models/appointment_model.dart';

class BusinessAppointmentsScreen extends StatefulWidget {
  const BusinessAppointmentsScreen({super.key});

  @override
  State<BusinessAppointmentsScreen> createState() => _BusinessAppointmentsScreenState();
}

class _BusinessAppointmentsScreenState extends State<BusinessAppointmentsScreen> 
    with SingleTickerProviderStateMixin {
  final AuthService _authService = AuthService();
  final AppointmentService _appointmentService = AppointmentService();
  
  List<AppointmentModel> _allAppointments = [];
  List<AppointmentModel> _filteredAppointments = [];
  bool _isLoading = true;
  
  // Filter options
  AppointmentStatus? _selectedStatus;
  DateTime? _selectedDate;
  String _sortBy = 'date'; // date, customer, status
  bool _sortAscending = true;
  
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadAppointments();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAppointments() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = _authService.currentUser;
      if (user != null) {
        final appointments = await _appointmentService.getSalonAppointments(user.id);
        setState(() {
          _allAppointments = appointments;
          _filteredAppointments = appointments;
          _applyFiltersAndSort();
        });
      }
    } catch (e) {
      print('Randevular yüklenirken hata: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _applyFiltersAndSort() {
    List<AppointmentModel> filtered = List.from(_allAppointments);

    // Status filtresi
    if (_selectedStatus != null) {
      filtered = filtered.where((apt) => apt.status == _selectedStatus).toList();
    }

    // Tarih filtresi
    if (_selectedDate != null) {
      filtered = filtered.where((apt) {
        final aptDate = DateTime(apt.appointmentDate.year, 
                               apt.appointmentDate.month, 
                               apt.appointmentDate.day);
        final selDate = DateTime(_selectedDate!.year, 
                               _selectedDate!.month, 
                               _selectedDate!.day);
        return aptDate.isAtSameMomentAs(selDate);
      }).toList();
    }

    // Sıralama
    filtered.sort((a, b) {
      int comparison = 0;
      switch (_sortBy) {
        case 'date':
          comparison = a.appointmentDate.compareTo(b.appointmentDate);
          if (comparison == 0) {
            comparison = a.appointmentTime.hour.compareTo(b.appointmentTime.hour);
            if (comparison == 0) {
              comparison = a.appointmentTime.minute.compareTo(b.appointmentTime.minute);
            }
          }
          break;
        case 'customer':
          comparison = a.customerName.compareTo(b.customerName);
          break;
        case 'status':
          comparison = a.status.index.compareTo(b.status.index);
          break;
      }
      return _sortAscending ? comparison : -comparison;
    });

    setState(() {
      _filteredAppointments = filtered;
    });
  }

  List<AppointmentModel> _getAppointmentsByStatus(AppointmentStatus status) {
    return _allAppointments.where((apt) => apt.status == status).toList()
      ..sort((a, b) => a.appointmentDate.compareTo(b.appointmentDate));
  }

  Future<void> _handleAppointmentAction(AppointmentModel appointment, AppointmentStatus newStatus) async {
    try {
      bool success = false;
      switch (newStatus) {
        case AppointmentStatus.confirmed:
          await _appointmentService.confirmAppointment(appointment.id);
          success = true;
          break;
        case AppointmentStatus.rejected:
          await _appointmentService.rejectAppointment(appointment.id, 'Uygun değil');
          success = true;
          break;
        case AppointmentStatus.completed:
          await _appointmentService.completeAppointment(appointment.id);
          success = true;
          break;
        default:
          return;
      }

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_getStatusActionText(newStatus)),
            backgroundColor: _getStatusColor(newStatus),
          ),
        );
        _loadAppointments();
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

  String _getStatusActionText(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.confirmed:
        return 'Randevu onaylandı';
      case AppointmentStatus.rejected:
        return 'Randevu reddedildi';
      case AppointmentStatus.completed:
        return 'Randevu tamamlandı';
      default:
        return 'İşlem gerçekleştirildi';
    }
  }

  Color _getStatusColor(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.confirmed:
        return AppColors.success;
      case AppointmentStatus.rejected:
        return AppColors.error;
      case AppointmentStatus.completed:
        return AppColors.primary;
      default:
        return AppColors.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Randevu Yönetimi'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            onPressed: _showFilterDialog,
            icon: const Icon(Icons.filter_list),
          ),
          IconButton(
            onPressed: _loadAppointments,
            icon: const Icon(Icons.refresh),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: [
            Tab(
              text: 'Tümü (${_allAppointments.length})',
            ),
            Tab(
              text: 'Bekleyen (${_getAppointmentsByStatus(AppointmentStatus.pending).length})',
            ),
            Tab(
              text: 'Onaylı (${_getAppointmentsByStatus(AppointmentStatus.confirmed).length})',
            ),
            Tab(
              text: 'Tamamlanan (${_getAppointmentsByStatus(AppointmentStatus.completed).length})',
            ),
            Tab(
              text: 'İptal/Red (${_getAppointmentsByStatus(AppointmentStatus.cancelled).length + _getAppointmentsByStatus(AppointmentStatus.rejected).length})',
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildAppointmentsList(_filteredAppointments),
                _buildAppointmentsList(_getAppointmentsByStatus(AppointmentStatus.pending)),
                _buildAppointmentsList(_getAppointmentsByStatus(AppointmentStatus.confirmed)),
                _buildAppointmentsList(_getAppointmentsByStatus(AppointmentStatus.completed)),
                _buildAppointmentsList([
                  ..._getAppointmentsByStatus(AppointmentStatus.cancelled),
                  ..._getAppointmentsByStatus(AppointmentStatus.rejected),
                ]),
              ],
            ),
    );
  }

  Widget _buildAppointmentsList(List<AppointmentModel> appointments) {
    if (appointments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_busy,
              size: 64,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              'Bu kategoride randevu bulunmuyor',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAppointments,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: appointments.length,
        itemBuilder: (context, index) {
          final appointment = appointments[index];
          return _buildAppointmentCard(appointment);
        },
      ),
    );
  }

  Widget _buildAppointmentCard(AppointmentModel appointment) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  child: Text(
                    appointment.customerName[0].toUpperCase(),
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        appointment.customerName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        appointment.customerPhone,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: appointment.statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    appointment.statusText,
                    style: TextStyle(
                      color: appointment.statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Date and time
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 8),
                Text(
                  appointment.dateTimeText,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Services
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.content_cut,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    appointment.services.map((s) => s.name).join(", "),
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Price and duration
            Row(
              children: [
                Icon(
                  Icons.attach_money,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 8),
                Text(
                  '${appointment.totalPrice}₺ • ${appointment.totalDuration}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),

            // Notes
            if (appointment.notes?.isNotEmpty == true) ...[
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.note,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Not: ${appointment.notes}',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ],

            // Action buttons
            if (appointment.status == AppointmentStatus.pending) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _handleAppointmentAction(
                        appointment, 
                        AppointmentStatus.rejected
                      ),
                      icon: const Icon(Icons.close, size: 16),
                      label: const Text('Reddet'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.error),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _handleAppointmentAction(
                        appointment, 
                        AppointmentStatus.confirmed
                      ),
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text('Onayla'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ] else if (appointment.status == AppointmentStatus.confirmed) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _handleAppointmentAction(
                    appointment, 
                    AppointmentStatus.completed
                  ),
                  icon: const Icon(Icons.done_all, size: 16),
                  label: const Text('Tamamlandı Olarak İşaretle'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Filtreleme ve Sıralama'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status Filter
                const Text(
                  'Durum Filtresi',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                DropdownButton<AppointmentStatus?>(
                  value: _selectedStatus,
                  isExpanded: true,
                  hint: const Text('Tüm durumlar'),
                  items: [
                    const DropdownMenuItem<AppointmentStatus?>(
                      value: null,
                      child: Text('Tüm durumlar'),
                    ),
                    ...AppointmentStatus.values.map((status) => 
                      DropdownMenuItem<AppointmentStatus?>(
                        value: status,
                        child: Text(_getStatusDisplayName(status)),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    setDialogState(() {
                      _selectedStatus = value;
                    });
                  },
                ),
                const SizedBox(height: 16),

                // Date Filter
                const Text(
                  'Tarih Filtresi',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _selectedDate == null 
                            ? 'Tüm tarihler'
                            : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                      ),
                    ),
                    TextButton(
                      onPressed: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _selectedDate ?? DateTime.now(),
                          firstDate: DateTime.now().subtract(const Duration(days: 365)),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (date != null) {
                          setDialogState(() {
                            _selectedDate = date;
                          });
                        }
                      },
                      child: const Text('Seç'),
                    ),
                    TextButton(
                      onPressed: () {
                        setDialogState(() {
                          _selectedDate = null;
                        });
                      },
                      child: const Text('Temizle'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Sort Options
                const Text(
                  'Sıralama',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                DropdownButton<String>(
                  value: _sortBy,
                  isExpanded: true,
                  items: const [
                    DropdownMenuItem(
                      value: 'date',
                      child: Text('Tarih ve Saat'),
                    ),
                    DropdownMenuItem(
                      value: 'customer',
                      child: Text('Müşteri Adı'),
                    ),
                    DropdownMenuItem(
                      value: 'status',
                      child: Text('Durum'),
                    ),
                  ],
                  onChanged: (value) {
                    setDialogState(() {
                      _sortBy = value!;
                    });
                  },
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Checkbox(
                      value: _sortAscending,
                      onChanged: (value) {
                        setDialogState(() {
                          _sortAscending = value!;
                        });
                      },
                    ),
                    const Text('Artan sıralama'),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                setDialogState(() {
                  _selectedStatus = null;
                  _selectedDate = null;
                  _sortBy = 'date';
                  _sortAscending = true;
                });
              },
              child: const Text('Temizle'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _applyFiltersAndSort();
                });
                Navigator.of(context).pop();
              },
              child: const Text('Uygula'),
            ),
          ],
        ),
      ),
    );
  }

  String _getStatusDisplayName(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.pending:
        return 'Bekleyen';
      case AppointmentStatus.confirmed:
        return 'Onaylı';
      case AppointmentStatus.completed:
        return 'Tamamlanan';
      case AppointmentStatus.cancelled:
        return 'İptal Edilen';
      case AppointmentStatus.rejected:
        return 'Reddedilen';
      case AppointmentStatus.noShow:
        return 'Gelmedi';
    }
  }
} 