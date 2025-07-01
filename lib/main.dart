import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/splash_screen.dart';
import 'widgets/auth_wrapper.dart';
import 'screens/auth/welcome_screen.dart';
import 'constants/app_colors.dart';
import 'services/appointment_service.dart';
import 'services/auth_service.dart';
import 'services/location_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('Firebase başarıyla başlatıldı');
  } catch (e) {
    print('Firebase başlatılırken hata oluştu: $e');
  }
  
  // Mock verilerini yükle
  AppointmentService().addMockAppointments();
  
  runApp(const RandevuCepteApp());
}

class RandevuCepteApp extends StatelessWidget {
  const RandevuCepteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RandevuCepte',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
      routes: {
        '/welcome': (context) => const WelcomeScreen(),
      },
      home: const SplashScreenWithAuth(),
    );
  }
}

class SplashScreenWithAuth extends StatefulWidget {
  const SplashScreenWithAuth({super.key});

  @override
  State<SplashScreenWithAuth> createState() => _SplashScreenWithAuthState();
}

class _SplashScreenWithAuthState extends State<SplashScreenWithAuth> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Splash screen süresini bekle
    await Future.delayed(const Duration(seconds: 2));
    
    // Konum izni kontrolü (isteğe bağlı - sessiz)
    try {
      await LocationService().requestLocationPermission();
      print('Konum izni kontrol edildi');
    } catch (e) {
      print('Konum izni kontrolünde hata: $e');
    }
    
    // Mevcut kullanıcıyı kontrol et
    try {
      await AuthService().checkCurrentUser();
    } catch (e) {
      print('Kullanıcı durumu kontrol edilemedi: $e');
    }
    
    // AuthWrapper'a geçiş yap
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const AuthWrapper(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const SplashScreen();
  }
}
