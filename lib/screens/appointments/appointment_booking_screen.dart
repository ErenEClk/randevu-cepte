import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../models/salon_model.dart';
import '../../models/service_model.dart';
import '../../models/user_model.dart';
import '../../services/appointment_service.dart';
import '../../services/auth_service.dart';
import '../../services/salon_service.dart';

class AppointmentBookingScreen extends StatefulWidget {
  final SalonModel salon;

  const AppointmentBookingScreen({
    super.key,
    required this.salon,
  });

  @override
  State<AppointmentBookingScreen> createState() => _AppointmentBookingScreenState();
}

class _AppointmentBookingScreenState extends State<AppointmentBookingScreen> {
  int currentStep = 0;
  
  // Seçilen değerler
  List<ServiceModel> selectedServices = [];
  DateTime? selectedDate;
  TimeOfDay? selectedTime;
  final TextEditingController notesController = TextEditingController();
  
  // Servisler
  final AppointmentService _appointmentService = AppointmentService();
  final AuthService _authService = AuthService();
  final SalonService _salonService = SalonService();
  
  // Loading states
  bool isLoadingTimeSlots = false;
  bool isBooking = false;
  bool isLoadingServices = true;
  
  // Mevcut tarih ve saatler
  List<DateTime> availableDates = [];
  List<TimeOfDay> availableTimeSlots = [];
  List<ServiceModel> availableServices = [];

  @override
  void initState() {
    super.initState();
    _loadAvailableDates();
    _loadServices();
  }

  Future<void> _loadServices() async {
    try {
      setState(() {
        isLoadingServices = true;
      });
      
      print('🔍 Randevu Al - salon hizmetleri yükleniyor: ${widget.salon.ownerId}');
      final services = await _salonService.getSalonServices(widget.salon.ownerId);
      
      setState(() {
        availableServices = services;
        isLoadingServices = false;
      });
      
      print('✅ Randevu Al - ${availableServices.length} hizmet yüklendi');
    } catch (e) {
      print('❌ Randevu Al - hizmet yükleme hatası: $e');
      setState(() {
        availableServices = widget.salon.services; // Fallback to mock data
        isLoadingServices = false;
      });
    }
  }

  void _loadAvailableDates() {
    setState(() {
      availableDates = _appointmentService.getAvailableDates();
    });
  }

