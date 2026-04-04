import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'services/notification_service.dart';
import 'home_screen.dart';
import 'login_screen.dart';

Future<void> main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();

    // 1. Initialize Supabase first (Critical for UI state)
    await Supabase.initialize(
      url: 'https://dycanquxbnecrritcoou.supabase.co',
      anonKey:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImR5Y2FucXV4Ym5lY3JyaXRjb291Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzUwMjc1MzEsImV4cCI6MjA5MDYwMzUzMX0.i85iLktslLTHZAF3V0xn8_5FKLwqUXqQP6eAai9rSyk',
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
    );

    // 2. Kick off Firebase and Notifications in the background
    // This prevents the app from getting stuck if Firebase has issues.
    unawaited(_initializeSecondaryServices());

    runApp(const MyApp());
  } catch (e) {
    debugPrint("Startup Error: $e");
    runApp(const MyApp());
  }
}

// Helper for background init
Future<void> _initializeSecondaryServices() async {
  try {
    await Firebase.initializeApp();
    await PushNotificationService.initialize();
  } catch (e) {
    debugPrint("Firebase/Notification Init Error: $e");
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chennai City Rides',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF166534)),
        useMaterial3: true,
      ),
      home: StreamBuilder<AuthState>(
        stream: Supabase.instance.client.auth.onAuthStateChange,
        initialData: AuthState(
          AuthChangeEvent.initialSession,
          Supabase.instance.client.auth.currentSession,
        ),
        builder: (context, snapshot) {
          final session =
              snapshot.data?.session ??
              Supabase.instance.client.auth.currentSession;
          return session == null
              ? const LoginScreen()
              : const HomeScreen();
        },
      ),
    );
  }
}
