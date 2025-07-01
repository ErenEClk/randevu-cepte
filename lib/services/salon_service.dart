import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/salon_model.dart';
import '../models/service_model.dart';
import 'dart:math';

class SalonService {
  // Firebase Firestore instance
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Mock salon verileri (geliştirme için)
  List<SalonModel> _salons = [];

  SalonService() {
    _initMockData();
  }

  void _initMockData() {
    _salons = [
      SalonModel(
        id: "1",
        name: "Güzellik Merkezi Ayşe",
        description: "Profesyonel kuaför hizmetleri ve güzellik bakımı. 15 yıllık deneyimimizle sizlere en kaliteli hizmeti sunuyoruz.",
        category: "Kuaför",
        address: "Kadıköy Moda Caddesi No:123, İstanbul",
        latitude: 40.9990,
        longitude: 29.0309,
        phoneNumber: "+90212123456",
        rating: 4.8,
        reviewCount: 156,
        imageUrl: "https://example.com/salon1.jpg",
        images: [
          "https://example.com/salon1.jpg",
          "https://example.com/salon1_2.jpg",
        ],
        workingHours: {
          'Pazartesi': ['09:00', '18:00'],
          'Salı': ['09:00', '18:00'],
          'Çarşamba': ['09:00', '18:00'],
          'Perşembe': ['09:00', '18:00'],
          'Cuma': ['09:00', '18:00'],
          'Cumartesi': ['10:00', '17:00'],
          'Pazar': ['Kapalı', 'Kapalı'],
        },
        services: [
          ServiceModel(
            id: "s1",
            salonId: "1",
            name: "Kadın Saç Kesimi",
            description: "Profesyonel kadın saç kesimi ve şekillendirme",
            price: 150,
            durationMinutes: 60,
            category: ServiceCategory.haircut,
            isActive: true,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          ServiceModel(
            id: "s2",
            salonId: "1",
            name: "Saç Boyama",
            description: "Doğal saç boyama ve renklendirme",
            price: 300,
            durationMinutes: 120,
            category: ServiceCategory.coloring,
            isActive: true,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          ServiceModel(
            id: "s3",
            salonId: "1",
            name: "Keratin Bakım",
            description: "Saç bakım ve onarım tedavisi",
            price: 250,
            durationMinutes: 90,
            category: ServiceCategory.treatment,
            isActive: true,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          ServiceModel(
            id: "s4",
            salonId: "1",
            name: "Fön Çekimi",
            description: "Profesyonel fön ve şekillendirme",
            price: 80,
            durationMinutes: 45,
            category: ServiceCategory.haircut,
            isActive: true,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ],
        ownerId: "2",
        createdAt: DateTime.now().subtract(Duration(days: 30)),
      ),
      SalonModel(
        id: "2",
        name: "Modern Berber Salih",
        description: "Erkek kuaförü ve tıraş hizmetleri. Geleneksel ustura tıraşı ve modern saç kesimleri.",
        category: "Berber",
        address: "Beşiktaş Barbaros Bulvarı No:45, İstanbul",
        latitude: 41.0422,
        longitude: 29.0098,
        phoneNumber: "+90212987654",
        rating: 4.5,
        reviewCount: 89,
        imageUrl: "https://example.com/salon2.jpg",
        images: [
          "https://example.com/salon2.jpg",
        ],
        workingHours: {
          'Pazartesi': ['08:00', '20:00'],
          'Salı': ['08:00', '20:00'],
          'Çarşamba': ['08:00', '20:00'],
          'Perşembe': ['08:00', '20:00'],
          'Cuma': ['08:00', '20:00'],
          'Cumartesi': ['09:00', '18:00'],
          'Pazar': ['Kapalı', 'Kapalı'],
        },
        services: [
          ServiceModel(
            id: "s5",
            salonId: "2",
            name: "Erkek Saç Kesimi",
            description: "Klasik ve modern erkek saç kesimleri",
            price: 80,
            durationMinutes: 30,
            category: ServiceCategory.haircut,
            isActive: true,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          ServiceModel(
            id: "s6",
            salonId: "2",
            name: "Sakal Tıraş",
            description: "Geleneksel ustura tıraşı",
            price: 50,
            durationMinutes: 20,
            category: ServiceCategory.shaving,
            isActive: true,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          ServiceModel(
            id: "s7",
            salonId: "2",
            name: "Saç + Sakal Kombo",
            description: "Saç kesimi ve sakal tıraş paketi",
            price: 120,
            durationMinutes: 45,
            category: ServiceCategory.haircut,
            isActive: true,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ],
        ownerId: "3",
        createdAt: DateTime.now().subtract(Duration(days: 45)),
      ),
      SalonModel(
        id: "3",
        name: "Lüks Güzellik Salonu Elif",
        description: "Premium güzellik ve bakım hizmetleri. VIP müşteri deneyimi ve lüks ortam.",
        category: "Güzellik Salonu",
        address: "Nişantaşı Abdi İpekçi Caddesi No:67, İstanbul",
        latitude: 41.0460,
        longitude: 28.9943,
        phoneNumber: "+90212555777",
        rating: 4.9,
        reviewCount: 234,
        imageUrl: "https://example.com/salon3.jpg",
        images: [
          "https://example.com/salon3.jpg",
          "https://example.com/salon3_2.jpg",
          "https://example.com/salon3_3.jpg",
        ],
        workingHours: {
          'Pazartesi': ['10:00', '19:00'],
          'Salı': ['10:00', '19:00'],
          'Çarşamba': ['10:00', '19:00'],
          'Perşembe': ['10:00', '19:00'],
          'Cuma': ['10:00', '19:00'],
          'Cumartesi': ['10:00', '18:00'],
          'Pazar': ['11:00', '17:00'],
        },
        services: [
          ServiceModel(
            id: "s8",
            salonId: "3",
            name: "Saç Bakımı & Keratin",
            description: "Keratin bakım ve onarım tedavisi",
            price: 350,
            durationMinutes: 120,
            category: ServiceCategory.treatment,
            isActive: true,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          ServiceModel(
            id: "s9",
            salonId: "3",
            name: "Özel Gün Makyajı",
            description: "Düğün, nişan ve özel günler için profesyonel makyaj",
            price: 300,
            durationMinutes: 60,
            category: ServiceCategory.makeup,
            isActive: true,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          ServiceModel(
            id: "s10",
            salonId: "3",
            name: "Lüks Saç Kesimi",
            description: "VIP saç kesimi ve şekillendirme",
            price: 200,
            durationMinutes: 75,
            category: ServiceCategory.haircut,
            isActive: true,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          ServiceModel(
            id: "s11",
            salonId: "3",
            name: "Cilt Bakımı",
            description: "Profesyonel cilt bakım ve temizleme",
            price: 250,
            durationMinutes: 90,
            category: ServiceCategory.skincare,
            isActive: true,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          ServiceModel(
            id: "s12",
            salonId: "3",
            name: "Manikür & Pedikür",
            description: "Nail art ve tırnak bakımı",
            price: 150,
            durationMinutes: 60,
            category: ServiceCategory.nail,
            isActive: true,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ],
        ownerId: "4",
        createdAt: DateTime.now().subtract(Duration(days: 60)),
      ),
    ];
  }

  // Popüler salonları getir - Firebase'den
  Future<List<SalonModel>> getPopularSalons({int limit = 5}) async {
    try {
      // Mock verileri Firebase'e kaydet
      await saveMockSalonsToFirebase();
      
      // Firebase'den popüler salonları getir
      final querySnapshot = await _firestore
          .collection('salons')
          .orderBy('rating', descending: true)
          .limit(limit)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final firebaseSalons = querySnapshot.docs
            .map((doc) => SalonModel.fromFirestore(doc))
            .toList();
        print('🔥 Firebase\'den ${firebaseSalons.length} popüler salon yüklendi');
        return firebaseSalons;
      }
      
      // Firebase boşsa mock verileri kullan
      print('📍 Firebase boş, mock veriler kullanılıyor');
      await Future.delayed(Duration(milliseconds: 300));
      List<SalonModel> sortedSalons = List.from(_salons);
      sortedSalons.sort((a, b) => b.rating.compareTo(a.rating));
      return sortedSalons.take(limit).toList();
    } catch (e) {
      print('❌ Firebase popüler salon hatası: $e');
      // Hata durumunda mock verileri kullan
      await Future.delayed(Duration(milliseconds: 300));
      List<SalonModel> sortedSalons = List.from(_salons);
      sortedSalons.sort((a, b) => b.rating.compareTo(a.rating));
      return sortedSalons.take(limit).toList();
    }
  }

  // Salon ekleme (esnaf için)
  Future<void> addSalon(SalonModel salon) async {
    try {
      await _firestore.collection('salons').doc(salon.id).set(salon.toFirestore());
    } catch (e) {
      throw Exception('Salon eklenemedi: $e');
    }
  }

  // Salon oluştur (yeni method)
  Future<void> createSalon(SalonModel salon) async {
    try {
      await _firestore.collection('salons').doc(salon.id).set(salon.toFirestore());
      print('Salon Firestore\'a kaydedildi: ${salon.name}');
    } catch (e) {
      print('Salon kaydetme hatası: $e');
      throw Exception('Salon kaydedilemedi: $e');
    }
  }

  // Kullanıcının salonunu getir
  Future<SalonModel?> getUserSalon(String userId) async {
    try {
      final doc = await _firestore.collection('salons').doc(userId).get();
      if (doc.exists) {
        return SalonModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Salon getirme hatası: $e');
      return null;
    }
  }

  // Salon güncelle
  Future<void> updateSalon(SalonModel salon) async {
    try {
      await _firestore.collection('salons').doc(salon.id).update(salon.toFirestore());
      print('Salon güncellendi: ${salon.name}');
    } catch (e) {
      print('Salon güncelleme hatası: $e');
      throw Exception('Salon güncellenemedi: $e');
    }
  }

  // Mock verileri Firebase'e kaydet (bir kerelik)
  Future<void> saveMockSalonsToFirebase() async {
    try {
      for (var salon in _salons) {
        final doc = await _firestore.collection('salons').doc(salon.id).get();
        if (!doc.exists) {
          await _firestore.collection('salons').doc(salon.id).set(salon.toFirestore());
          print('✅ Mock salon Firebase\'e kaydedildi: ${salon.name}');
        }
      }
      print('🔥 Tüm mock salonlar Firebase\'e kaydedildi');
    } catch (e) {
      print('❌ Mock salon kaydetme hatası: $e');
    }
  }

  // Tüm salonları getir
  Future<List<SalonModel>> getAllSalons() async {
    try {
      // İlk çalıştırmada mock verileri Firebase'e kaydet
      await saveMockSalonsToFirebase();
      
      // Firebase'den salon verilerini getir
      final querySnapshot = await _firestore.collection('salons').get();
      
      if (querySnapshot.docs.isNotEmpty) {
        final firebaseSalons = querySnapshot.docs
            .map((doc) => SalonModel.fromFirestore(doc))
            .toList();
        print('🔥 Firebase\'den ${firebaseSalons.length} salon yüklendi');
        return firebaseSalons;
      }

      // Firebase boşsa mock verileri döndür
      print('📍 Firebase boş, mock veriler kullanılıyor');
      await Future.delayed(Duration(milliseconds: 200));
      return _salons;
    } catch (e) {
      print('❌ Firebase salon hatası: $e');
      // Hata durumunda mock verileri kullan
      await Future.delayed(Duration(milliseconds: 200));
      return _salons;
    }
  }

  // ID ile salon getir
  Future<SalonModel?> getSalonById(String salonId) async {
    try {
      // Mock verileri Firebase'e kaydet
      await saveMockSalonsToFirebase();
      
      // Firebase'den salon getir
      final doc = await _firestore.collection('salons').doc(salonId).get();
      
      if (doc.exists) {
        final salon = SalonModel.fromFirestore(doc);
        
        // Salonun hizmetlerini Firebase'den çek
        final services = await getSalonServices(salonId);
        
        // Salon'u hizmetleriyle birlikte döndür
        final salonWithServices = salon.copyWith(services: services);
        print('🔥 Firebase\'den salon bulundu: ${salon.name} (${services.length} hizmet)');
        return salonWithServices;
      }

      // Firebase'de bulunamadıysa mock verilerden ara
      try {
        final mockSalon = _salons.firstWhere((salon) => salon.id == salonId);
        print('📍 Mock verilerden salon bulundu: ${mockSalon.name}');
        return mockSalon;
      } catch (e) {
        print('❌ Salon bulunamadı: $salonId');
        return null;
      }
    } catch (e) {
      print('❌ Firebase salon getirme hatası: $e');
      // Hata durumunda mock verilerden dene
      try {
        final mockSalon = _salons.firstWhere((salon) => salon.id == salonId);
        return mockSalon;
      } catch (e) {
        return null;
      }
    }
  }

  // Konum bazında salonları getir
  Future<List<SalonModel>> getNearestSalons({
    required double latitude,
    required double longitude,
    double radiusKm = 5.0,
    int limit = 10,
  }) async {
    try {
      // Firebase Geolocation query (daha kompleks olacak, şimdilik basit versiyonu)
      final querySnapshot = await _firestore
          .collection('salons')
          .limit(limit)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        List<SalonModel> salons = querySnapshot.docs
            .map((doc) => SalonModel.fromFirestore(doc))
            .toList();
        
        // Mesafeye göre filtrele ve sırala
        salons = salons.where((salon) {
          double distance = salon.calculateDistance(latitude, longitude);
          return distance <= radiusKm;
        }).toList();

        salons.sort((a, b) {
          double distanceA = a.calculateDistance(latitude, longitude);
          double distanceB = b.calculateDistance(latitude, longitude);
          return distanceA.compareTo(distanceB);
        });

        return salons;
      }

      // Mock verilerle çalış
      List<SalonModel> nearestSalons = _salons.where((salon) {
        double distance = salon.calculateDistance(latitude, longitude);
        return distance <= radiusKm;
      }).toList();

      nearestSalons.sort((a, b) {
        double distanceA = a.calculateDistance(latitude, longitude);
        double distanceB = b.calculateDistance(latitude, longitude);
        return distanceA.compareTo(distanceB);
      });

      return nearestSalons.take(limit).toList();
    } catch (e) {
      print('En yakın salonlar bulunamadı: $e');
      return [];
    }
  }

  // Hizmet yönetimi methodları
  
  // Salon hizmetlerini getir
  Future<List<ServiceModel>> getSalonServices(String salonId) async {
    try {
      print('🔍 getSalonServices başlatıldı: salonId=$salonId');
      
      // Basit query (index gerekmez)
      final querySnapshot = await _firestore
          .collection('services')
          .where('salonId', isEqualTo: salonId)
          .where('isActive', isEqualTo: true)
          .get();

      print('📊 Firebase query sonucu: ${querySnapshot.docs.length} dokuman');

      final services = querySnapshot.docs
          .map((doc) {
            print('📄 Service doc: ${doc.id} -> ${doc.data()}');
            return ServiceModel.fromFirestore(doc);
          })
          .toList();

      // Client-side sorting (orderBy yerine)
      services.sort((a, b) => a.createdAt.compareTo(b.createdAt));
          
      print('🔥 Firebase\'den ${services.length} hizmet yüklendi (salon: $salonId)');
      print('📋 Hizmet listesi: ${services.map((s) => '${s.name}(${s.id})').join(', ')}');
      return services;
    } catch (e) {
      print('❌ Firebase hizmet getirme hatası: $e');
      print('❌ Stack trace: ${StackTrace.current}');
      return [];
    }
  }

  // Hizmet ekle
  Future<void> addService(ServiceModel service) async {
    try {
      print('🚀 addService başlatıldı: ${service.name}');
      print('📄 Service data: ID=${service.id}, SalonID=${service.salonId}, Name=${service.name}');
      
      final docRef = _firestore.collection('services').doc();
      print('📄 Firebase doc reference oluşturuldu: ${docRef.id}');
      
      final serviceWithId = service.copyWith(id: docRef.id);
      print('📄 Service with new ID: ${serviceWithId.id}');
      
      final firestoreData = serviceWithId.toFirestore();
      print('📄 Firestore data: $firestoreData');
      
      await docRef.set(firestoreData);
      print('✅ Hizmet Firebase\'e eklendi: ${service.name} (ID: ${docRef.id})');
    } catch (e) {
      print('❌ Hizmet ekleme hatası: $e');
      print('❌ Stack trace: ${StackTrace.current}');
      throw Exception('Hizmet eklenemedi: $e');
    }
  }

  // Hizmet güncelle
  Future<void> updateService(ServiceModel service) async {
    try {
      await _firestore
          .collection('services')
          .doc(service.id)
          .update(service.toFirestore());
      print('✅ Hizmet güncellendi: ${service.name}');
    } catch (e) {
      print('❌ Hizmet güncelleme hatası: $e');
      throw Exception('Hizmet güncellenemedi: $e');
    }
  }

  // Hizmet sil
  Future<void> deleteService(String serviceId) async {
    try {
      await _firestore
          .collection('services')
          .doc(serviceId)
          .update({'isActive': false, 'updatedAt': Timestamp.fromDate(DateTime.now())});
      print('✅ Hizmet silindi: $serviceId');
    } catch (e) {
      print('❌ Hizmet silme hatası: $e');
      throw Exception('Hizmet silinemedi: $e');
    }
  }

  // Salon oluştururken varsayılan hizmetler ekle
  Future<void> addDefaultServices(String salonId) async {
    try {
      final defaultServices = [
        ServiceModel(
          id: '',
          salonId: salonId,
          name: 'Saç Kesimi',
          description: 'Profesyonel saç kesimi ve şekillendirme',
          price: 100.0,
          durationMinutes: 45,
          category: ServiceCategory.haircut,
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        ServiceModel(
          id: '',
          salonId: salonId,
          name: 'Fön Çekimi',
          description: 'Profesyonel fön ve şekillendirme',
          price: 60.0,
          durationMinutes: 30,
          category: ServiceCategory.treatment,
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      for (var service in defaultServices) {
        await addService(service);
      }
      
      print('✅ Varsayılan hizmetler eklendi (salon: $salonId)');
    } catch (e) {
      print('❌ Varsayılan hizmet ekleme hatası: $e');
    }
  }
} 