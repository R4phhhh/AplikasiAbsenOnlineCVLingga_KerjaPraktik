import 'package:aplikasi_absen_online/screens/login.dart';
import 'package:aplikasi_absen_online/screens/profil.dart';
import 'package:aplikasi_absen_online/screens/proyek_aktif.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {

        // 🔄 Loading awal
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // ❌ Belum login (data is null)
        if (snapshot.data == null) {
          return const LoginScreen();
        }

        // ✅ Sudah login (data is not null)
        return const ProyekAktifScreen();
      },
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  initializeDateFormatting('id_ID', null).then((_) {
    runApp(MyApp());
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const AuthGate(), // 🔥 WAJIB
      routes: {
        '/proyek': (_) => const ProyekAktifScreen(),
        '/profil': (_) => const ProfilScreen(),
        '/login': (_) => const LoginScreen(),
      },
    );
  }
}