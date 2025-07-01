import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../models/salon_model.dart';
import '../screens/salon/salon_detail_screen.dart';

class SalonCard extends StatelessWidget {
  final SalonModel salon;
  final double? userLatitude;
  final double? userLongitude;
  final bool showDistance;
  final VoidCallback? onTap;

  const SalonCard({
    super.key,
    required this.salon,
    this.userLatitude,
    this.userLongitude,
    this.showDistance = false,
    this.onTap,
  });

  String _formatDistance(double distance) {
    if (distance < 1) {
      return '${(distance * 1000).round()} m';
    } else {
      return '${distance.toStringAsFixed(1)} km';
    }
  }

  Widget _buildRatingStars(double rating) {
    List<Widget> stars = [];
    int fullStars = rating.floor();
    bool hasHalfStar = (rating - fullStars) >= 0.5;

    // Dolu yıldızlar
    for (int i = 0; i < fullStars; i++) {
      stars.add(const Icon(
        Icons.star,
        color: Colors.amber,
        size: 16,
      ));
    }

    // Yarım yıldız
    if (hasHalfStar) {
      stars.add(const Icon(
        Icons.star_half,
        color: Colors.amber,
        size: 16,
      ));
    }

    // Boş yıldızlar
    int remainingStars = 5 - fullStars - (hasHalfStar ? 1 : 0);
    for (int i = 0; i < remainingStars; i++) {
      stars.add(const Icon(
        Icons.star_border,
        color: Colors.grey,
        size: 16,
      ));
    }

    return Row(children: stars);
  }

  String _getCurrentStatus() {
    final now = DateTime.now();
    final weekday = [
      'Pazar', 'Pazartesi', 'Salı', 'Çarşamba', 
      'Perşembe', 'Cuma', 'Cumartesi'
    ][now.weekday % 7];

    final todayHours = salon.workingHours[weekday];
    if (todayHours == null || todayHours.length != 2) return 'Kapalı';

    final openTime = todayHours[0];
    final closeTime = todayHours[1];

    if (openTime == 'Kapalı' || closeTime == 'Kapalı') {
      return 'Kapalı';
    }

    try {
      final openHour = int.parse(openTime.split(':')[0]);
      final openMinute = int.parse(openTime.split(':')[1]);
      final closeHour = int.parse(closeTime.split(':')[0]);
      final closeMinute = int.parse(closeTime.split(':')[1]);

      final openDateTime = DateTime(now.year, now.month, now.day, openHour, openMinute);
      final closeDateTime = DateTime(now.year, now.month, now.day, closeHour, closeMinute);

      if (now.isAfter(openDateTime) && now.isBefore(closeDateTime)) {
        return 'Açık';
      } else if (now.isBefore(openDateTime)) {
        return '$openTime\'da açılacak';
      } else {
        return 'Kapalı';
      }
    } catch (e) {
      return 'Kapalı';
    }
  }

  @override
  Widget build(BuildContext context) {
    final distance = userLatitude != null && userLongitude != null
        ? salon.calculateDistance(userLatitude!, userLongitude!)
        : null;

    final status = _getCurrentStatus();
    final isOpen = status == 'Açık';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap ?? () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => SalonDetailScreen(salon: salon),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Üst kısım - Salon adı ve durumu
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Salon resmi placeholder
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: salon.images.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              salon.images.first,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(
                                  Icons.business,
                                  color: AppColors.primary,
                                  size: 32,
                                );
                              },
                            ),
                          )
                        : const Icon(
                            Icons.business,
                            color: AppColors.primary,
                            size: 32,
                          ),
                  ),
                  
                  const SizedBox(width: 12),
                  
                  // Salon bilgileri
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Salon adı
                        Text(
                          salon.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        
                        const SizedBox(height: 4),
                        
                        // Kategori
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.secondary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            salon.category,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.secondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 8),
                        
                        // Rating ve mesafe
                        Row(
                          children: [
                            _buildRatingStars(salon.rating),
                            const SizedBox(width: 4),
                            Text(
                              '(${salon.rating.toStringAsFixed(1)})',
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            if (distance != null) ...[
                              const SizedBox(width: 8),
                              const Icon(
                                Icons.location_on,
                                size: 16,
                                color: AppColors.textSecondary,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                _formatDistance(distance),
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  // Durum badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isOpen 
                          ? Colors.green.withOpacity(0.1)
                          : Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isOpen ? Colors.green : Colors.red,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Açıklama
              if (salon.description.isNotEmpty)
                Text(
                  salon.description,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              
              const SizedBox(height: 12),
              
              // Alt kısım - Adres ve randevu butonu
              Row(
                children: [
                  const Icon(
                    Icons.location_on,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      salon.address,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  
                  const SizedBox(width: 8),
                  
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => SalonDetailScreen(salon: salon),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      minimumSize: const Size(0, 32),
                    ),
                    child: const Text(
                      'Detay',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
} 