  Future<void> _loadAvailableTimeSlots(DateTime date) async {
    setState(() {
      isLoadingTimeSlots = true;
      selectedTime = null;
    });

    try {
      final timeSlots = await _appointmentService.getAvailableTimeSlots(
        salonId: widget.salon.id,
        date: date,
      );
      
      setState(() {
        availableTimeSlots = timeSlots;
        isLoadingTimeSlots = false;
      });
    } catch (e) {
      setState(() {
        isLoadingTimeSlots = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Müsait saatler yüklenirken hata oluştu'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _bookAppointment() async {
    if (selectedServices.isEmpty || selectedDate == null || selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen tüm alanları doldurun'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      isBooking = true;
    });

    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        throw Exception('Kullanıcı girişi yapılmamış');
      }

      final success = await _appointmentService.createAppointmentLegacy(
        customerId: currentUser.id,
        customerName: currentUser.fullName,
        customerPhone: currentUser.phoneNumber,
        salonId: widget.salon.id,
        salonName: widget.salon.name,
        services: selectedServices,
        appointmentDate: selectedDate!,
        appointmentTime: selectedTime!,
        notes: notesController.text.trim().isEmpty ? null : notesController.text.trim(),
      );

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Randevunuz başarıyla oluşturuldu!'),
              backgroundColor: AppColors.primary,
            ),
          );
          Navigator.of(context).pop(true); // Geri dön ve refresh için true gönder
        }
      } else {
        throw Exception('Randevu oluşturulamadı');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isBooking = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Randevu Al'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Salon Bilgileri
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: widget.salon.imageUrl != null && widget.salon.imageUrl!.isNotEmpty
                      ? Image.network(
                          widget.salon.imageUrl!,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 60,
                              height: 60,
                              color: AppColors.lightGrey,
                              child: const Icon(Icons.store, color: AppColors.primary),
                            );
                          },
                        )
                      : Container(
                          width: 60,
                          height: 60,
                          color: AppColors.lightGrey,
                          child: const Icon(Icons.store, color: AppColors.primary),
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.salon.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.salon.address,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            '${widget.salon.rating}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Stepper
          Expanded(
            child: Theme(
              data: Theme.of(context).copyWith(
                colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: AppColors.primary,
                ),
              ),
              child: Stepper(
                currentStep: currentStep,
                onStepTapped: (step) {
                  if (step <= currentStep) {
                    setState(() {
                      currentStep = step;
                    });
                  }
                },
                controlsBuilder: (context, details) {
                  return Row(
                    children: [
                      if (details.stepIndex < 3)
                        ElevatedButton(
                          onPressed: _canProceedToNextStep() ? () {
                            setState(() {
                              currentStep = details.stepIndex + 1;
                            });
                          } : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('İleri'),
                        ),
                      if (details.stepIndex == 3)
                        ElevatedButton(
                          onPressed: isBooking ? null : _bookAppointment,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                          ),
                          child: isBooking 
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Text('Randevu Al'),
                        ),
                      const SizedBox(width: 8),
                      if (details.stepIndex > 0)
                        TextButton(
                          onPressed: () {
                            setState(() {
                              currentStep = details.stepIndex - 1;
                            });
                          },
                          child: const Text('Geri'),
                        ),
                    ],
                  );
                },
                steps: [
                  Step(
                    title: const Text('Hizmet Seçin'),
                    content: _buildServiceSelection(),
                    isActive: currentStep >= 0,
                    state: currentStep > 0 
                        ? StepState.complete 
                        : currentStep == 0 
                            ? StepState.indexed 
                            : StepState.disabled,
                  ),
                  Step(
                    title: const Text('Tarih Seçin'),
                    content: _buildDateSelection(),
                    isActive: currentStep >= 1,
                    state: currentStep > 1 
                        ? StepState.complete 
                        : currentStep == 1 
                            ? StepState.indexed 
                            : StepState.disabled,
                  ),
                  Step(
                    title: const Text('Saat Seçin'),
                    content: _buildTimeSelection(),
                    isActive: currentStep >= 2,
                    state: currentStep > 2 
                        ? StepState.complete 
                        : currentStep == 2 
                            ? StepState.indexed 
                            : StepState.disabled,
                  ),
                  Step(
                    title: const Text('Onaylayın'),
                    content: _buildConfirmation(),
                    isActive: currentStep >= 3,
                    state: currentStep == 3 
                        ? StepState.indexed 
                        : StepState.disabled,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _canProceedToNextStep() {
    switch (currentStep) {
      case 0:
        return selectedServices.isNotEmpty;
      case 1:
        return selectedDate != null;
      case 2:
        return selectedTime != null;
      default:
        return false;
    }
  }

  Widget _buildServiceSelection() {
    if (isLoadingServices) {
      return const Center(
        child: Column(
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Hizmetler yükleniyor...'),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Hangi hizmetleri almak istiyorsunuz?',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 16),
        if (availableServices.isEmpty)
          const Text('Bu salon için henüz hizmet tanımlanmamış.')
        else
          ...availableServices.map((service) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: CheckboxListTile(
                  title: Text(service.name),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (service.description.isNotEmpty)
                        Text(service.description),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            service.priceText,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Text(
                            service.durationText,
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ],
                  ),
                  value: selectedServices.contains(service),
                  onChanged: (bool? value) {
                    setState(() {
                      if (value == true) {
                        selectedServices.add(service);
                      } else {
                        selectedServices.remove(service);
                      }
                    });
                  },
                  activeColor: AppColors.primary,
                ),
              )).toList(),
        if (selectedServices.isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Toplam:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${selectedServices.fold(0.0, (sum, service) => sum + service.price).toStringAsFixed(0)} ₺',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      _getTotalDurationText(),
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  String _getTotalDurationText() {
    final totalMinutes = selectedServices.fold<int>(0, (sum, service) => sum + service.durationMinutes);
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    
    if (hours > 0) {
      return '${hours}s ${minutes}dk';
    } else {
      return '${minutes}dk';
    }
  }

  Widget _buildDateSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Hangi tarihte randevu almak istiyorsunuz?',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: availableDates.length,
            itemBuilder: (context, index) {
              final date = availableDates[index];
              final isSelected = selectedDate != null &&
                  selectedDate!.year == date.year &&
                  selectedDate!.month == date.month &&
                  selectedDate!.day == date.day;
              
              return GestureDetector(
                onTap: () {
                  setState(() {
                    selectedDate = date;
                  });
                  _loadAvailableTimeSlots(date);
                },
                child: Container(
                  width: 80,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : Colors.white,
                    border: Border.all(
                      color: isSelected ? AppColors.primary : Colors.grey.shade300,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _getDayName(date.weekday),
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${date.day}',
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.black,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getMonthName(date.month),
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTimeSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Saat seçiniz:',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 16),
        if (selectedDate == null)
          const Text('Önce bir tarih seçiniz.')
        else if (isLoadingTimeSlots)
          const Center(child: CircularProgressIndicator())
        else if (availableTimeSlots.isEmpty)
          const Text('Bu tarih için müsait saat bulunmuyor.')
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: availableTimeSlots.map((time) {
              final isSelected = selectedTime?.hour == time.hour &&
                  selectedTime?.minute == time.minute;
              
              return GestureDetector(
                onTap: () {
                  setState(() {
                    selectedTime = time;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : Colors.white,
                    border: Border.all(
                      color: isSelected ? AppColors.primary : Colors.grey.shade300,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildConfirmation() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Randevu Özeti',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        
        // Salon Bilgisi
        _buildSummaryCard(
          'Salon',
          widget.salon.name,
          Icons.store,
        ),
        
        // Hizmetler
        _buildSummaryCard(
          'Hizmetler',
          selectedServices.map((s) => s.name).join(', '),
          Icons.content_cut,
        ),
        
        // Tarih ve Saat
        if (selectedDate != null && selectedTime != null)
          _buildSummaryCard(
            'Tarih & Saat',
            '${selectedDate!.day}.${selectedDate!.month}.${selectedDate!.year} - ${selectedTime!.hour.toString().padLeft(2, '0')}:${selectedTime!.minute.toString().padLeft(2, '0')}',
            Icons.schedule,
          ),
        
        // Toplam Fiyat
        _buildSummaryCard(
          'Toplam Tutar',
          '${selectedServices.fold(0.0, (sum, service) => sum + service.price).toStringAsFixed(0)} ₺',
          Icons.payment,
        ),
        
        // Notlar
        const SizedBox(height: 16),
        TextField(
          controller: notesController,
          decoration: const InputDecoration(
            labelText: 'Notlar (İsteğe bağlı)',
            hintText: 'Özel isteklerinizi yazabilirsiniz...',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
      ],
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: AppColors.primary),
        title: Text(title),
        subtitle: Text(value),
      ),
    );
  }

  String _getDayName(int weekday) {
    const days = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
    return days[weekday - 1];
  }

  String _getMonthName(int month) {
    const months = [
      'Oca', 'Şub', 'Mar', 'Nis', 'May', 'Haz',
      'Tem', 'Ağu', 'Eyl', 'Eki', 'Kas', 'Ara'
    ];
    return months[month - 1];
  }

  @override
  void dispose() {
    notesController.dispose();
    super.dispose();
  }
} 