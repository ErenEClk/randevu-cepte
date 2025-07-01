import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:firebase_auth/firebase_auth.dart';

class PhotoService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  // Galeri veya kameradan fotoğraf seçme
  Future<XFile?> pickImage({required ImageSource source}) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 80,
      );
      return image;
    } catch (e) {
      print('Fotoğraf seçme hatası: $e');
      return null;
    }
  }

  // Birden fazla fotoğraf seçme (galeri)
  Future<List<XFile>> pickMultipleImages() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 80,
      );
      return images;
    } catch (e) {
      print('Çoklu fotoğraf seçme hatası: $e');
      return [];
    }
  }

  // Firebase Storage'a fotoğraf yükleme
  Future<String?> uploadImage({
    required XFile imageFile,
    required String folderPath,
    String? fileName,
  }) async {
    try {
      print('=== PHOTO UPLOAD DEBUG ===');
      print('Fotoğraf yükleme başlıyor: ${imageFile.path}');
      print('Folder path: $folderPath');
      
      // Firebase Auth durumu kontrol et
      final user = FirebaseAuth.instance.currentUser;
      print('Firebase Auth kullanıcısı: ${user?.uid ?? "null"}');
      print('User email: ${user?.email ?? "null"}');
      print('User isAnonymous: ${user?.isAnonymous ?? "null"}');
      
      final File file = File(imageFile.path);
      
      // Dosya var mı kontrol et
      if (!file.existsSync()) {
        print('Hata: Dosya bulunamadı');
        return null;
      }
      
      print('Dosya boyutu: ${file.lengthSync()} bytes');
      
      final String fileExtension = path.extension(imageFile.path);
      final String finalFileName = fileName ?? 
        'image_${DateTime.now().millisecondsSinceEpoch}$fileExtension';
      
      final String fullPath = '$folderPath/$finalFileName';
      print('Storage path: $fullPath');
      
      final Reference ref = _storage.ref().child(fullPath);
      print('Firebase Storage referansı: ${ref.fullPath}');
      print('Storage bucket: ${ref.bucket}');
      
      final UploadTask uploadTask = ref.putFile(
        file,
        SettableMetadata(
          contentType: 'image/${fileExtension.substring(1).isEmpty ? 'jpeg' : fileExtension.substring(1)}',
          customMetadata: {
            'uploaded_at': DateTime.now().toIso8601String(),
            'uploaded_by': user?.uid ?? 'unknown',
          },
        ),
      );

      print('Upload task başlatıldı');
      
      // Upload progress'ini dinle
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        print('Upload progress: ${(snapshot.bytesTransferred / snapshot.totalBytes * 100).round()}%');
      });
      
      final TaskSnapshot snapshot = await uploadTask;
      print('Upload tamamlandı. State: ${snapshot.state}');
      
      final String downloadUrl = await snapshot.ref.getDownloadURL();
      
      print('Download URL alındı: $downloadUrl');
      print('=== UPLOAD SUCCESS ===');
      
      return downloadUrl;
    } catch (e) {
      print('=== UPLOAD ERROR ===');
      print('Fotoğraf yükleme hatası detayı: $e');
      print('Hata türü: ${e.runtimeType}');
      if (e is FirebaseException) {
        print('Firebase Error Code: ${e.code}');
        print('Firebase Error Message: ${e.message}');
        print('Firebase Error Plugin: ${e.plugin}');
      }
      print('====================');
      return null;
    }
  }

  // Birden fazla fotoğraf yükleme
  Future<List<String>> uploadMultipleImages({
    required List<XFile> imageFiles,
    required String folderPath,
  }) async {
    final List<String> downloadUrls = [];
    
    for (int i = 0; i < imageFiles.length; i++) {
      final String? url = await uploadImage(
        imageFile: imageFiles[i],
        folderPath: folderPath,
        fileName: 'image_${i + 1}_${DateTime.now().millisecondsSinceEpoch}',
      );
      
      if (url != null) {
        downloadUrls.add(url);
      }
    }
    
    return downloadUrls;
  }

  // Salon fotoğrafı yükleme
  Future<String?> uploadSalonImage({
    required XFile imageFile,
    required String salonId,
  }) async {
    return await uploadImage(
      imageFile: imageFile,
      folderPath: 'salons/$salonId/images',
    );
  }

  // Salon için birden fazla fotoğraf yükleme
  Future<List<String>> uploadSalonImages({
    required List<XFile> imageFiles,
    required String salonId,
  }) async {
    return await uploadMultipleImages(
      imageFiles: imageFiles,
      folderPath: 'salons/$salonId/images',
    );
  }

  // Profil fotoğrafı yükleme
  Future<String?> uploadProfileImage({
    required XFile imageFile,
    required String userId,
  }) async {
    return await uploadImage(
      imageFile: imageFile,
      folderPath: 'users/$userId',
      fileName: 'profile_image',
    );
  }

  // Firebase Storage'dan fotoğraf silme
  Future<bool> deleteImage(String imageUrl) async {
    try {
      final Reference ref = _storage.refFromURL(imageUrl);
      await ref.delete();
      return true;
    } catch (e) {
      print('Fotoğraf silme hatası: $e');
      return false;
    }
  }

  // Birden fazla fotoğraf silme
  Future<List<bool>> deleteMultipleImages(List<String> imageUrls) async {
    final List<bool> results = [];
    
    for (String url in imageUrls) {
      final bool result = await deleteImage(url);
      results.add(result);
    }
    
    return results;
  }

  // Fotoğraf seçme modalı gösterme
  Future<XFile?> showImagePickerModal({
    required context,
    bool allowMultiple = false,
  }) async {
    return showModalBottomSheet<XFile?>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 20),
              Container(
                width: 50,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Fotoğraf Seç',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildOptionButton(
                    context: context,
                    icon: Icons.camera_alt,
                    label: 'Kamera',
                    onTap: () async {
                      Navigator.pop(context);
                      final image = await pickImage(source: ImageSource.camera);
                      Navigator.pop(context, image);
                    },
                  ),
                  _buildOptionButton(
                    context: context,
                    icon: Icons.photo_library,
                    label: 'Galeri',
                    onTap: () async {
                      Navigator.pop(context);
                      final image = await pickImage(source: ImageSource.gallery);
                      Navigator.pop(context, image);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 30),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOptionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Icon(
              icon,
              size: 30,
              color: Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
} 