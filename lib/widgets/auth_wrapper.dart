import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../screens/auth/welcome_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/home/business_home_screen.dart';
import '../services/auth_service.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Bağlantı durumu kontrol edilirken loading göster
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // Kullanıcı giriş yapmışsa
        if (snapshot.hasData && snapshot.data != null) {
          return FutureBuilder(
            future: _getCurrentUser(snapshot.data!.uid),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              // Kullanıcı tipine göre ana ekranı göster
              final authService = AuthService();
              final currentUser = authService.currentUser;

              if (currentUser?.userType.toString().split('.').last == 'business') {
                return const BusinessHomeScreen();
              } else {
                return const HomeScreen();
              }
            },
          );
        }

        // Kullanıcı giriş yapmamışsa hoş geldiniz ekranını göster
        return const WelcomeScreen();
      },
    );
  }

  Future<void> _getCurrentUser(String uid) async {
    await AuthService().checkCurrentUser();
  }
} 