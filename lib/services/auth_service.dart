import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart';

class AuthService {
  // Singleton pattern
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  // Firebase instances
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  
  // Firebase Auth instance getter
  FirebaseAuth get firebaseAuth => _auth;
  
  // Kullanıcı verisi
  UserModel? _currentUser;

  UserModel? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;

  // Firebase Auth listener
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Uygulama başladığında mevcut kullanıcıyı kontrol et
  Future<void> checkCurrentUser() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        // Firestore'dan kullanıcı bilgilerini al
        final userDoc = await _firestore.collection('users').doc(user.uid).get();
        if (userDoc.exists) {
          _currentUser = UserModel.fromFirestore(userDoc);
        }
      }
    } catch (e) {
      print('Mevcut kullanıcı kontrol edilemedi: $e');
    }
  }

  // Google ile giriş
  Future<UserModel?> signInWithGoogle() async {
    try {
      // Mevcut oturumu temizle
      await _googleSignIn.signOut();
      
      // Google Sign In akışını başlat
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        print('Kullanıcı Google girişini iptal etti');
        return null; // Kullanıcı iptal etti
      }

      print('Google kullanıcısı seçildi: ${googleUser.email}');

      // Google auth bilgilerini al
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      print('Google auth token alındı');

      // Firebase credential oluştur
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      print('Firebase credential oluşturuldu');

      // Firebase'e giriş yap
      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      final User? user = userCredential.user;

      print('Firebase girişi başarılı: ${user?.uid}');

      if (user != null) {
        // Kullanıcı daha önce kayıt olmuş mu kontrol et
        final userDoc = await _firestore.collection('users').doc(user.uid).get();
        
        if (userDoc.exists) {
          // Mevcut kullanıcı
          _currentUser = UserModel.fromFirestore(userDoc);
          print('Mevcut kullanıcı bulundu: ${_currentUser?.fullName}');
          return _currentUser;
        } else {
          // Yeni kullanıcı - kullanıcı tipi seçimi için null dönder
          // Bu durumda UserTypeSelectionScreen gösterilecek
          print('Yeni Google kullanıcısı: ${user.displayName} - kullanıcı tipi seçimi gerekli');
          return null;
        }
      }
    } catch (e) {
      print('Google Sign-In hatası: $e');
      // Daha spesifik hata mesajları
      if (e.toString().contains('network_error')) {
        throw Exception("İnternet bağlantınızı kontrol edin");
      } else if (e.toString().contains('sign_in_canceled')) {
        throw Exception("Giriş iptal edildi");
      } else if (e.toString().contains('sign_in_failed')) {
        throw Exception("Google ile giriş başarısız oldu");
      } else {
        throw Exception("Google ile giriş yapılamadı: ${e.toString()}");
      }
    }
    return null;
  }

  // Firebase ile giriş
  Future<UserModel?> login(String email, String password) async {
    try {
      // Test kullanıcıları için Firebase Anonymous Auth kullan
      if (email == "musteri@test.com" && password == "123456") {
        print('=== ANONYMOUS AUTH TEST ===');
        final UserCredential userCredential = await _auth.signInAnonymously();
        print('Anonymous user ID: ${userCredential.user?.uid}');
        
        _currentUser = UserModel(
          id: userCredential.user?.uid ?? "anonymous_customer",
          email: email,
          fullName: "Test Müşteri",
          phoneNumber: "+90555123456",
          userType: UserType.customer,
          createdAt: DateTime.now(),
        );
        return _currentUser;
      }
      
      if (email == "kuafor@test.com" && password == "123456") {
        print('=== ANONYMOUS AUTH TEST FOR BUSINESS ===');
        final UserCredential userCredential = await _auth.signInAnonymously();
        print('Anonymous business user ID: ${userCredential.user?.uid}');
        
        _currentUser = UserModel(
          id: userCredential.user?.uid ?? "anonymous_business",
          email: email,
          fullName: "Test Kuaför",
          phoneNumber: "+90555654321",
          userType: UserType.business,
          createdAt: DateTime.now(),
        );
        
        // Mock kuaför için salon profili oluştur
        await _createMockSalonProfile();
        
        return _currentUser;
      }

      // Firebase Authentication ile giriş yap
      final UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Firestore'dan kullanıcı bilgilerini al
      final userDoc = await _firestore.collection('users').doc(userCredential.user!.uid).get();
      
      if (userDoc.exists) {
        _currentUser = UserModel.fromFirestore(userDoc);
        return _currentUser;
      } else {
        throw Exception("Kullanıcı bilgileri bulunamadı");
      }
    } catch (e) {
      throw Exception("Giriş yapılamadı: ${e.toString()}");
    }
  }

  // Mock kuaför için salon profili oluştur
  Future<void> _createMockSalonProfile() async {
    try {
      final String userId = _currentUser?.id ?? 'unknown';
      print('Mock salon profili oluşturuluyor. User ID: $userId');
      
      final salonDoc = await _firestore.collection('salons').doc(userId).get();
      
      if (!salonDoc.exists) {
        // Mock salon profili oluştur
        final salonData = {
          'id': userId,
          'name': 'Test Kuaför Salonu',
          'description': 'Test amaçlı kuaför salonu. Burada gerçek hizmetlerinizi tanımlayabilirsiniz.',
          'category': 'Kuaför',
          'address': 'Test Mahallesi, Test Sokak No:1, İstanbul',
          'latitude': 41.0082,
          'longitude': 28.9784,
          'phoneNumber': '+90555654321',
          'rating': 5.0,
          'reviewCount': 1,
          'imageUrl': '',
          'images': [],
          'workingHours': {
            'Pazartesi': ['09:00', '18:00'],
            'Salı': ['09:00', '18:00'],
            'Çarşamba': ['09:00', '18:00'],
            'Perşembe': ['09:00', '18:00'],
            'Cuma': ['09:00', '18:00'],
            'Cumartesi': ['09:00', '17:00'],
            'Pazar': ['Kapalı'],
          },
          'ownerId': userId,
          'createdAt': Timestamp.fromDate(DateTime.now()),
        };
        
        await _firestore.collection('salons').doc(userId).set(salonData);
        print('✅ Mock salon profili oluşturuldu ID: $userId');
      } else {
        print('✅ Mock salon profili zaten mevcut ID: $userId');
      }
    } catch (e) {
      print('❌ Mock salon profili oluşturma hatası: $e');
    }
  }

  // Firebase ile kayıt
  Future<UserModel?> register({
    required String email,
    required String password,
    required String fullName,
    required String phoneNumber,
    required UserType userType,
  }) async {
    try {
      // Firebase Authentication ile hesap oluştur
      final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Kullanıcı modelini oluştur
      final newUser = UserModel(
        id: userCredential.user!.uid,
        email: email,
        fullName: fullName,
        phoneNumber: phoneNumber,
        userType: userType,
        createdAt: DateTime.now(),
      );

      // Firestore'a kullanıcı bilgilerini kaydet
      await _firestore.collection('users').doc(newUser.id).set(newUser.toFirestore());

      _currentUser = newUser;
      return _currentUser;
    } catch (e) {
      throw Exception("Kayıt olunamadı: ${e.toString()}");
    }
  }

  // Google kullanıcısını Firestore'a kaydet
  Future<void> saveGoogleUserToFirestore({
    required String userId,
    required String email,
    required String fullName,
    required UserType userType,
    String? profileImageUrl,
  }) async {
    try {
      final newUser = UserModel(
        id: userId,
        email: email,
        fullName: fullName,
        phoneNumber: '', // Google'dan telefon numarası gelmeyebilir
        userType: userType,
        profileImageUrl: profileImageUrl,
        createdAt: DateTime.now(),
      );

      print('Google kullanıcısı Firestore\'a kaydediliyor: $fullName');

      // Firestore'a kaydet
      await _firestore.collection('users').doc(userId).set(newUser.toFirestore());
      _currentUser = newUser;
      print('Google kullanıcısı başarıyla kaydedildi');
    } catch (e) {
      print('Google kullanıcısı kaydedilirken hata: $e');
      throw Exception('Kullanıcı bilgileri kaydedilemedi: $e');
    }
  }

  // Çıkış yap
  Future<void> logout() async {
    await _auth.signOut();
    await _googleSignIn.signOut();
    _currentUser = null;
  }

  // Çıkış yap (alias)
  Future<void> signOut() async {
    await logout();
  }
} 