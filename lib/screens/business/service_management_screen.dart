import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../models/service_model.dart';
import '../../services/salon_service.dart';
import '../../services/auth_service.dart';

class ServiceManagementScreen extends StatefulWidget {
  const ServiceManagementScreen({super.key});

  @override
  State<ServiceManagementScreen> createState() => _ServiceManagementScreenState();
}

class _ServiceManagementScreenState extends State<ServiceManagementScreen> {
  List<ServiceModel> _services = [];
  bool _isLoading = false;
  final SalonService _salonService = SalonService();
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _loadServices();
  }

  Future<void> _loadServices() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final currentUser = _authService.currentUser;
      print('🔍 Service Management - Current User: ${currentUser?.fullName} (ID: ${currentUser?.id})');
      
      if (currentUser != null) {
        print('🔍 Firebase\'den hizmetler yükleniyor... (SalonID: ${currentUser.id})');
        
        // Firebase'den kullanıcının salon hizmetlerini getir
        final services = await _salonService.getSalonServices(currentUser.id);
        print('📋 ${services.length} hizmet bulundu: ${services.map((s) => s.name).join(', ')}');
        
        setState(() {
          _services = services;
        });
        
        // Eğer hiç hizmet yoksa varsayılan hizmetleri ekle
        if (services.isEmpty) {
          print('🆕 Hiç hizmet yok, varsayılan hizmetler ekleniyor...');
          await _salonService.addDefaultServices(currentUser.id);
          // Varsayılan hizmetleri ekledikten sonra tekrar yükle
          final newServices = await _salonService.getSalonServices(currentUser.id);
          print('📋 Varsayılan hizmetler eklendi: ${newServices.length} hizmet');
          setState(() {
            _services = newServices;
          });
        }
      } else {
        print('❌ Current user null!');
      }
    } catch (e) {
      print('❌ Hizmet yükleme hatası: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hizmetler yüklenirken hata: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _addService() {
    _showServiceDialog();
  }

  void _editService(ServiceModel service) {
    _showServiceDialog(service: service);
  }

  Future<void> _deleteService(ServiceModel service) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hizmeti Sil'),
        content: Text('${service.name} hizmetini silmek istediğinizden emin misiniz?'),
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
            child: const Text('Sil'),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      try {
        await _salonService.deleteService(service.id);
        await _loadServices(); // Listeyi yenile
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Hizmet başarıyla silindi'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Hizmet silinirken hata: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  void _showServiceDialog({ServiceModel? service}) {
    final isEdit = service != null;
    final nameController = TextEditingController(text: service?.name ?? '');
    final descriptionController = TextEditingController(text: service?.description ?? '');
    final priceController = TextEditingController(text: service?.price.toString() ?? '');
    ServiceCategory selectedCategory = service != null 
        ? ServiceCategory.values.firstWhere(
            (cat) => cat.toString().split('.').last == service.category.toString().split('.').last,
            orElse: () => ServiceCategory.haircut,
          )
        : ServiceCategory.haircut;
    int durationMinutes = service?.durationMinutes ?? 30;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isEdit ? 'Hizmeti Düzenle' : 'Yeni Hizmet Ekle'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Hizmet Adı',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Açıklama',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: priceController,
                  decoration: const InputDecoration(
                    labelText: 'Fiyat (₺)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<ServiceCategory>(
                  value: selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Kategori',
                    border: OutlineInputBorder(),
                  ),
                  items: ServiceCategory.values.map((category) => 
                    DropdownMenuItem(
                      value: category,
                                             child: Row(
                         children: [
                           Text(_getCategoryEmoji(category)),
                           const SizedBox(width: 8),
                           Text(_getCategoryName(category)),
                         ],
                       ),
                    ),
                  ).toList(),
                  onChanged: (value) {
                    setDialogState(() {
                      selectedCategory = value!;
                    });
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text('Süre: '),
                    Expanded(
                      child: Slider(
                        value: durationMinutes.toDouble(),
                        min: 15,
                        max: 180,
                        divisions: 11,
                        label: '${durationMinutes} dk',
                        onChanged: (value) {
                          setDialogState(() {
                            durationMinutes = value.round();
                          });
                        },
                      ),
                    ),
                    Text('${durationMinutes} dk'),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isEmpty || priceController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Lütfen tüm alanları doldurun'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                  return;
                }

                try {
                  final currentUser = _authService.currentUser;
                  if (currentUser == null) {
                    throw Exception('Kullanıcı girişi yapılmamış');
                  }

                  final newService = ServiceModel(
                    id: service?.id ?? '', // Firebase'de otomatik ID atanacak
                    salonId: currentUser.id, // Kullanıcının ID'si salon ID'si olur
                    name: nameController.text,
                    description: descriptionController.text,
                    price: double.tryParse(priceController.text) ?? 0,
                    durationMinutes: durationMinutes,
                    category: selectedCategory,
                    isActive: true,
                    createdAt: service?.createdAt ?? DateTime.now(),
                    updatedAt: DateTime.now(),
                  );

                  print('🔍 Hizmet ekleniyor: ${newService.name} (SalonID: ${newService.salonId})');

                  if (isEdit) {
                    print('✏️ Hizmet güncelleniyor: ${newService.id}');
                    await _salonService.updateService(newService);
                  } else {
                    print('➕ Yeni hizmet ekleniyor...');
                    await _salonService.addService(newService);
                  }

                  Navigator.of(context).pop();
                  await _loadServices(); // Listeyi yenile
                  
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(isEdit ? 'Hizmet başarıyla güncellendi' : 'Hizmet başarıyla eklendi'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Hata: $e'),
                        backgroundColor: AppColors.error,
                      ),
                    );
                  }
                }
              },
              child: Text(isEdit ? 'Güncelle' : 'Ekle'),
            ),
          ],
        ),
      ),
    );
  }

  String _getCategoryName(ServiceCategory category) {
    switch (category) {
      case ServiceCategory.haircut:
        return 'Saç Kesimi';
      case ServiceCategory.coloring:
        return 'Saç Boyama';
      case ServiceCategory.treatment:
        return 'Bakım';
      case ServiceCategory.makeup:
        return 'Makyaj';
      case ServiceCategory.shaving:
        return 'Sakal';
      case ServiceCategory.nail:
        return 'Tırnak';
      case ServiceCategory.skincare:
        return 'Cilt Bakımı';
      case ServiceCategory.massage:
        return 'Masaj';
    }
  }

  String _getCategoryEmoji(ServiceCategory category) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hizmet Yönetimi'),
        actions: [
          IconButton(
            onPressed: _addService,
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _services.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.content_cut,
                        size: 64,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Henüz hizmet eklenmemiş',
                        style: TextStyle(
                          fontSize: 18,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Hizmet eklemek için + butonuna dokunun',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _services.length,
                  itemBuilder: (context, index) {
                    final service = _services[index];
                    return _buildServiceCard(service);
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addService,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildServiceCard(ServiceModel service) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    service.emoji,
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        service.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        _getCategoryName(service.category),
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'edit':
                        _editService(service);
                        break;
                      case 'delete':
                        _deleteService(service);
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 18),
                          SizedBox(width: 8),
                          Text('Düzenle'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 18, color: AppColors.error),
                          SizedBox(width: 8),
                          Text('Sil', style: TextStyle(color: AppColors.error)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (service.description.isNotEmpty) ...[
              Text(
                service.description,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
            ],
            Row(
              children: [
                Icon(
                  Icons.attach_money,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 4),
                Text(
                  '${service.price}₺',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(width: 16),
                Icon(
                  Icons.schedule,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 4),
                Text(
                  service.durationText,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
} 