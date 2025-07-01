import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../models/salon_model.dart';
import '../../services/salon_service.dart';
import '../../services/auth_service.dart';

class WorkingHoursScreen extends StatefulWidget {
  const WorkingHoursScreen({Key? key}) : super(key: key);

  @override
  State<WorkingHoursScreen> createState() => _WorkingHoursScreenState();
}

class _WorkingHoursScreenState extends State<WorkingHoursScreen> {
  final SalonService _salonService = SalonService();
  final AuthService _authService = AuthService();
  
  bool _isLoading = true;
  bool _isSaving = false;
  SalonModel? _salon;
  
  Map<String, List<String>> _workingHours = {
    'Pazartesi': ['09:00', '18:00'],
    'Salı': ['09:00', '18:00'],
    'Çarşamba': ['09:00', '18:00'],
    'Perşembe': ['09:00', '18:00'],
    'Cuma': ['09:00', '18:00'],
    'Cumartesi': ['10:00', '17:00'],
    'Pazar': ['Kapalı', 'Kapalı'],
  };

  @override
  void initState() {
    super.initState();
    _loadSalonData();
  }

  Future<void> _loadSalonData() async {
    try {
      final user = _authService.currentUser;
      if (user != null) {
        final salon = await _salonService.getUserSalon(user.id);
        if (salon != null) {
          setState(() {
            _salon = salon;
            _workingHours = Map<String, List<String>>.from(salon.workingHours);
          });
        }
      }
    } catch (e) {
      print('Salon verisi yüklenirken hata: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveWorkingHours() async {
    if (_salon == null) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final updatedSalon = _salon!.copyWith(
        workingHours: _workingHours,
      );

      await _salonService.updateSalon(updatedSalon);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Çalışma saatleri güncellendi'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  void _toggleDayStatus(String day) {
    setState(() {
      if (_workingHours[day]![0] == 'Kapalı') {
        _workingHours[day] = ['09:00', '18:00'];
      } else {
        _workingHours[day] = ['Kapalı', 'Kapalı'];
      }
    });
  }

  Future<void> _selectTime(String day, bool isOpeningTime) async {
    if (_workingHours[day]![0] == 'Kapalı') return;

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: int.parse(_workingHours[day]![isOpeningTime ? 0 : 1].split(':')[0]),
        minute: int.parse(_workingHours[day]![isOpeningTime ? 0 : 1].split(':')[1]),
      ),
    );

    if (picked != null) {
      final timeString = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      
      setState(() {
        if (isOpeningTime) {
          _workingHours[day]![0] = timeString;
        } else {
          _workingHours[day]![1] = timeString;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Çalışma Saatleri'),
        actions: [
          if (!_isLoading)
            IconButton(
              onPressed: _isSaving ? null : _saveWorkingHours,
              icon: _isSaving 
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.save),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Bilgi kartı
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Müşteriler bu saatlerde randevu alabilecek. Kapalı günlerde randevu alınamaz.',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Çalışma saatleri listesi
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _workingHours.keys.length,
                    itemBuilder: (context, index) {
                      final day = _workingHours.keys.elementAt(index);
                      final hours = _workingHours[day]!;
                      final isClosed = hours[0] == 'Kapalı';

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      day,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                  Switch(
                                    value: !isClosed,
                                    onChanged: (value) => _toggleDayStatus(day),
                                    activeColor: AppColors.primary,
                                  ),
                                ],
                              ),
                              
                              if (!isClosed) ...[
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildTimeSelector(
                                        'Açılış',
                                        hours[0],
                                        () => _selectTime(day, true),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: _buildTimeSelector(
                                        'Kapanış',
                                        hours[1],
                                        () => _selectTime(day, false),
                                      ),
                                    ),
                                  ],
                                ),
                              ] else ...[
                                const SizedBox(height: 8),
                                Text(
                                  'Kapalı',
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Alt butonlar
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : _saveWorkingHours,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: _isSaving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Kaydet',
                                  style: TextStyle(fontSize: 16),
                                ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: TextButton(
                          onPressed: _applyToAllDays,
                          child: const Text('Hafta İçi Saatleri Tüm Günlere Uygula'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildTimeSelector(String label, String time, VoidCallback onTap) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        InkWell(
          onTap: onTap,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.lightGrey),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Text(
                  time,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.access_time,
                  size: 18,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _applyToAllDays() {
    setState(() {
      final mondayHours = _workingHours['Pazartesi']!;
      if (mondayHours[0] != 'Kapalı') {
        for (String day in ['Salı', 'Çarşamba', 'Perşembe', 'Cuma']) {
          _workingHours[day] = [mondayHours[0], mondayHours[1]];
        }
      }
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Pazartesi saatleri hafta içi günlere uygulandı'),
        backgroundColor: AppColors.info,
      ),
    );
  }
} 