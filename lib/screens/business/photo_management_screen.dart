import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import '../../constants/app_colors.dart';
import '../../models/salon_model.dart';
import '../../services/photo_service.dart';
import '../../services/salon_service.dart';
import '../../services/auth_service.dart';

class PhotoManagementScreen extends StatefulWidget {
  const PhotoManagementScreen({super.key});

  @override
  State<PhotoManagementScreen> createState() => _PhotoManagementScreenState();
}

class _PhotoManagementScreenState extends State<PhotoManagementScreen> {
  final PhotoService _photoService = PhotoService();
  final SalonService _salonService = SalonService();
  final AuthService _authService = AuthService();
  
  SalonModel? _salon;
  bool _isLoading = true;
  bool _isUploading = false;

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
        setState(() {
          _salon = salon;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _addPhotos() async {
    if (_salon == null) return;

    try {
      final List<XFile> images = await _photoService.pickMultipleImages();
      if (images.isEmpty) return;

      setState(() {
        _isUploading = true;
      });

      final List<String> uploadedUrls = await _photoService.uploadSalonImages(
        imageFiles: images,
        salonId: _salon!.id,
      );

      if (uploadedUrls.isNotEmpty) {
        final updatedImages = [..._salon!.images, ...uploadedUrls];
        final updatedSalon = SalonModel(
          id: _salon!.id,
          name: _salon!.name,
          description: _salon!.description,
          category: _salon!.category,
          ownerId: _salon!.ownerId,
          address: _salon!.address,
          latitude: _salon!.latitude,
          longitude: _salon!.longitude,
          phoneNumber: _salon!.phoneNumber,
          email: _salon!.email,
          services: _salon!.services,
          workingHours: _salon!.workingHours,
          images: updatedImages,
          imageUrl: _salon!.imageUrl,
          rating: _salon!.rating,
          reviewCount: _salon!.reviewCount,
          isActive: _salon!.isActive,
          createdAt: _salon!.createdAt,
        );

        await _salonService.updateSalon(updatedSalon);
        
        setState(() {
          _salon = updatedSalon;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${uploadedUrls.length} fotoğraf başarıyla eklendi!'),
              backgroundColor: AppColors.success,
            ),
          );
        }
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
        _isUploading = false;
      });
    }
  }

  Future<void> _deletePhoto(String imageUrl, int index) async {
    if (_salon == null) return;

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Fotoğrafı Sil'),
        content: const Text('Bu fotoğrafı silmek istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Sil'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      setState(() {
        _isUploading = true;
      });

      final bool deleted = await _photoService.deleteImage(imageUrl);
      
      if (deleted) {
        final updatedImages = List<String>.from(_salon!.images);
        updatedImages.removeAt(index);
        
        final updatedSalon = SalonModel(
          id: _salon!.id,
          name: _salon!.name,
          description: _salon!.description,
          category: _salon!.category,
          ownerId: _salon!.ownerId,
          address: _salon!.address,
          latitude: _salon!.latitude,
          longitude: _salon!.longitude,
          phoneNumber: _salon!.phoneNumber,
          email: _salon!.email,
          services: _salon!.services,
          workingHours: _salon!.workingHours,
          images: updatedImages,
          imageUrl: _salon!.imageUrl,
          rating: _salon!.rating,
          reviewCount: _salon!.reviewCount,
          isActive: _salon!.isActive,
          createdAt: _salon!.createdAt,
        );

        await _salonService.updateSalon(updatedSalon);
        
        setState(() {
          _salon = updatedSalon;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Fotoğraf başarıyla silindi!'),
              backgroundColor: AppColors.success,
            ),
          );
        }
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
        _isUploading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_salon == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Fotoğraf Yönetimi'),
        ),
        body: const Center(
          child: Text('Salon bilgileri bulunamadı'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fotoğraf Yönetimi'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          if (!_isUploading)
            IconButton(
              onPressed: _addPhotos,
              icon: const Icon(Icons.add_a_photo),
              tooltip: 'Fotoğraf Ekle',
            ),
        ],
      ),
      body: _isUploading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Fotoğraflar yükleniyor...'),
                ],
              ),
            )
          : _salon!.images.isEmpty
              ? _buildEmptyState()
              : _buildPhotoGrid(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_a_photo,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 24),
            Text(
              'Henüz fotoğraf eklenmemiş',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'İşletmenizin fotoğraflarını ekleyerek müşterilerinizin dikkatini çekin',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[500],
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _addPhotos,
              icon: const Icon(Icons.add_a_photo),
              label: const Text('İlk Fotoğrafı Ekle'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoGrid() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Fotoğraflar (${_salon!.images.length})',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton.icon(
                onPressed: _addPhotos,
                icon: const Icon(Icons.add),
                label: const Text('Ekle'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1,
              ),
              itemCount: _salon!.images.length,
              itemBuilder: (context, index) {
                return _buildPhotoCard(_salon!.images[index], index);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoCard(String imageUrl, int index) {
    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          CachedNetworkImage(
            imageUrl: imageUrl,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              color: Colors.grey[200],
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
            errorWidget: (context, url, error) => Container(
              color: Colors.grey[200],
              child: const Icon(
                Icons.error,
                color: Colors.grey,
              ),
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: GestureDetector(
              onTap: () => _deletePhoto(imageUrl, index),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.delete,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${index + 1}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
} 