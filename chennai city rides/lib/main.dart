import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'car_selection_screen.dart';
import 'login_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://dycanquxbnecrritcoou.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImR5Y2FucXV4Ym5lY3JyaXRjb291Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzUwMjc1MzEsImV4cCI6MjA5MDYwMzUzMX0.i85iLktslLTHZAF3V0xn8_5FKLwqUXqQP6eAai9rSyk',
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
    ),
  );

  Supabase.instance.client.auth.onAuthStateChange.listen((data) {
    print("EVENT: ${data.event}");
    print("SESSION: ${data.session}");
  });

  runApp(const MyApp());
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
              : const CarSelectionScreen();
        },
      ),
    );
  }
}
