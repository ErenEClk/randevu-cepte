import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  // Konum izni kontrolü ve talebi
  Future<bool> requestLocationPermission() async {
    try {
      // Konum servisleri etkin mi?
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Konum servisleri etkin değil');
      }

      // İzin durumunu kontrol et
      LocationPermission permission = await Geolocator.checkPermission();
      
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Konum izni reddedildi');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Konum izni kalıcı olarak reddedildi. Ayarlardan izin verin.');
      }

      return permission == LocationPermission.always || 
             permission == LocationPermission.whileInUse;
    } catch (e) {
      print('Konum izni hatası: $e');
      return false;
    }
  }

  // Geçerli konumu al
  Future<Position?> getCurrentLocation() async {
    try {
      bool hasPermission = await requestLocationPermission();
      if (!hasPermission) {
        throw Exception('Konum izni verilmedi');
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      return position;
    } catch (e) {
      print('Konum alma hatası: $e');
      return null;
    }
  }

  // Koordinatları adrese çevir (Reverse Geocoding)
  Future<String?> getAddressFromCoordinates(double latitude, double longitude) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(latitude, longitude);
      
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        
        // Adres formatını oluştur
        List<String> addressParts = [];
        
        if (place.street?.isNotEmpty == true) {
          addressParts.add(place.street!);
        }
        
        if (place.subLocality?.isNotEmpty == true) {
          addressParts.add(place.subLocality!);
        }
        
        if (place.locality?.isNotEmpty == true) {
          addressParts.add(place.locality!);
        }
        
        if (place.administrativeArea?.isNotEmpty == true) {
          addressParts.add(place.administrativeArea!);
        }
        
        if (place.country?.isNotEmpty == true) {
          addressParts.add(place.country!);
        }

        return addressParts.join(', ');
      }
      
      return null;
    } catch (e) {
      print('Adres çevirme hatası: $e');
      return null;
    }
  }

  // Detaylı adres bilgisi al
  Future<Map<String, String>?> getDetailedAddressFromCoordinates(
    double latitude, 
    double longitude
  ) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(latitude, longitude);
      
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        
        return {
          'street': place.street ?? '',
          'subLocality': place.subLocality ?? '',
          'locality': place.locality ?? '',
          'administrativeArea': place.administrativeArea ?? '',
          'country': place.country ?? '',
          'postalCode': place.postalCode ?? '',
          'thoroughfare': place.thoroughfare ?? '',
          'subThoroughfare': place.subThoroughfare ?? '',
        };
      }
      
      return null;
    } catch (e) {
      print('Detaylı adres alma hatası: $e');
      return null;
    }
  }

  // İki nokta arasındaki mesafeyi hesapla
  double calculateDistance(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) {
    return Geolocator.distanceBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    ) / 1000; // Kilometre cinsinden
  }

  // Konum izni durumunu kontrol et
  Future<bool> hasLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    return permission == LocationPermission.always || 
           permission == LocationPermission.whileInUse;
  }

  // Uygulama ayarlarını aç
  Future<void> openAppSettings() async {
    await Geolocator.openAppSettings();
  }

  // Konum servisleri ayarlarını aç
  Future<void> openLocationSettings() async {
    await Geolocator.openLocationSettings();
  }
} 