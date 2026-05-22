import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'models/user_model.dart';
import 'screens/login_screen.dart';
import 'screens/main_nav_screen.dart';
import 'services/auth_service.dart';
import 'services/firestore_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  bool isFirebaseInitialized = false;
  String? initError;

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    isFirebaseInitialized = true;
  } catch (e) {
    // Tambahkan pengecekan khusus untuk error duplicate-app
    if (e.toString().contains('duplicate-app')) {
      // Jika errornya duplicate-app, berarti Firebase sudah menyala di background.
      // Kita anggap sukses dan tidak perlu menampilkan error.
      isFirebaseInitialized = true;
      debugPrint('Firebase terbaca sudah menyala dari sesi sebelumnya.');
    } else {
      // Jika error lain, baru kita tangkap untuk ditampilkan di layar merah
      initError = e.toString();
      debugPrint('Firebase initialization error: $e');
    }
  }

  runApp(
    MyApp(isFirebaseInitialized: isFirebaseInitialized, initError: initError),
  );
}

class MyApp extends StatelessWidget {
  final bool isFirebaseInitialized;
  final String? initError;

  const MyApp({super.key, required this.isFirebaseInitialized, this.initError});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NexaLock IoT',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.themeData,
      home: isFirebaseInitialized
          ? const AuthWrapper()
          : _FirebaseSetupErrorScreen(error: initError),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final firestoreService = FirestoreService();

    return StreamBuilder<User?>(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        // While checking auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: AppTheme.primary),
            ),
          );
        }

        // If user is authenticated, listen to their profile in Firestore
        final User? user = snapshot.data;
        if (user != null) {
          return StreamBuilder<UserModel?>(
            stream: firestoreService.getUserStream(user.uid),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(
                    child: CircularProgressIndicator(color: AppTheme.primary),
                  ),
                );
              }

              // If user profile is loaded successfully
              if (userSnapshot.hasData && userSnapshot.data != null) {
                return MainNavScreen(user: userSnapshot.data!);
              }

              // Fallback if profile doesn't exist yet but user is logged in
              final fallbackUser = UserModel(
                uid: user.uid,
                name:
                    user.displayName ?? user.email?.split('@').first ?? 'User',
                email: user.email ?? '',
                role: 'user',
              );
              return MainNavScreen(user: fallbackUser);
            },
          );
        }

        // User is not authenticated, redirect to Login
        return const LoginScreen();
      },
    );
  }
}

class _FirebaseSetupErrorScreen extends StatelessWidget {
  final String? error;

  const _FirebaseSetupErrorScreen({this.error});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: AppTheme.error,
                size: 64,
              ),
              const SizedBox(height: 16),
              const Text(
                'Firebase Not Configured',
                style: TextStyle(
                  fontFamily: 'Hanken Grotesk',
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Please run "flutterfire configure" in your terminal to generate the necessary platform configuration files for Firebase Authentication and Firestore.',
                style: const TextStyle(
                  fontSize: 15,
                  color: AppTheme.onSurfaceVariant,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              if (error != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.outlineVariant),
                  ),
                  child: Text(
                    error!,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      color: AppTheme.outline,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
