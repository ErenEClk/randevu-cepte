import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../constants/app_colors.dart';
import '../../models/salon_model.dart';
import '../../services/auth_service.dart';
import '../../services/salon_service.dart';
import '../../services/location_service.dart';
import '../home/business_home_screen.dart';

class BusinessProfileSetupScreen extends StatefulWidget {
  const BusinessProfileSetupScreen({super.key});

  @override
  State<BusinessProfileSetupScreen> createState() => _BusinessProfileSetupScreenState();
}

class _BusinessProfileSetupScreenState extends State<BusinessProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final AuthService _authService = AuthService();
  final SalonService _salonService = SalonService();
  final LocationService _locationService = LocationService();
  
  bool _isLoading = false;
  String _selectedCategory = 'Kuaför';
  Position? _currentPosition;
  
  final List<String> _categories = [
    'Kuaför',
    'Güzellik Salonu',
    'Berber',
    'Nail Art',
    'Masaj',
    'Spa',
    'Estetik',
  ];

  final Map<String, List<String>> _workingHours = {
    'Pazartesi': ['09:00', '18:00'],
    'Salı': ['09:00', '18:00'],
    'Çarşamba': ['09:00', '18:00'],
    'Perşembe': ['09:00', '18:00'],
    'Cuma': ['09:00', '18:00'],
    'Cumartesi': ['09:00', '17:00'],
    'Pazar': ['Kapalı', 'Kapalı'],
  };

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      _currentPosition = await _locationService.getCurrentLocation();
      
      if (_currentPosition != null) {
        // Otomatik adres alma
        await _getAddressFromLocation();
      }
      
      setState(() {});
    } catch (e) {
      print('Konum alınamadı: $e');
    }
  }

  Future<void> _getAddressFromLocation() async {
    if (_currentPosition == null) return;
    
    try {
      String? address = await _locationService.getAddressFromCoordinates(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
      );
      
      if (address != null && _addressController.text.isEmpty) {
        _addressController.text = address;
      }
    } catch (e) {
      print('Adres alınamadı: $e');
    }
  }

  Future<void> _saveBusinessProfile() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Konum bilgisi alınamadı. Lütfen konum izni verin.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final user = _authService.currentUser;
      if (user == null) throw Exception('Kullanıcı bulunamadı');

      final salon = SalonModel(
        id: user.id,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _selectedCategory,
        address: _addressController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
        services: [], // Başlangıçta boş, daha sonra eklenebilir
        workingHours: _workingHours,
        rating: 0.0,
        reviewCount: 0,
        isActive: true,
        ownerId: user.id,
        createdAt: DateTime.now(),
        images: [], // Başlangıçta boş, daha sonra eklenebilir
      );

      await _salonService.createSalon(salon);
      
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('İşletme profili başarıyla oluşturuldu!'),
          backgroundColor: AppColors.success,
        ),
      );

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const BusinessHomeScreen()),
      );
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Hata: ${e.toString()}'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildWorkingHoursCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Çalışma Saatleri',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            ..._workingHours.entries.map((entry) {
                                return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            SizedBox(
                              width: 80,
                              child: Text(
                                entry.key,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textPrimary,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Row(
                                children: [
                                  Expanded(
                                    child: _buildTimeSelector(
                                      entry.key,
                                      0,
                                      entry.value[0],
                                    ),
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 4),
                                    child: Text('-', style: TextStyle(fontSize: 12)),
                                  ),
                                  Expanded(
                                    child: _buildTimeSelector(
                                      entry.key,
                                      1,
                                      entry.value[1],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeSelector(String day, int index, String currentTime) {
    return InkWell(
      onTap: () async {
        if (currentTime == 'Kapalı') {
          setState(() {
            _workingHours[day]![index] = '09:00';
            if (index == 0 && _workingHours[day]![1] == 'Kapalı') {
              _workingHours[day]![1] = '18:00';
            }
          });
          return;
        }

        final TimeOfDay? picked = await showTimePicker(
          context: context,
          initialTime: TimeOfDay(
            hour: int.parse(currentTime.split(':')[0]),
            minute: int.parse(currentTime.split(':')[1]),
          ),
        );

        if (picked != null) {
          setState(() {
            _workingHours[day]![index] = 
                '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          currentTime,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            color: currentTime == 'Kapalı' ? AppColors.textSecondary : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('İşletme Profili Oluştur'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Başlık
              const Text(
                'İşletmenizi Tanıtalım',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Müşterilerinizin sizi bulabilmesi için işletme bilgilerinizi doldurun',
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 32),

              // İşletme Adı
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'İşletme Adı',
                  hintText: 'Örn: Güzellik Merkezi',
                  prefixIcon: Icon(Icons.business),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'İşletme adı gerekli';
                  }
                  if (value.trim().length < 2) {
                    return 'İşletme adı en az 2 karakter olmalı';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Kategori Seçimi
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Kategori',
                  prefixIcon: Icon(Icons.category),
                  border: OutlineInputBorder(),
                ),
                items: _categories.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value!;
                  });
                },
              ),

              const SizedBox(height: 16),

              // Açıklama
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Açıklama',
                  hintText: 'İşletmenizi kısaca tanıtın...',
                  prefixIcon: Icon(Icons.description),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Açıklama gerekli';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Adres
              TextFormField(
                controller: _addressController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Adres',
                  hintText: 'Tam adresinizi girin veya GPS konumunu kullanın',
                  prefixIcon: const Icon(Icons.location_on),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.my_location, color: AppColors.primary),
                    onPressed: _getCurrentLocation,
                    tooltip: 'Mevcut konumumu kullan',
                  ),
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Adres gerekli';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Telefon
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Telefon',
                  hintText: '+90 555 123 4567',
                  prefixIcon: Icon(Icons.phone),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Telefon numarası gerekli';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 24),

              // Çalışma Saatleri
              _buildWorkingHoursCard(),

              const SizedBox(height: 16),

              // Konum Bilgisi
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _currentPosition != null ? Icons.my_location : Icons.location_off,
                            color: _currentPosition != null ? AppColors.success : AppColors.error,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _currentPosition != null 
                                ? 'Konum başarıyla alındı'
                                : 'Konum alınamadı',
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                color: _currentPosition != null 
                                  ? AppColors.success 
                                  : AppColors.error,
                              ),
                            ),
                          ),
                          TextButton.icon(
                            icon: const Icon(Icons.refresh, size: 18),
                            label: const Text('Yenile'),
                            onPressed: _getCurrentLocation,
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                      if (_currentPosition != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Koordinatlar: ${_currentPosition!.latitude.toStringAsFixed(6)}, ${_currentPosition!.longitude.toStringAsFixed(6)}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ] else ...[
                        const SizedBox(height: 8),
                        const Text(
                          'İşletmenizin konumunu belirlemek için GPS erişimi gereklidir.',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Kaydet Butonu
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveBusinessProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        )
                      : const Text(
                          'İşletme Profilini Oluştur',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
} 